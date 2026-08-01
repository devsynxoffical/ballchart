const path = require('path');
const fs = require('fs');
const PDFDocument = require('pdfkit');

const REPORT_FONT_REGULAR = path.join(__dirname, '../../assets/fonts/ReportSans.ttf');
const REPORT_FONT_BOLD = path.join(__dirname, '../../assets/fonts/ReportSans-Bold.ttf');

const C = {
    ink: '#1E293B', // Slate 800 (primary text)
    muted: '#475569', // Slate 600 (secondary text)
    soft: '#64748B', // Slate 500 (labels/captions)
    line: '#E2E8F0', // Slate 200 (borders/dividers)
    card: '#F8FAFC', // Slate 50 (card backgrounds)
    white: '#FFFFFF',
    header: '#0F172A', // Slate 900 (primary brand color)
    gold: '#EAB308', // Yellow 500 (accent highlight)
    goldDark: '#CA8A04', // Yellow 600
    good: '#10B981', // Emerald 500 (positive progress)
    warn: '#F59E0B', // Amber 500 (needs focus)
    red: '#EF4444', // Red 500 (priority attention)
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

// Vector-based arc rendering loop
function drawArc(doc, cx, cy, r, startAngleDeg, endAngleDeg, color, width) {
    doc.save();
    doc.lineWidth(width);
    doc.strokeColor(color);
    doc.lineCap('round');
    
    let first = true;
    for (let a = startAngleDeg; a <= endAngleDeg; a += 1.5) {
        const rad = (a - 90) * Math.PI / 180;
        const x = cx + r * Math.cos(rad);
        const y = cy + r * Math.sin(rad);
        if (first) {
            doc.moveTo(x, y);
            first = false;
        } else {
            doc.lineTo(x, y);
        }
    }
    doc.stroke();
    doc.restore();
}

// Segmented track rating component
function drawRatingScale(doc, x, y, rating) {
    const maxVal = 5;
    const blockW = 16;
    const blockH = 8;
    const gap = 4;
    const r = 2; // rounded corners for pills

    const value = Math.max(0, Math.min(5, Number(rating) || 0));

    for (let i = 1; i <= maxVal; i++) {
        const bx = x + (i - 1) * (blockW + gap);
        // Draw background block
        drawRoundedRect(doc, bx, y, blockW, blockH, r, '#E2E8F0', null);

        // Draw filled block proportion
        if (i <= value) {
            drawRoundedRect(doc, bx, y, blockW, blockH, r, C.gold, null);
        } else if (i - 1 < value) {
            const fillPct = value - (i - 1);
            const fillW = blockW * fillPct;
            doc.save();
            doc.roundedRect(bx, y, blockW, blockH, r).clip();
            doc.fillColor(C.gold).rect(bx, y, fillW, blockH).fill();
            doc.restore();
        }
    }
}

// Mini rating bar for summary list
function drawRatingBar(doc, x, y, w, h, rating) {
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    drawRoundedRect(doc, x, y, w, h, h / 2, '#F1F5F9', null);
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
        
        doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
            .text('BALLCHART  ·  PERFORMANCE REPORT', 40, 18, {
                width: width - 80,
                align: 'left',
                characterSpacing: 0.8
            });
        doc.font(fonts.regular).fontSize(8).fillColor(C.muted)
            .text(meta.playerName, 40, 18, { width: width - 80, align: 'right' });
        doc.y = 44;
    }

    // Footer
    const footerY = height - 36;
    doc.save();
    doc.moveTo(40, footerY - 8).lineTo(width - 40, footerY - 8).strokeColor(C.line).lineWidth(0.8).stroke();
    
    doc.font(fonts.regular).fontSize(8).fillColor(C.soft)
        .text('BallChart · Confidential Athlete Performance Report', 40, footerY, {
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
    doc.rect(0, 0, width, 130).fill(C.header);
    doc.rect(0, 130, width, 4).fill(C.gold);

    // Render Logo if present
    const logoPath = path.join(__dirname, '../../assets/images/logo.png');
    if (fs.existsSync(logoPath)) {
        try {
            doc.image(logoPath, width - 110, 25, { width: 70 });
        } catch (e) {
            console.error("Failed to render header logo:", e);
        }
    }

    doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
        .text('BALLCHART', 40, 30, { characterSpacing: 2 });
    doc.font(fonts.bold).fontSize(7).fillColor('#94A3B8')
        .text('ATHLETE DEVELOPMENT NETWORK', 40, 44, { characterSpacing: 1.2 });

    doc.font(fonts.bold).fontSize(20).fillColor(C.white)
        .text('Performance Development Report', 40, 64, { width: width - 160 });

    doc.font(fonts.regular).fontSize(8.5).fillColor('#CBD5E1')
        .text(meta.generatedLabel, 40, 94);
        
    doc.restore();
    doc.y = 150;
}

function drawMetaCard(doc, fonts, meta) {
    const x = 40;
    const y = doc.y;
    const w = doc.page.width - 80;
    const h = 76;
    
    drawRoundedRect(doc, x, y, w, h, 12, '#F8FAFC', C.line);

    const colW = (w - 32) / 3;
    const rows = [
        { label: 'ATHLETE / PLAYER', value: meta.playerName },
        { label: 'EVALUATION PERIOD', value: meta.periodLabel },
        { label: 'AGE CATEGORY', value: meta.ageCategory || '—' },
    ];

    rows.forEach((row, i) => {
        const cx = x + 16 + i * colW;
        
        // Vertical divider
        if (i > 0) {
            doc.moveTo(cx - 8, y + 16).lineTo(cx - 8, y + 60).strokeColor(C.line).lineWidth(1).stroke();
        }

        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text(row.label, cx, y + 16, { width: colW - 16, characterSpacing: 0.8 });
        doc.font(fonts.bold).fontSize(12).fillColor(C.header)
            .text(row.value, cx, y + 30, { width: colW - 16, ellipsis: true });
    });

    if (meta.nextEvaluationDate) {
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text(`NEXT PLANNED EVALUATION:`, x + 16, y + 54);
        doc.font(fonts.bold).fontSize(8).fillColor(C.goldDark)
            .text(meta.nextEvaluationDate, x + 140, y + 53);
    }

    doc.y = y + h + 18;
}

function drawScoreOverview(doc, fonts, areas) {
    const avg = avgRating(areas);
    const x = 40;
    const y = doc.y;
    const w = doc.page.width - 80;
    const h = 120;

    drawRoundedRect(doc, x, y, w, h, 12, C.white, C.line);
    
    doc.save();
    doc.rect(x, y, 6, h).fillColor(C.header).fill();
    doc.restore();

    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text('OVERALL DEVELOPMENT SNAPSHOT', x + 20, y + 14, { characterSpacing: 1 });

    // Circular gauge center
    const gaugeX = x + 65;
    const gaugeY = y + 70;
    const gaugeR = 32;
    
    // Draw background circle
    doc.save();
    doc.lineWidth(8);
    doc.strokeColor('#F1F5F9');
    doc.circle(gaugeX, gaugeY, gaugeR).stroke();
    doc.restore();

    // Draw active progress arc
    if (avg > 0) {
        const ratingPct = avg / 5;
        drawArc(doc, gaugeX, gaugeY, gaugeR, 0, ratingPct * 360, C.gold, 8);
    }

    // Centered average score text
    const scoreText = avg == null ? '—' : avg.toFixed(1);
    doc.font(fonts.bold).fontSize(20).fillColor(C.header);
    const textW = doc.widthOfString(scoreText);
    doc.text(scoreText, gaugeX - textW / 2, gaugeY - 12);
    
    doc.font(fonts.bold).fontSize(7).fillColor(C.soft);
    const maxText = '/ 5.0';
    const maxTextW = doc.widthOfString(maxText);
    doc.text(maxText, gaugeX - maxTextW / 2, gaugeY + 10);

    // Average label details
    const labelX = x + 135;
    doc.font(fonts.bold).fontSize(12).fillColor(C.header)
        .text(ratingLabel(avg), labelX, y + 36, { width: 180 });
        
    doc.font(fonts.regular).fontSize(9).fillColor(C.muted)
        .text(`${areas.filter((a) => a.rating).length} of ${areas.length} areas rated`, labelX, y + 54);

    // Development badge
    const badgeText = ratingLabel(avg).toUpperCase();
    const badgeW = doc.widthOfString(badgeText) + 12;
    const badgeColor = avg >= 4.5 ? C.good : (avg >= 3.5 ? C.good : (avg >= 2.5 ? C.goldDark : C.warn));
    drawRoundedRect(doc, labelX, y + 72, badgeW, 16, 4, badgeColor, null);
    doc.font(fonts.bold).fontSize(7).fillColor(C.white)
        .text(badgeText, labelX + 6, y + 76);

    // Mini area progress bar list on the right
    const miniX = x + w - 210;
    areas.slice(0, 6).forEach((area, i) => {
        const my = y + 16 + i * 16;
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.header)
            .text(area.label, miniX, my, { width: 100, ellipsis: true });
        
        drawRatingBar(doc, miniX + 110, my + 1, 80, 6, area.rating);
        
        const ratingVal = typeof area.rating === 'number' ? area.rating.toFixed(1) : '—';
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text(ratingVal, miniX + 195, my, { width: 15, align: 'right' });
    });

    doc.y = y + h + 20;
}

function measureAreaCardHeight(doc, fonts, area, contentWidth) {
    let h = 56; // Header and initial padding
    const blocks = [
        { text: safeText(area.performanceComment) },
        { text: safeText(area.strengths) },
        { text: safeText(area.focusArea) },
    ].filter((b) => b.text);

    if (!blocks.length) {
        h += 22;
    } else {
        for (const b of blocks) {
            doc.font(fonts.regular).fontSize(9);
            const textH = doc.heightOfString(b.text, { width: contentWidth - 24, lineGap: 1.5 });
            const blockH = textH + 18;
            h += blockH + 10;
        }
    }
    return h + 4; // minor padding bottom
}

function drawAreaCard(doc, fonts, area, index) {
    const x = 40;
    const w = doc.page.width - 80;
    const contentWidth = w - 32;
    
    const h = measureAreaCardHeight(doc, fonts, area, contentWidth);
    ensureSpace(doc, h + 12);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 12, C.white, C.line);

    // Number Badge / Indicator
    drawRoundedRect(doc, x + 16, y + 14, 22, 22, 6, C.header, null);
    doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
        .text(String(index + 1).padStart(2, '0'), x + 16, y + 20, { width: 22, align: 'center' });

    // Category Label
    doc.font(fonts.bold).fontSize(12).fillColor(C.header)
        .text(area.label || `Area ${index + 1}`, x + 48, y + 18, { width: w - 180 });

    // Segmented Rating Scale
    const rating = typeof area.rating === 'number' ? area.rating : null;
    if (rating != null) {
        drawRatingScale(doc, x + w - 150, y + 20, rating);
        doc.font(fonts.bold).fontSize(10).fillColor(C.header)
            .text(`${rating.toFixed(1)}/5`, x + w - 50, y + 19, { width: 34, align: 'right' });
    } else {
        doc.font(fonts.regular).fontSize(9).fillColor(C.soft)
            .text('Unrated', x + w - 80, y + 20, { width: 66, align: 'right' });
    }

    // Divider line
    doc.moveTo(x + 16, y + 46).lineTo(x + w - 16, y + 46).strokeColor(C.line).lineWidth(0.8).stroke();

    let cy = y + 56;
    const blocks = [
        { label: 'PERFORMANCE NOTES', text: safeText(area.performanceComment), border: '#3B82F6' },
        { label: 'STRENGTHS', text: safeText(area.strengths), border: C.good },
        { label: 'FOCUS NEXT', text: safeText(area.focusArea), border: C.warn },
    ].filter((b) => b.text);

    if (!blocks.length) {
        doc.font(fonts.regular).fontSize(9).fillColor(C.soft)
            .text('No detailed notes recorded for this area.', x + 20, cy, { width: contentWidth - 8 });
    } else {
        for (const b of blocks) {
            const textH = doc.heightOfString(b.text, { width: contentWidth - 24, lineGap: 1.5 });
            const blockH = textH + 18;
            
            // Draw background
            drawRoundedRect(doc, x + 16, cy, contentWidth, blockH, 6, '#F8FAFC', null);
            
            // Left border accent
            doc.save();
            doc.fillColor(b.border).rect(x + 16, cy, 4, blockH).fill();
            doc.restore();

            // Label text
            doc.font(fonts.bold).fontSize(7).fillColor(C.soft)
                .text(b.label, x + 28, cy + 6, { characterSpacing: 0.8 });
            
            // Notes text
            doc.font(fonts.regular).fontSize(9).fillColor(C.header)
                .text(b.text, x + 28, cy + 16, { width: contentWidth - 22, lineGap: 1.5 });

            cy += blockH + 10;
        }
    }

    doc.y = y + h + 12;
}

