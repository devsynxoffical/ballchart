const path = require('path');
const fs = require('fs');
const PDFDocument = require('pdfkit');

const REPORT_FONT_REGULAR = path.join(__dirname, '../../assets/fonts/ReportSans.ttf');
const REPORT_FONT_BOLD = path.join(__dirname, '../../assets/fonts/ReportSans-Bold.ttf');

const C = {
    ink: '#111111',
    muted: '#6B6B6B',
    soft: '#9A9A9A',
    line: '#E6E6E6',
    card: '#F6F6F6',
    white: '#FFFFFF',
    header: '#141414',
    gold: '#FFD900',
    goldDark: '#C9A600',
    accentBar: '#FFD900',
    good: '#1F7A3F',
    warn: '#B45309',
};

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

function safeText(v) {
    return String(v == null ? '' : v).trim();
}

function avgRating(areas) {
    const rated = areas.filter((a) => typeof a.rating === 'number' && a.rating > 0);
    if (!rated.length) return null;
    const sum = rated.reduce((s, a) => s + Number(a.rating), 0);
    return Math.round((sum / rated.length) * 10) / 10;
}

function ratingLabel(avg) {
    if (avg == null) return 'Not rated';
    if (avg >= 4.5) return 'Elite progress';
    if (avg >= 3.5) return 'Strong progress';
    if (avg >= 2.5) return 'Developing';
    if (avg >= 1.5) return 'Needs focus';
    return 'Priority attention';
}

function drawRoundedRect(doc, x, y, w, h, r, fill, stroke) {
    doc.save();
    if (fill) doc.fillColor(fill);
    if (stroke) doc.strokeColor(stroke);
    doc.roundedRect(x, y, w, h, r);
    if (fill && stroke) doc.fillAndStroke();
    else if (fill) doc.fill();
    else doc.stroke();
    doc.restore();
}

function drawRatingDots(doc, x, y, rating, size = 9, gap = 5) {
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    for (let i = 1; i <= 5; i += 1) {
        const cx = x + (i - 1) * (size + gap);
        const filled = i <= Math.round(value);
        doc.circle(cx + size / 2, y + size / 2, size / 2)
            .fillColor(filled ? C.gold : '#D8D8D8')
            .fill();
        if (filled) {
            doc.circle(cx + size / 2, y + size / 2, size / 2)
                .lineWidth(0.6)
                .strokeColor(C.goldDark)
                .stroke();
        }
    }
}

function drawRatingBar(doc, x, y, w, h, rating) {
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    drawRoundedRect(doc, x, y, w, h, h / 2, '#E9E9E9', null);
    const fillW = Math.max(h, (w * value) / 5);
    if (value > 0) {
        drawRoundedRect(doc, x, y, fillW, h, h / 2, C.gold, null);
    }
}

function ensureSpace(doc, needed, marginBottom = 56) {
    const pageBottom = doc.page.height - marginBottom;
    if (doc.y + needed > pageBottom) {
        doc.addPage();
        return true;
    }
    return false;
}

function drawPageChrome(doc, fonts, pageIndex, pageCount, meta) {
    const { width, height } = doc.page;
    // Top thin gold rule on continuations
    if (pageIndex > 0) {
        doc.save();
        doc.rect(0, 0, width, 6).fill(C.header);
        doc.rect(0, 6, width, 3).fill(C.gold);
        doc.restore();
        doc.font(fonts.bold).fontSize(8).fillColor(C.muted)
            .text('BALLCHART  ·  REPORT', 40, 18, {
                width: width - 80,
                align: 'left',
            });
        doc.font(fonts.regular).fontSize(8).fillColor(C.soft)
            .text(meta.playerName, 40, 18, { width: width - 80, align: 'right' });
        doc.y = 44;
    }

    // Footer
    const footerY = height - 36;
    doc.save();
    doc.moveTo(40, footerY - 8).lineTo(width - 40, footerY - 8).strokeColor(C.line).lineWidth(0.8).stroke();
    doc.font(fonts.regular).fontSize(8).fillColor(C.soft)
        .text('BallChart · Confidential · For academy coaching use only', 40, footerY, {
            width: width - 160,
            align: 'left',
        });
    doc.font(fonts.regular).fontSize(8).fillColor(C.muted)
        .text(`Page ${pageIndex + 1} of ${pageCount}`, 40, footerY, {
            width: width - 80,
            align: 'right',
        });
    doc.restore();
}

