const path = require('path');
const fs = require('fs');
const PDFDocument = require('pdfkit');

const REPORT_FONT_REGULAR = path.join(__dirname, '../../assets/fonts/ReportSans.ttf');
const REPORT_FONT_BOLD = path.join(__dirname, '../../assets/fonts/ReportSans-Bold.ttf');

const C = {
    ink: '#1E293B',
    muted: '#475569',
    soft: '#64748B',
    line: '#E2E8F0',
    card: '#F8FAFC',
    white: '#FFFFFF',
    header: '#0F172A',
    gold: '#EAB308',
    goldDark: '#CA8A04',
    good: '#10B981',
    warn: '#F59E0B',
    red: '#EF4444',
};

// ─── helpers ────────────────────────────────────────────────────────────────

function applyReportFonts(doc) {
    const hasRegular = fs.existsSync(REPORT_FONT_REGULAR);
    const hasBold = fs.existsSync(REPORT_FONT_BOLD);
    if (hasRegular) doc.registerFont('ReportSans', REPORT_FONT_REGULAR);
    if (hasBold) doc.registerFont('ReportSans-Bold', REPORT_FONT_BOLD);
    return {
        regular: hasRegular ? 'ReportSans' : 'Helvetica',
        bold: hasBold ? 'ReportSans-Bold' : (hasRegular ? 'ReportSans' : 'Helvetica-Bold'),
    };
}

function monthName(month) {
    const names = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[Number(month)] || String(month || '');
}

function safeText(v) { return String(v == null ? '' : v).trim(); }

function avgRating(areas) {
    const rated = areas.filter((a) => typeof a.rating === 'number' && a.rating > 0);
    if (!rated.length) return null;
    return Math.round((rated.reduce((s, a) => s + Number(a.rating), 0) / rated.length) * 10) / 10;
}

function ratingLabel(avg) {
    if (avg == null) return 'Not Rated';
    if (avg >= 4.5) return 'Elite Progress';
    if (avg >= 3.5) return 'Strong Progress';
    if (avg >= 2.5) return 'Developing';
    if (avg >= 1.5) return 'Needs Focus';
    return 'Priority Attention';
}

// ─── primitive draw helpers ──────────────────────────────────────────────────

function drawRoundedRect(doc, x, y, w, h, r, fill, stroke) {
    doc.save();
    if (fill) doc.fillColor(fill);
    if (stroke) doc.strokeColor(stroke).lineWidth(0.6);
    doc.roundedRect(x, y, w, h, r);
    if (fill && stroke) doc.fillAndStroke();
    else if (fill) doc.fill();
    else doc.stroke();
    doc.restore();
}

function drawArc(doc, cx, cy, r, startAngleDeg, endAngleDeg, color, lw) {
    doc.save();
    doc.lineWidth(lw);
    doc.strokeColor(color);
    doc.lineCap('round');
    let first = true;
    for (let a = startAngleDeg; a <= endAngleDeg; a += 1.5) {
        const rad = (a - 90) * Math.PI / 180;
        const x = cx + r * Math.cos(rad);
        const y = cy + r * Math.sin(rad);
        if (first) { doc.moveTo(x, y); first = false; }
        else doc.lineTo(x, y);
    }
    doc.stroke();
    doc.restore();
}

function drawRatingScale(doc, x, y, rating) {
    const blockW = 15, blockH = 7, gap = 3, r = 2;
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    for (let i = 1; i <= 5; i++) {
        const bx = x + (i - 1) * (blockW + gap);
        drawRoundedRect(doc, bx, y, blockW, blockH, r, '#E2E8F0', null);
        if (i <= value) {
            drawRoundedRect(doc, bx, y, blockW, blockH, r, C.gold, null);
        } else if (i - 1 < value) {
            const fillW = blockW * (value - (i - 1));
            doc.save();
            doc.roundedRect(bx, y, blockW, blockH, r).clip();
            doc.fillColor(C.gold).rect(bx, y, fillW, blockH).fill();
            doc.restore();
        }
    }
}