function drawSectionTitle(doc, fonts, title, subtitle) {
    ensureSpace(doc, 50);
    const y = doc.y;
    
    doc.save();
    doc.fillColor(C.gold).rect(40, y + 2, 4, 18).fill();
    doc.restore();

    doc.font(fonts.bold).fontSize(13).fillColor(C.header).text(title, 52, y);
    if (subtitle) {
        doc.font(fonts.regular).fontSize(8.5).fillColor(C.muted).text(subtitle, 52, y + 16);
    }
    
    doc.y = y + (subtitle ? 34 : 24);
}

function drawTextPanel(doc, fonts, title, body) {
    const x = 40;
    const w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(9.5);
    const bodyH = doc.heightOfString(body, { width: w - 40, lineGap: 2.5 });
    const h = 40 + bodyH + 16;
    ensureSpace(doc, h + 8);
    const y = doc.y;

    drawRoundedRect(doc, x, y, w, h, 12, '#F8FAFC', C.line);
    
    doc.save();
    doc.fillColor(C.header).rect(x, y, 6, h).fill();
    doc.restore();

    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text(title, x + 20, y + 14, { characterSpacing: 1 });
    
    doc.font(fonts.regular).fontSize(9.5).fillColor(C.header)
        .text(body, x + 20, y + 30, { width: w - 40, lineGap: 2.5 });
        
    doc.y = y + h + 16;
}