function drawHeader(doc, fonts, meta) {
    const { width } = doc.page;
    doc.save();
    doc.rect(0, 0, width, 118).fill(C.header);
    doc.rect(0, 118, width, 5).fill(C.gold);

    doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
        .text('BALLCHART', 40, 28, { characterSpacing: 2 });
    doc.font(fonts.regular).fontSize(8).fillColor('#B8B8B8')
        .text('PLAYER DEVELOPMENT PROGRAM', 40, 42, { characterSpacing: 1.2 });

    doc.font(fonts.bold).fontSize(22).fillColor(C.white)
        .text('Performance Development Report', 40, 62, { width: width - 80 });

    doc.font(fonts.regular).fontSize(9).fillColor('#CFCFCF')
        .text(meta.generatedLabel, 40, 92, { width: width - 80, align: 'right' });
    doc.restore();
    doc.y = 140;
}

function drawMetaCard(doc, fonts, meta) {
    const x = 40;
    const y = doc.y;
    const w = doc.page.width - 80;
    const h = 78;
    drawRoundedRect(doc, x, y, w, h, 10, C.card, C.line);

    const colW = (w - 36) / 3;
    const rows = [
        { label: 'PLAYER', value: meta.playerName },
        { label: 'EVALUATION PERIOD', value: meta.periodLabel },
        { label: 'AGE CATEGORY', value: meta.ageCategory || '—' },
    ];

    rows.forEach((row, i) => {
        const cx = x + 18 + i * colW;
        doc.font(fonts.bold).fontSize(7).fillColor(C.soft)
            .text(row.label, cx, y + 16, { width: colW - 12, characterSpacing: 0.8 });
        doc.font(fonts.bold).fontSize(12).fillColor(C.ink)
            .text(row.value, cx, y + 32, { width: colW - 12 });
    });

    if (meta.nextEvaluationDate) {
        doc.font(fonts.regular).fontSize(8).fillColor(C.muted)
            .text(`Next evaluation: ${meta.nextEvaluationDate}`, x + 18, y + 56, { width: w - 36 });
    }

    doc.y = y + h + 18;
}

function drawScoreOverview(doc, fonts, areas) {
    const avg = avgRating(areas);
    const x = 40;
    const y = doc.y;
    const w = doc.page.width - 80;
    const h = 92;

    drawRoundedRect(doc, x, y, w, h, 10, C.white, C.line);
    doc.save();
    doc.rect(x, y, 6, h).fill(C.gold);
    doc.restore();

    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text('OVERALL DEVELOPMENT SNAPSHOT', x + 20, y + 14, { characterSpacing: 1 });

    const scoreText = avg == null ? '—' : avg.toFixed(1);
    doc.font(fonts.bold).fontSize(28).fillColor(C.ink)
        .text(scoreText, x + 20, y + 30, { width: 70 });
    doc.font(fonts.regular).fontSize(9).fillColor(C.muted)
        .text(avg == null ? '' : '/ 5.0', x + 78, y + 44);

    doc.font(fonts.bold).fontSize(11).fillColor(C.ink)
        .text(ratingLabel(avg), x + 130, y + 34, { width: 180 });
    doc.font(fonts.regular).fontSize(8).fillColor(C.muted)
        .text(`${areas.filter((a) => a.rating).length} of ${areas.length} areas rated`, x + 130, y + 52);

    // Mini area bars on the right
    const miniX = x + w - 210;
    areas.slice(0, 6).forEach((area, i) => {
        const my = y + 16 + i * 11;
        doc.font(fonts.regular).fontSize(6.5).fillColor(C.muted)
            .text(area.label, miniX, my, { width: 88, ellipsis: true });
        drawRatingBar(doc, miniX + 92, my + 1, 90, 5, area.rating);
    });

    doc.y = y + h + 20;
}

function measureAreaCardHeight(doc, fonts, area, contentWidth) {
    let h = 52; // header
    const blocks = [
        { label: 'Performance notes', text: safeText(area.performanceComment) },
        { label: 'Strengths', text: safeText(area.strengths) },
        { label: 'Focus next', text: safeText(area.focusArea) },
    ].filter((b) => b.text);

    if (!blocks.length) h += 22;
    for (const b of blocks) {
        doc.font(fonts.regular).fontSize(9);
        const th = doc.heightOfString(b.text, { width: contentWidth, lineGap: 1.5 });
        h += 16 + th + 10;
    }
    return h + 8;
}