function drawRatingBar(doc, x, y, w, h, rating) {
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    drawRoundedRect(doc, x, y, w, h, h / 2, '#F1F5F9', null);
    const fillW = Math.max(h, (w * value) / 5);
    if (value > 0) drawRoundedRect(doc, x, y, fillW, h, h / 2, C.gold, null);
}

// ─── layout utilities ────────────────────────────────────────────────────────

const PAGE_MARGIN_BOTTOM = 42;

function ensureSpace(doc, needed) {
    if (doc.y + needed > doc.page.height - PAGE_MARGIN_BOTTOM) {
        doc.addPage();
        return true;
    }
    return false;
}

/**
 * Draw text at an absolute position without moving doc.y.
 */
function staticText(doc, font, size, color, text, x, y, opts = {}) {
    const savedY = doc.y;
    doc.font(font).fontSize(size).fillColor(color);
    doc.text(text, x, y, { lineBreak: false, ...opts });
    doc.y = savedY;
}

/**
 * Draw text during switchToPage chrome loop.
 * Temporarily increases page.height so PDFKit's LineWrapper never
 * calls continueOnNewPage, then restores the real height.
 */
function chromeText(doc, font, size, color, text, x, y, opts = {}) {
    const savedY = doc.y;
    const realHeight = doc.page.height;
    doc.page.height = 99999; // prevent any auto-pagination
    doc.font(font).fontSize(size).fillColor(color);
    doc.text(text, x, y, { lineBreak: false, ...opts });
    doc.page.height = realHeight; // restore
    doc.y = savedY;
}

// ─── page chrome (header strip on page > 0, footer on every page) ────────────

function drawPageChrome(doc, fonts, pageIndex, pageCount, meta) {
    const { width, height } = doc.page;
    const savedY = doc.y;

    if (pageIndex > 0) {
        doc.save();
        doc.rect(0, 0, width, 6).fill(C.header);
        doc.rect(0, 6, width, 3).fill(C.gold);
        doc.restore();
        chromeText(doc, fonts.bold, 7.5, C.soft,
            'BALLCHART  \xB7  PERFORMANCE REPORT', 40, 17,
            { width: width - 80, align: 'left', characterSpacing: 0.7 });
        chromeText(doc, fonts.regular, 7.5, C.muted,
            meta.playerName, 40, 17,
            { width: width - 80, align: 'right' });
    }

    const footerY = height - 34;
    doc.save();
    doc.moveTo(40, footerY - 7).lineTo(width - 40, footerY - 7)
        .strokeColor(C.line).lineWidth(0.6).stroke();
    doc.restore();
    chromeText(doc, fonts.regular, 7.5, C.soft,
        'BallChart \xB7 Confidential Athlete Performance Report',
        40, footerY, { width: width - 160, align: 'left' });
    chromeText(doc, fonts.regular, 7.5, C.muted,
        `Page ${pageIndex + 1} of ${pageCount}`,
        40, footerY, { width: width - 80, align: 'right' });

    doc.y = savedY;
}

// ─── content sections ────────────────────────────────────────────────────────

function drawHeader(doc, fonts, meta) {
    const { width } = doc.page;
    doc.save();
    doc.rect(0, 0, width, 90).fill(C.header);
    doc.rect(0, 90, width, 3).fill(C.gold);
    doc.restore();

    const logoPath = path.join(__dirname, '../../assets/images/logo.png');
    if (fs.existsSync(logoPath)) {
        try { doc.image(logoPath, width - 95, 16, { width: 52 }); } catch (_) {}
    }

    staticText(doc, fonts.bold, 8, C.gold, 'BALLCHART', 40, 18,
        { characterSpacing: 1.8 });
    staticText(doc, fonts.bold, 6, '#94A3B8', 'ATHLETE DEVELOPMENT NETWORK', 40, 30,
        { characterSpacing: 1 });
    staticText(doc, fonts.bold, 16, C.white, 'Performance Development Report', 40, 46,
        { width: width - 150 });
    staticText(doc, fonts.regular, 7.5, '#CBD5E1', meta.generatedLabel, 40, 70);

    doc.y = 104;
}