function drawGoalsPanel(doc, fonts, title, goals) {
    const items = (goals || []).map(safeText).filter(Boolean);
    if (!items.length) return;

    const x = 40;
    const w = doc.page.width - 80;
    doc.font(fonts.regular).fontSize(9.5);
    
    let contentH = 0;
    for (const g of items) {
        contentH += Math.max(20, doc.heightOfString(g, { width: w - 60, lineGap: 2 }) + 16);
    }
    const h = 36 + contentH + 8;
    ensureSpace(doc, Math.min(h, 240));
    let y = doc.y;

    drawRoundedRect(doc, x, y, w, Math.min(h, doc.page.height - y - 56), 12, C.white, C.line);
    
    doc.font(fonts.bold).fontSize(8).fillColor(C.soft)
        .text(title, x + 20, y + 14, { characterSpacing: 1 });

    let cy = y + 34;
    items.forEach((g, i) => {
        const th = Math.max(16, doc.heightOfString(g, { width: w - 60, lineGap: 2 }));
        const itemH = th + 12;

        if (cy + itemH + 16 > doc.page.height - 56) {
            doc.addPage();
            y = doc.y;
            cy = y + 16;
        }

        const cbSize = 12;
        const cbX = x + 20;
        const cbY = cy + 2;
        
        drawRoundedRect(doc, cbX, cbY, cbSize, cbSize, 3, '#F1F5F9', '#CBD5E1');
        
        doc.save();
        doc.lineWidth(1.5);
        doc.strokeColor(C.goldDark);
        doc.moveTo(cbX + 3, cbY + 6).lineTo(cbX + 5, cbY + 9).lineTo(cbX + 9, cbY + 3).stroke();
        doc.restore();

        doc.font(fonts.regular).fontSize(9.5).fillColor(C.header)
            .text(g, x + 40, cy, { width: w - 60, lineGap: 2 });
            
        cy += itemH + 8;
    });
    doc.y = cy + 4;
}