function drawAreaCard(doc, fonts, area, index) {
    const x = 40;
    const w = doc.page.width - 80;
    const contentWidth = w - 36;
    const h = measureAreaCardHeight(doc, fonts, area, contentWidth);
    ensureSpace(doc, h + 12);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 10, C.white, C.line);

    // Index badge
    drawRoundedRect(doc, x + 14, y + 14, 24, 24, 6, C.header, null);
    doc.font(fonts.bold).fontSize(10).fillColor(C.gold)
        .text(String(index + 1).padStart(2, '0'), x + 14, y + 20, { width: 24, align: 'center' });

    doc.font(fonts.bold).fontSize(12).fillColor(C.ink)
        .text(area.label || `Area ${index + 1}`, x + 48, y + 16, { width: w - 180 });

    const rating = typeof area.rating === 'number' ? area.rating : null;
    if (rating != null) {
        drawRatingDots(doc, x + w - 118, y + 18, rating);
        doc.font(fonts.bold).fontSize(9).fillColor(C.ink)
            .text(`${rating}/5`, x + w - 48, y + 18, { width: 34, align: 'right' });
    } else {
        doc.font(fonts.regular).fontSize(8).fillColor(C.soft)
            .text('Unrated', x + w - 70, y + 20, { width: 56, align: 'right' });
    }

    // Divider under header
    doc.moveTo(x + 14, y + 46).lineTo(x + w - 14, y + 46).strokeColor(C.line).lineWidth(0.8).stroke();

    let cy = y + 56;
    const blocks = [
        { label: 'PERFORMANCE NOTES', text: safeText(area.performanceComment) },
        { label: 'STRENGTHS', text: safeText(area.strengths) },
        { label: 'FOCUS NEXT', text: safeText(area.focusArea) },
    ].filter((b) => b.text);

    if (!blocks.length) {
        doc.font(fonts.regular).fontSize(9).fillColor(C.soft)
            .text('No detailed notes recorded for this area.', x + 18, cy, { width: contentWidth });
    } else {
        for (const b of blocks) {
            doc.font(fonts.bold).fontSize(7).fillColor(C.soft)
                .text(b.label, x + 18, cy, { characterSpacing: 0.7 });
            cy += 12;
            doc.font(fonts.regular).fontSize(9).fillColor(C.ink)
                .text(b.text, x + 18, cy, { width: contentWidth, lineGap: 1.5 });
            cy += doc.heightOfString(b.text, { width: contentWidth, lineGap: 1.5 }) + 10;
        }
    }

    doc.y = y + h + 12;
}

function drawSectionTitle(doc, fonts, title, subtitle) {
    ensureSpace(doc, 48);
    doc.font(fonts.bold).fontSize(13).fillColor(C.ink).text(title, 40);
    if (subtitle) {
        doc.moveDown(0.15);
        doc.font(fonts.regular).fontSize(8).fillColor(C.muted).text(subtitle, 40);
    }
    doc.moveDown(0.4);
    const y = doc.y;
    doc.moveTo(40, y).lineTo(doc.page.width - 40, y).strokeColor(C.gold).lineWidth(1.5).stroke();
    doc.y = y + 12;
}

function drawTextPanel(doc, fonts, title, body) {
    const x = 40;
    const w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(10);
    const bodyH = doc.heightOfString(body, { width: w - 36, lineGap: 2 });
    const h = 36 + bodyH + 16;
    ensureSpace(doc, h + 8);
    const y = doc.y;
    drawRoundedRect(doc, x, y, w, h, 10, C.card, C.line);
    doc.save();
    doc.rect(x, y, 5, h).fill(C.gold);
    doc.restore();
    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text(title, x + 18, y + 12, { characterSpacing: 0.8 });
    doc.font(fonts.regular).fontSize(10).fillColor(C.ink)
        .text(body, x + 18, y + 28, { width: w - 36, lineGap: 2 });
    doc.y = y + h + 14;
}