function drawMetaCard(doc, fonts, meta) {
    const x = 40, y = doc.y, w = doc.page.width - 80, h = 54;
    drawRoundedRect(doc, x, y, w, h, 8, '#F8FAFC', C.line);

    const colW = (w - 24) / 3;
    const rows = [
        { label: 'ATHLETE / PLAYER', value: meta.playerName },
        { label: 'EVALUATION PERIOD', value: meta.periodLabel },
        { label: 'AGE CATEGORY', value: meta.ageCategory || '—' },
    ];
    rows.forEach((row, i) => {
        const cx = x + 12 + i * colW;
        if (i > 0) {
            doc.save();
            doc.moveTo(cx - 6, y + 10).lineTo(cx - 6, y + 44)
                .strokeColor(C.line).lineWidth(0.7).stroke();
            doc.restore();
        }
        staticText(doc, fonts.bold, 6.5, C.soft, row.label, cx, y + 10,
            { width: colW - 12, characterSpacing: 0.5 });
        staticText(doc, fonts.bold, 10.5, C.header, row.value, cx, y + 22,
            { width: colW - 12, ellipsis: true });
    });

    if (meta.nextEvaluationDate) {
        staticText(doc, fonts.bold, 6.5, C.soft, 'NEXT EVALUATION:', x + 12, y + 40);
        staticText(doc, fonts.bold, 7, C.goldDark, meta.nextEvaluationDate, x + 104, y + 40);
    }

    doc.y = y + h + 10;
}

function drawScoreOverview(doc, fonts, areas) {
    const avg = avgRating(areas);
    const x = 40, y = doc.y, w = doc.page.width - 80, h = 96;

    drawRoundedRect(doc, x, y, w, h, 8, C.white, C.line);
    doc.save();
    doc.rect(x, y, 5, h).fillColor(C.header).fill();
    doc.restore();

    staticText(doc, fonts.bold, 7.5, C.soft, 'OVERALL DEVELOPMENT SNAPSHOT',
        x + 18, y + 10, { characterSpacing: 0.8 });

    // Circular gauge
    const gaugeX = x + 58, gaugeY = y + 55, gaugeR = 24;
    doc.save();
    doc.lineWidth(5).strokeColor('#F1F5F9');
    doc.circle(gaugeX, gaugeY, gaugeR).stroke();
    doc.restore();
    if (avg != null && avg > 0) {
        drawArc(doc, gaugeX, gaugeY, gaugeR, 0, (avg / 5) * 360, C.gold, 5);
    }
    const scoreStr = avg == null ? '—' : avg.toFixed(1);
    doc.font(fonts.bold).fontSize(15).fillColor(C.header);
    const scoreW = doc.widthOfString(scoreStr);
    staticText(doc, fonts.bold, 15, C.header, scoreStr, gaugeX - scoreW / 2, gaugeY - 9);
    doc.font(fonts.bold).fontSize(6).fillColor(C.soft);
    const subW = doc.widthOfString('/ 5.0');
    staticText(doc, fonts.bold, 6, C.soft, '/ 5.0', gaugeX - subW / 2, gaugeY + 8);

    // Label + badge
    const labelX = x + 110;
    staticText(doc, fonts.bold, 10.5, C.header, ratingLabel(avg), labelX, y + 28, { width: 160 });
    staticText(doc, fonts.regular, 8, C.muted,
        `${areas.filter(a => a.rating).length} of ${areas.length} areas rated`,
        labelX, y + 44);

    const bText = ratingLabel(avg).toUpperCase();
    doc.font(fonts.bold).fontSize(6.5);
    const bW = doc.widthOfString(bText) + 10;
    const bColor = avg != null && avg >= 3.5 ? C.good : (avg != null && avg >= 2.5 ? C.goldDark : C.warn);
    drawRoundedRect(doc, labelX, y + 60, bW, 13, 3, bColor, null);
    staticText(doc, fonts.bold, 6.5, C.white, bText, labelX + 5, y + 63);

    // Mini bars
    const miniX = x + w - 200;
    areas.slice(0, 5).forEach((area, i) => {
        const my = y + 10 + i * 14;
        staticText(doc, fonts.bold, 7, C.header, area.label, miniX, my,
            { width: 95, ellipsis: true });
        drawRatingBar(doc, miniX + 100, my + 1, 68, 5, area.rating);
        const rv = typeof area.rating === 'number' ? area.rating.toFixed(1) : '—';
        staticText(doc, fonts.bold, 7, C.soft, rv, miniX + 172, my, { width: 16, align: 'right' });
    });

    doc.y = y + h + 12;
}

