const asyncHandler = require('express-async-handler');
const PeriodReport = require('../models/PeriodReport');
const TrainingAssignment = require('../models/TrainingAssignment');
const DevelopmentCatalog = require('../models/DevelopmentCatalog');
const Team = require('../models/Team');
const Player = require('../models/Player');
const { academyScopeId, isStaff } = require('../utils/userLookup');
const {
    buildPerformanceReportPdf,
    buildAssignmentCompletionPdf,
} = require('../utils/performanceReportPdf');

const STANDARD_AREAS = [
    'Technical Skills',
    'Shooting',
    'Strength & Conditioning',
    'Nutrition Awareness',
    'Mental Performance',
    'Attendance & Effort',
];

const DEFAULT_DRILLS = [
    'Form shooting',
    'Ball handling circuit',
    'Defensive slides',
    'Conditioning sprint',
    'Film review',
];

function mergeAreas(areas = []) {
    const byKey = Object.fromEntries(areas.map((a) => [a.key, a]));
    const byLabel = Object.fromEntries(areas.map((a) => [(a.label || '').toLowerCase(), a]));
    return STANDARD_AREAS.map((label, i) => {
        const key = `area_${i + 1}`;
        return byKey[key] || byLabel[label.toLowerCase()] || {
            key,
            label,
            rating: null,
            performanceComment: '',
            strengths: '',
            focusArea: '',
        };
    });
}

async function getOrCreateCatalog(scope) {
    let catalog = await DevelopmentCatalog.findOne({ managedBy: scope });
    if (!catalog) {
        catalog = await DevelopmentCatalog.create({
            managedBy: scope,
            focusAreas: [...STANDARD_AREAS],
            drillTemplates: [...DEFAULT_DRILLS],
        });
    }
    return catalog;
}

function reportDto(report) {
    return {
        periodKey: `${report.year}-${String(report.month).padStart(2, '0')}`,
        playerId: `${report.playerId}`,
        ageCategory: report.ageCategory || '',
        evaluationPeriod: report.evaluationPeriod || '',
        areas: mergeAreas(report.areas),
        summary: report.summary || '',
        goals: report.goals || [],
        playerGoals: report.playerGoals || [],
        nextEvaluationDate: report.nextEvaluationDate || '',
    };
}

async function assertPlayerAccess(req, res, playerId) {
    const scope = academyScopeId(req.user);
    if (`${req.user._id}` === `${playerId}`) return;

    if (!isStaff(req.user)) {
        res.status(403);
        throw new Error('Access denied');
    }

    // Fast academy membership check (indexed) — avoids scanning every team.
    const player = await Player.findOne({ _id: playerId, managedBy: scope })
        .select('_id')
        .lean();
    if (player) return;

    // Fallback for older records that may lack managedBy on Player.
    const inTeam = await Team.exists({ managedBy: scope, players: playerId });
    if (inTeam) return;

    res.status(404);
    throw new Error('Player not found in academy');
}

function buildPdfBuffer(report, playerName) {
    return buildPerformanceReportPdf(report, playerName, mergeAreas(report.areas));
}

const getCatalog = asyncHandler(async (req, res) => {
    const scope = academyScopeId(req.user);
    const catalog = await getOrCreateCatalog(scope);
    res.json({
        focusAreas: catalog.focusAreas,
        drillTemplates: catalog.drillTemplates,
        formationEngagementPct: catalog.formationEngagementPct,
        drillCompletionPct: catalog.drillCompletionPct,
    });
});

const patchCatalog = asyncHandler(async (req, res) => {
    if (!isStaff(req.user)) {
        res.status(403);
        throw new Error('Staff only');
    }
    const scope = academyScopeId(req.user);
    const catalog = await getOrCreateCatalog(scope);
    const body = req.body || {};
    if (body.focusAreas) catalog.focusAreas = body.focusAreas;
    if (body.drillTemplates) catalog.drillTemplates = body.drillTemplates;
    if (Object.prototype.hasOwnProperty.call(body, 'formationEngagementPct')) {
        catalog.formationEngagementPct = body.formationEngagementPct;
    } else if (body.clearFormationEngagementPct) {
        catalog.formationEngagementPct = null;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'drillCompletionPct')) {
        catalog.drillCompletionPct = body.drillCompletionPct;
    } else if (body.clearDrillCompletionPct) {
        catalog.drillCompletionPct = null;
    }
    await catalog.save();
    res.json({
        focusAreas: catalog.focusAreas,
        drillTemplates: catalog.drillTemplates,
        formationEngagementPct: catalog.formationEngagementPct,
        drillCompletionPct: catalog.drillCompletionPct,
    });
});

const getPeriodReport = asyncHandler(async (req, res) => {
    const playerId = req.params.playerId;
    const year = parseInt(req.query.year, 10);
    const month = parseInt(req.query.month, 10);
    await assertPlayerAccess(req, res, playerId);
    const report = await PeriodReport.findOne({ playerId, year, month }).lean();
    if (!report) {
        // New report — return empty template (no 404) so the editor opens instantly.
        return res.json(reportDto({
            playerId,
            year,
            month,
            ageCategory: '',
            evaluationPeriod: '',
            areas: [],
            summary: '',
            goals: [],
            playerGoals: [],
            nextEvaluationDate: '',
        }));
    }
    res.json(reportDto(report));
});