function drawSignatureBlock(doc, fonts) {
    const x = 40;
    const w = doc.page.width - 80;
    const h = 76;
    ensureSpace(doc, h + 10);
    const y = doc.y;
    
    const colW = (w - 40) / 2;
    
    // Left: Coach
    const leftX = x;
    doc.moveTo(leftX, y + 45).lineTo(leftX + colW, y + 45).strokeColor(C.soft).lineWidth(0.8).stroke();
    doc.font(fonts.bold).fontSize(8.5).fillColor(C.header)
        .text('HEAD COACH SIGNATURE', leftX, y + 52);
    doc.font(fonts.regular).fontSize(7.5).fillColor(C.soft)
        .text('BallChart Certified Academy Staff', leftX, y + 64);
        
    // Right: Athlete/Parent
    const rightX = x + colW + 40;
    doc.moveTo(rightX, y + 45).lineTo(rightX + colW, y + 45).strokeColor(C.soft).lineWidth(0.8).stroke();
    doc.font(fonts.bold).fontSize(8.5).fillColor(C.header)
        .text('ATHLETE / PARENT SIGNATURE', rightX, y + 52);
    doc.font(fonts.regular).fontSize(7.5).fillColor(C.soft)
        .text('Acknowledgment of Development Plan', rightX, y + 64);
        
    doc.y = y + h + 10;
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

        // Draw Official Signatures Block
        drawSectionTitle(doc, fonts, 'Sign-Off & Validation', 'Formal validation of development plan');
        drawSignatureBlock(doc, fonts);

        // Closing strip
        ensureSpace(doc, 56);
        const cx = 40;
        const cy = doc.y + 4;
        const cw = doc.page.width - 80;
        drawRoundedRect(doc, cx, cy, cw, 44, 10, C.header, null);
        doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
            .text('BALLCHART', cx + 20, cy + 12, { characterSpacing: 1.5 });
        doc.font(fonts.regular).fontSize(8).fillColor('#94A3B8')
            .text('Train with intent. Measure progress. Raise the standard.', cx + 20, cy + 26);

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
        doc.rect(0, 0, width, 110).fill(C.header);
        doc.rect(0, 110, width, 4).fill(C.gold);
        
        doc.font(fonts.bold).fontSize(9).fillColor(C.gold)
            .text('BALLCHART', 40, 28, { characterSpacing: 2 });
        doc.font(fonts.bold).fontSize(18).fillColor(C.white)
            .text('Training Assignment Completion', 40, 46);
        doc.font(fonts.regular).fontSize(8.5).fillColor('#CBD5E1')
            .text('Official completion validation record', 40, 76);
            
        doc.y = 134;

        const x = 40;
        const w = width - 80;
        const h = 180;
        
        drawRoundedRect(doc, x, doc.y, w, h, 12, C.white, C.line);
        
        doc.save();
        doc.fillColor(C.good).rect(x, doc.y, 6, h).fill();
        doc.restore();

        const cy = doc.y;
        const colW = (w - 32) / 2;
        
        // Column 1
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text('DEVELOPMENT FOCUS AREA', x + 20, cy + 16, { characterSpacing: 0.8 });
        doc.font(fonts.bold).fontSize(11).fillColor(C.header)
            .text(safeText(assignment.focusArea) || '—', x + 20, cy + 28, { width: colW - 10 });

        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text('ASSIGNED DRILL / PRACTICE', x + colW + 20, cy + 16, { characterSpacing: 0.8 });
        doc.font(fonts.bold).fontSize(11).fillColor(C.header)
            .text(safeText(assignment.drillName) || '—', x + colW + 20, cy + 28, { width: colW - 10 });

        // Divider
        doc.moveTo(x + 20, cy + 58).lineTo(x + w - 20, cy + 58).strokeColor(C.line).lineWidth(0.8).stroke();

        // Row 2
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text('POINTS AWARDED', x + 20, cy + 72, { characterSpacing: 0.8 });
        const pointsStr = `+${assignment.pointsValue ?? 10} XP`;
        doc.font(fonts.bold).fontSize(14).fillColor(C.goldDark)
            .text(pointsStr, x + 20, cy + 84);

        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text('COMPLETION STATUS', x + colW + 20, cy + 72, { characterSpacing: 0.8 });
        const statusText = (safeText(assignment.status) || 'COMPLETED').toUpperCase();
        const statusBadgeW = doc.widthOfString(statusText) + 12;
        drawRoundedRect(doc, x + colW + 20, cy + 84, statusBadgeW, 16, 4, C.good, null);
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.white)
            .text(statusText, x + colW + 26, cy + 88);

        // Divider
        doc.moveTo(x + 20, cy + 114).lineTo(x + w - 20, cy + 114).strokeColor(C.line).lineWidth(0.8).stroke();

        // Row 3
        doc.font(fonts.bold).fontSize(7.5).fillColor(C.soft)
            .text('VALIDATION TIMESTAMP', x + 20, cy + 128, { characterSpacing: 0.8 });
        const dateStr = assignment.completedAt
            ? new Date(assignment.completedAt).toLocaleString('en-GB', {
                day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
              })
            : '—';
        doc.font(fonts.bold).fontSize(10).fillColor(C.header)
            .text(dateStr, x + 20, cy + 140);

        doc.y = cy + h + 18;

        if (safeText(assignment.playerNotes)) {
            drawTextPanel(doc, fonts, 'PLAYER LOG NOTES', safeText(assignment.playerNotes));
        }

        // Signature
        ensureSpace(doc, 60);
        const sigY = doc.y;
        doc.moveTo(x, sigY + 30).lineTo(x + 200, sigY + 30).strokeColor(C.soft).lineWidth(0.8).stroke();
        doc.font(fonts.bold).fontSize(8).fillColor(C.header)
            .text('AUTHORIZED BY ACADEMY COACH', x, sigY + 36);

        const range = doc.bufferedPageRange();
        for (let i = 0; i < range.count; i += 1) {
            doc.switchToPage(range.start + i);
            drawPageChrome(doc, fonts, i, range.count, { playerName: 'Training completion' });
        }
        doc.end();
    });
}

module.exports = {
    buildPerformanceReportPdf,
    buildAssignmentCompletionPdf,
    applyReportFonts,
};