function measureAreaCardHeight(doc, fonts, area, contentWidth) {
    let h = 38;
    const blocks = [
        safeText(area.performanceComment),
        safeText(area.strengths),
        safeText(area.focusArea),
    ].filter(Boolean);
    if (!blocks.length) { h += 14; } else {
        doc.font(fonts.regular).fontSize(8);
        for (const t of blocks) {
            h += doc.heightOfString(t, { width: contentWidth - 22, lineGap: 1 }) + 12 + 6;
        }
    }
    return h + 4;
}

function drawAreaCard(doc, fonts, area, index) {
    const x = 40, w = doc.page.width - 80, contentWidth = w - 28;
    const h = measureAreaCardHeight(doc, fonts, area, contentWidth);
    ensureSpace(doc, h + 8);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 8, C.white, C.line);
    drawRoundedRect(doc, x + 10, y + 10, 18, 18, 4, C.header, null);
    staticText(doc, fonts.bold, 8, C.gold,
        String(index + 1).padStart(2, '0'), x + 10, y + 14,
        { width: 18, align: 'center' });
    staticText(doc, fonts.bold, 10.5, C.header,
        area.label || `Area ${index + 1}`, x + 34, y + 14,
        { width: w - 165 });

    if (typeof area.rating === 'number') {
        drawRatingScale(doc, x + w - 140, y + 15, area.rating);
        staticText(doc, fonts.bold, 9, C.header,
            `${area.rating.toFixed(1)}/5`, x + w - 42, y + 14,
            { width: 28, align: 'right' });
    } else {
        staticText(doc, fonts.regular, 8, C.soft, 'Unrated', x + w - 68, y + 15,
            { width: 54, align: 'right' });
    }

    doc.save();
    doc.moveTo(x + 10, y + 34).lineTo(x + w - 10, y + 34)
        .strokeColor(C.line).lineWidth(0.5).stroke();
    doc.restore();

    let cy = y + 38;
    const blocks = [
        { label: 'PERFORMANCE NOTES', text: safeText(area.performanceComment), border: '#3B82F6' },
        { label: 'STRENGTHS', text: safeText(area.strengths), border: C.good },
        { label: 'FOCUS NEXT', text: safeText(area.focusArea), border: C.warn },
    ].filter(b => b.text);

    if (!blocks.length) {
        staticText(doc, fonts.regular, 8, C.soft,
            'No detailed notes recorded for this area.', x + 14, cy, { width: contentWidth });
    } else {
        for (const b of blocks) {
            doc.font(fonts.regular).fontSize(8);
            const textH = doc.heightOfString(b.text, { width: contentWidth - 22, lineGap: 1 });
            const blockH = textH + 12;
            drawRoundedRect(doc, x + 14, cy, contentWidth, blockH, 4, '#F8FAFC', null);
            doc.save();
            doc.rect(x + 14, cy, 3, blockH).fillColor(b.border).fill();
            doc.restore();
            staticText(doc, fonts.bold, 6, C.soft, b.label, x + 22, cy + 3,
                { characterSpacing: 0.6 });
            // For content text we must allow multi-line but control the y ourselves
            const savedY = doc.y;
            doc.font(fonts.regular).fontSize(8).fillColor(C.header)
                .text(b.text, x + 22, cy + 12, { width: contentWidth - 22, lineGap: 1, lineBreak: true });
            doc.y = savedY;
            cy += blockH + 6;
        }
    }

    doc.y = y + h + 8;
}