const savePeriodReport = asyncHandler(async (req, res) => {
    if (!isStaff(req.user)) {
        res.status(403);
        throw new Error('Staff only');
    }
    const playerId = req.params.playerId;
    const { year, month, ageCategory, evaluationPeriod, areas, summary, goals, nextEvaluationDate } = req.body;
    await assertPlayerAccess(req, res, playerId);
    const scope = academyScopeId(req.user);
    const report = await PeriodReport.findOneAndUpdate(
        { playerId, year, month },
        {
            playerId,
            year,
            month,
            managedBy: scope,
            ageCategory: ageCategory || '',
            evaluationPeriod: evaluationPeriod || '',
            areas: mergeAreas(areas || []),
            summary: summary || '',
            goals: goals || [],
            nextEvaluationDate: nextEvaluationDate || '',
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    res.json(reportDto(report));
});

const patchPlayerGoals = asyncHandler(async (req, res) => {
    const playerId = req.params.playerId;
    const { year, month, playerGoals } = req.body;
    if (`${req.user._id}` !== `${playerId}`) {
        res.status(403);
        throw new Error('Players can only edit their own goals');
    }
    const scope = academyScopeId(req.user);
    const report = await PeriodReport.findOneAndUpdate(
        { playerId, year, month },
        {
            playerId,
            year,
            month,
            managedBy: scope,
            playerGoals: playerGoals || [],
            areas: mergeAreas([]),
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    res.json(reportDto(report));
});

const monthlyReportPdf = asyncHandler(async (req, res) => {
    const playerId = req.params.playerId;
    const year = parseInt(req.params.year, 10);
    const month = parseInt(req.params.month, 10);
    await assertPlayerAccess(req, res, playerId);
    const report = await PeriodReport.findOne({ playerId, year, month });
    if (!report) {
        res.status(404);
        throw new Error('Period report not found');
    }
    const player = await Player.findById(playerId).select('username');
    const pdf = await buildPdfBuffer(report, player?.username || 'Player');
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="report-${year}-${month}.pdf"`);
    res.send(pdf);
});

const assignmentPdf = asyncHandler(async (req, res) => {
    const assignment = await TrainingAssignment.findById(req.params.assignmentId);
    if (!assignment) {
        res.status(404);
        throw new Error('Assignment not found');
    }
    await assertPlayerAccess(req, res, assignment.playerId);
    const pdf = await buildAssignmentCompletionPdf(assignment);
    res.setHeader('Content-Type', 'application/pdf');
    res.send(pdf);
});

const listMyAssignments = asyncHandler(async (req, res) => {
    const list = await TrainingAssignment.find({ playerId: req.user._id }).sort({ createdAt: -1 });
    res.json(list);
});

const listAssignmentsForPlayer = asyncHandler(async (req, res) => {
    const playerId = req.query.playerId;
    if (!playerId) {
        res.status(400);
        throw new Error('playerId required');
    }
    await assertPlayerAccess(req, res, playerId);
    const list = await TrainingAssignment.find({ playerId }).sort({ createdAt: -1 });
    res.json(list);
});

const createAssignment = asyncHandler(async (req, res) => {
    if (!isStaff(req.user)) {
        res.status(403);
        throw new Error('Staff only');
    }
    const scope = academyScopeId(req.user);
    const {
        playerId, focusArea, drillName, sessionIntent = 'training', dueAt, notes = '', pointsValue = 10,
    } = req.body;
    await assertPlayerAccess(req, res, playerId);
    const created = await TrainingAssignment.create({
        playerId,
        managedBy: scope,
        focusArea,
        drillName,
        sessionIntent,
        dueAt,
        notes,
        pointsValue,
        assignedBy: req.user._id,
    });
    res.status(201).json(created);
});

const completeAssignment = asyncHandler(async (req, res) => {
    const assignment = await TrainingAssignment.findById(req.params.assignmentId);
    if (!assignment) {
        res.status(404);
        throw new Error('Assignment not found');
    }
    if (`${assignment.playerId}` !== `${req.user._id}`) {
        res.status(403);
        throw new Error('Only the assigned player can complete this');
    }
    assignment.status = 'completed';
    assignment.completedAt = new Date();
    assignment.playerNotes = req.body.playerNotes || '';
    await assignment.save();
    res.json(assignment);
});

const myPoints = asyncHandler(async (req, res) => {
    const completed = await TrainingAssignment.find({ playerId: req.user._id, status: 'completed' });
    const totalPoints = completed.reduce((sum, a) => sum + (a.pointsValue || 0), 0);
    res.json({ totalPoints });
});

module.exports = {
    getCatalog,
    patchCatalog,
    getPeriodReport,
    savePeriodReport,
    patchPlayerGoals,
    monthlyReportPdf,
    assignmentPdf,
    listMyAssignments,
    listAssignmentsForPlayer,
    createAssignment,
    completeAssignment,
    myPoints,
};