function drawGoalsPanel(doc, fonts, title, goals) {
    const items = (goals || []).map(safeText).filter(Boolean);
    if (!items.length) return;

    const x = 40;
    const w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(10);
    let contentH = 0;
    for (const g of items) {
        contentH += Math.max(18, doc.heightOfString(g, { width: w - 56, lineGap: 1.5 }) + 10);
    }
    const h = 34 + contentH + 10;
    ensureSpace(doc, Math.min(h, 220));
    let y = doc.y;

    // If very tall, draw header then items with page breaks
    drawRoundedRect(doc, x, y, w, Math.min(h, doc.page.height - y - 56), 10, C.white, C.line);
    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text(title, x + 16, y + 12, { characterSpacing: 0.8 });

    let cy = y + 30;
    items.forEach((g, i) => {
        const th = Math.max(14, doc.heightOfString(g, { width: w - 56, lineGap: 1.5 }));
        if (cy + th + 16 > doc.page.height - 56) {
            doc.addPage();
            y = doc.y;
            cy = y;
        }
        // number circle
        doc.circle(x + 24, cy + 6, 7).fill(C.header);
        doc.font(fonts.bold).fontSize(7).fillColor(C.gold)
            .text(String(i + 1), x + 17, cy + 3, { width: 14, align: 'center' });
        doc.font(fonts.regular).fontSize(10).fillColor(C.ink)
            .text(g, x + 40, cy, { width: w - 56, lineGap: 1.5 });
        cy += th + 10;
    });
    doc.y = cy + 8;
}

/**
 * Professional multi-page Performance Development Report PDF.
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
        doc.on('data', (c) => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const periodLabel = safeText(report.evaluationPeriod)
            || `${monthName(report.month)} ${report.year}`
            || '—';
        const generated = new Date();
        const generatedLabel = `Generated ${generated.toLocaleDateString('en-GB', {
            day: '2-digit', month: 'short', year: 'numeric',
        })}`;
        const meta = {
            playerName: safeText(playerName) || 'Player',
            periodLabel,
            ageCategory: safeText(report.ageCategory),
            nextEvaluationDate: safeText(report.nextEvaluationDate),
            generatedLabel,
        };

        drawHeader(doc, fonts, meta);
        drawMetaCard(doc, fonts, meta);
        drawScoreOverview(doc, fonts, areas);

        drawSectionTitle(
            doc,
            fonts,
            'Development Areas',
            'Ratings, performance notes, strengths, and next-focus guidance',
        );
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

        // Closing strip
        ensureSpace(doc, 56);
        const cx = 40;
        const cy = doc.y + 4;
        const cw = doc.page.width - 80;
        drawRoundedRect(doc, cx, cy, cw, 44, 8, C.header, null);
        doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
            .text('BALLCHART', cx + 16, cy + 10, { characterSpacing: 1.2 });
        doc.font(fonts.regular).fontSize(8).fillColor('#D0D0D0')
            .text('Train with intent. Measure progress. Raise the standard.', cx + 16, cy + 24);

        // Page chrome + numbers
        const range = doc.bufferedPageRange();
        for (let i = 0; i < range.count; i += 1) {
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
        doc.on('data', (c) => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const { width } = doc.page;
        doc.rect(0, 0, width, 100).fill(C.header);
        doc.rect(0, 100, width, 5).fill(C.gold);
        doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
            .text('BALLCHART', 40, 28, { characterSpacing: 2 });
        doc.font(fonts.bold).fontSize(22).fillColor(C.white)
            .text('Training Completion Report', 40, 52);
        doc.y = 128;

        const rows = [
            ['Development area', safeText(assignment.focusArea)],
            ['Drill / practice', safeText(assignment.drillName)],
            ['Points earned', String(assignment.pointsValue ?? '')],
            ['Status', safeText(assignment.status)],
            [
                'Completed',
                assignment.completedAt
                    ? new Date(assignment.completedAt).toLocaleString('en-GB')
                    : '—',
            ],
        ];

        rows.forEach(([label, value]) => {
            const y = doc.y;
            drawRoundedRect(doc, 40, y, width - 80, 40, 8, C.card, C.line);
            doc.font(fonts.bold).fontSize(7).fillColor(C.soft)
                .text(label.toUpperCase(), 54, y + 8, { characterSpacing: 0.6 });
            doc.font(fonts.bold).fontSize(11).fillColor(C.ink)
                .text(value || '—', 54, y + 20, { width: width - 108 });
            doc.y = y + 50;
        });

        if (safeText(assignment.playerNotes)) {
            drawTextPanel(doc, fonts, 'PLAYER NOTES', safeText(assignment.playerNotes));
        }

        const range = doc.bufferedPageRange();
        for (let i = 0; i < range.count; i += 1) {
            doc.switchToPage(range.start + i);
            drawPageChrome(doc, fonts, i, range.count, { playerName: 'Training report' });
        }
        doc.end();
    });
}

module.exports = {
    buildPerformanceReportPdf,
    buildAssignmentCompletionPdf,
    applyReportFonts,
};