function drawSectionTitle(doc, fonts, title, subtitle) {
    ensureSpace(doc, 30);
    const y = doc.y;
    doc.save();
    doc.rect(40, y + 1, 3, 13).fillColor(C.gold).fill();
    doc.restore();
    staticText(doc, fonts.bold, 11, C.header, title, 50, y);
    if (subtitle) staticText(doc, fonts.regular, 7, C.muted, subtitle, 50, y + 13);
    doc.y = y + (subtitle ? 25 : 17);
}

function drawTextPanel(doc, fonts, title, body) {
    const x = 40, w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(8);
    const bodyH = doc.heightOfString(body, { width: w - 28, lineGap: 1.5 });
    const h = 24 + bodyH + 8;
    ensureSpace(doc, h + 6);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 8, '#F8FAFC', C.line);
    doc.save();
    doc.rect(x, y, 4, h).fillColor(C.header).fill();
    doc.restore();
    staticText(doc, fonts.bold, 6.5, C.soft, title, x + 14, y + 7, { characterSpacing: 0.7 });

    const savedY = doc.y;
    doc.font(fonts.regular).fontSize(8).fillColor(C.header)
        .text(body, x + 14, y + 17, { width: w - 28, lineGap: 1.5, lineBreak: true });
    doc.y = savedY;

    doc.y = y + h + 8;
}

function drawGoalsPanel(doc, fonts, title, goals) {
    const items = (goals || []).map(safeText).filter(Boolean);
    if (!items.length) return;

    const x = 40, w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(8);
    let contentH = 0;
    for (const g of items) {
        contentH += Math.max(12, doc.heightOfString(g, { width: w - 46, lineGap: 1 })) + 8;
    }
    const h = 24 + contentH + 4;
    ensureSpace(doc, h + 6);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 8, C.white, C.line);
    staticText(doc, fonts.bold, 6.5, C.soft, title, x + 14, y + 7, { characterSpacing: 0.7 });

    let cy = y + 22;
    items.forEach((g) => {
        doc.font(fonts.regular).fontSize(8);
        const th = Math.max(12, doc.heightOfString(g, { width: w - 46, lineGap: 1 }));
        const itemH = th + 6;
        const cbX = x + 14, cbY = cy;
        drawRoundedRect(doc, cbX, cbY, 9, 9, 2, '#F1F5F9', '#CBD5E1');
        doc.save();
        doc.lineWidth(1).strokeColor(C.goldDark)
            .moveTo(cbX + 2, cbY + 4.5).lineTo(cbX + 4, cbY + 6.5).lineTo(cbX + 7, cbY + 2).stroke();
        doc.restore();
        const savedY2 = doc.y;
        doc.font(fonts.regular).fontSize(8).fillColor(C.header)
            .text(g, x + 28, cy, { width: w - 46, lineGap: 1, lineBreak: true });
        doc.y = savedY2;
        cy += itemH + 4;
    });
    doc.y = y + h + 8;
}

function drawSignatureBlock(doc, fonts) {
    const x = 40, w = doc.page.width - 80, h = 64;
    ensureSpace(doc, h + 8);
    const y = doc.y;
    const colW = (w - 40) / 2;

    doc.save();
    doc.moveTo(x, y + 38).lineTo(x + colW, y + 38).strokeColor(C.soft).lineWidth(0.7).stroke();
    doc.restore();
    staticText(doc, fonts.bold, 8, C.header, 'HEAD COACH SIGNATURE', x, y + 44);
    staticText(doc, fonts.regular, 7, C.soft, 'BallChart Certified Academy Staff', x, y + 54);

    const rightX = x + colW + 40;
    doc.save();
    doc.moveTo(rightX, y + 38).lineTo(rightX + colW, y + 38).strokeColor(C.soft).lineWidth(0.7).stroke();
    doc.restore();
    staticText(doc, fonts.bold, 8, C.header, 'ATHLETE / PARENT SIGNATURE', rightX, y + 44);
    staticText(doc, fonts.regular, 7, C.soft, 'Acknowledgment of Development Plan', rightX, y + 54);

    doc.y = y + h + 8;
}

// ─── main builders ───────────────────────────────────────────────────────────

/**
 * Professional Performance Development Report PDF.
 */
function buildPerformanceReportPdf(report, playerName, areas) {
    return new Promise((resolve, reject) => {
        const doc = new PDFDocument({
            size: 'A4',
            margin: 40,
            bufferPages: true,
            autoFirstPage: true,
            info: {
                Title: 'Performance Development Report',
                Author: 'BallChart',
                Subject: `Development report for ${playerName}`,
            },
        });
        const fonts = applyReportFonts(doc);
        const chunks = [];
        doc.on('data', c => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const periodLabel = safeText(report.evaluationPeriod)
            || `${monthName(report.month)} ${report.year}` || '—';
        const generatedLabel = `Generated ${new Date().toLocaleDateString('en-GB', {
            day: '2-digit', month: 'short', year: 'numeric',
        })}`;
        const meta = {
            playerName: safeText(playerName) || 'Player',
            periodLabel,
            ageCategory: safeText(report.ageCategory),
            nextEvaluationDate: safeText(report.nextEvaluationDate),
            generatedLabel,
        };

        // ── page 1 content ──
        drawHeader(doc, fonts, meta);
        drawMetaCard(doc, fonts, meta);
        drawScoreOverview(doc, fonts, areas);

        drawSectionTitle(doc, fonts, 'Development Areas',
            'Ratings, performance notes, strengths, and next-focus guidance');
        areas.forEach((area, i) => drawAreaCard(doc, fonts, area, i));

        if (safeText(report.summary)) {
            drawSectionTitle(doc, fonts, 'Coach Summary', 'Holistic view of the evaluation period');
            drawTextPanel(doc, fonts, 'SUMMARY', safeText(report.summary));
        }

        if ((report.goals || []).filter(safeText).length) {
            drawSectionTitle(doc, fonts, 'Coach Goals', 'Priorities set by the coaching staff');
            drawGoalsPanel(doc, fonts, 'COACH GOALS', report.goals);
        }

        if ((report.playerGoals || []).filter(safeText).length) {
            drawSectionTitle(doc, fonts, 'Player Goals', 'Targets owned by the athlete');
            drawGoalsPanel(doc, fonts, 'PLAYER GOALS', report.playerGoals);
        }

        drawSectionTitle(doc, fonts, 'Sign-Off & Validation', 'Formal validation of development plan');
        drawSignatureBlock(doc, fonts);

        // Closing strip — drawn without touching doc.y after
        ensureSpace(doc, 52);
        const cx = 40, cy = doc.y + 4, cw = doc.page.width - 80;
        drawRoundedRect(doc, cx, cy, cw, 40, 8, C.header, null);
        staticText(doc, fonts.bold, 8.5, C.gold, 'BALLCHART', cx + 18, cy + 10,
            { characterSpacing: 1.4 });
        staticText(doc, fonts.regular, 7.5, '#94A3B8',
            'Train with intent. Measure progress. Raise the standard.',
            cx + 18, cy + 24);

        // ── apply chrome to every buffered page ──
        const range = doc.bufferedPageRange();
        for (let i = 0; i < range.count; i++) {
            doc.switchToPage(range.start + i);
            drawPageChrome(doc, fonts, i, range.count, meta);
        }

        doc.end();
    });
}

function buildAssignmentCompletionPdf(assignment) {
    return new Promise((resolve, reject) => {
        const doc = new PDFDocument({
            size: 'A4',
            margin: 40,
            bufferPages: true,
            info: { Title: 'Training Completion Report', Author: 'BallChart' },
        });
        const fonts = applyReportFonts(doc);
        const chunks = [];
        doc.on('data', c => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const { width } = doc.page;

        // Header
        doc.save();
        doc.rect(0, 0, width, 108).fill(C.header);
        doc.rect(0, 108, width, 3).fill(C.gold);
        doc.restore();
        staticText(doc, fonts.bold, 8.5, C.gold, 'BALLCHART', 40, 26, { characterSpacing: 1.8 });
        staticText(doc, fonts.bold, 17, C.white, 'Training Assignment Completion', 40, 44);
        staticText(doc, fonts.regular, 8, '#CBD5E1', 'Official completion validation record', 40, 72);

        doc.y = 128;

        const x = 40, w = width - 80, h = 172;
        drawRoundedRect(doc, x, doc.y, w, h, 10, C.white, C.line);
        doc.save();
        doc.rect(x, doc.y, 5, h).fillColor(C.good).fill();
        doc.restore();

        const baseY = doc.y;
        const colW = (w - 28) / 2;

        staticText(doc, fonts.bold, 7, C.soft, 'DEVELOPMENT FOCUS AREA',
            x + 18, baseY + 14, { characterSpacing: 0.7 });
        staticText(doc, fonts.bold, 10.5, C.header,
            safeText(assignment.focusArea) || '—', x + 18, baseY + 26,
            { width: colW - 10 });

        staticText(doc, fonts.bold, 7, C.soft, 'ASSIGNED DRILL / PRACTICE',
            x + colW + 18, baseY + 14, { characterSpacing: 0.7 });
        staticText(doc, fonts.bold, 10.5, C.header,
            safeText(assignment.drillName) || '—', x + colW + 18, baseY + 26,
            { width: colW - 10 });

        doc.save();
        doc.moveTo(x + 18, baseY + 56).lineTo(x + w - 18, baseY + 56)
            .strokeColor(C.line).lineWidth(0.7).stroke();
        doc.restore();

        staticText(doc, fonts.bold, 7, C.soft, 'POINTS AWARDED',
            x + 18, baseY + 68, { characterSpacing: 0.7 });
        staticText(doc, fonts.bold, 13, C.goldDark,
            `+${assignment.pointsValue ?? 10} XP`, x + 18, baseY + 80);

        staticText(doc, fonts.bold, 7, C.soft, 'COMPLETION STATUS',
            x + colW + 18, baseY + 68, { characterSpacing: 0.7 });
        const statusText = (safeText(assignment.status) || 'COMPLETED').toUpperCase();
        doc.font(fonts.bold).fontSize(7);
        const sBadgeW = doc.widthOfString(statusText) + 10;
        drawRoundedRect(doc, x + colW + 18, baseY + 80, sBadgeW, 14, 3, C.good, null);
        staticText(doc, fonts.bold, 7, C.white, statusText, x + colW + 22, baseY + 83);

        doc.save();
        doc.moveTo(x + 18, baseY + 108).lineTo(x + w - 18, baseY + 108)
            .strokeColor(C.line).lineWidth(0.7).stroke();
        doc.restore();

        staticText(doc, fonts.bold, 7, C.soft, 'VALIDATION TIMESTAMP',
            x + 18, baseY + 120, { characterSpacing: 0.7 });
        const dateStr = assignment.completedAt
            ? new Date(assignment.completedAt).toLocaleString('en-GB', {
                day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
            })
            : '—';
        staticText(doc, fonts.bold, 10, C.header, dateStr, x + 18, baseY + 132);

        doc.y = baseY + h + 16;

        if (safeText(assignment.playerNotes)) {
            drawTextPanel(doc, fonts, 'PLAYER LOG NOTES', safeText(assignment.playerNotes));
        }

        ensureSpace(doc, 56);
        const sigY = doc.y;
        doc.save();
        doc.moveTo(x, sigY + 28).lineTo(x + 200, sigY + 28)
            .strokeColor(C.soft).lineWidth(0.7).stroke();
        doc.restore();
        staticText(doc, fonts.bold, 8, C.header, 'AUTHORIZED BY ACADEMY COACH', x, sigY + 34);

        const range = doc.bufferedPageRange();
        for (let i = 0; i < range.count; i++) {
            doc.switchToPage(range.start + i);
            drawPageChrome(doc, fonts, i, range.count, { playerName: 'Training Completion' });
        }

        doc.end();
    });
}

module.exports = {
    buildPerformanceReportPdf,
    buildAssignmentCompletionPdf,
    applyReportFonts,
};
