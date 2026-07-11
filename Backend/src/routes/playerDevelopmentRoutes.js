const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
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
} = require('../controllers/playerDevelopmentController');

router.get('/catalog', protect, getCatalog);
router.patch('/catalog', protect, patchCatalog);
router.get('/my-assignments', protect, listMyAssignments);
router.get('/points/me', protect, myPoints);
router.get('/assignments', protect, listAssignmentsForPlayer);
router.post('/assignments', protect, createAssignment);
router.patch('/assignments/:assignmentId/complete', protect, completeAssignment);
router.get('/period-report/:playerId', protect, getPeriodReport);
router.put('/period-report/:playerId', protect, savePeriodReport);
router.patch('/period-report/:playerId/player-goals', protect, patchPlayerGoals);
router.get('/reports/:playerId/:year/:month/pdf', protect, monthlyReportPdf);
router.get('/reports/assignment/:assignmentId/pdf', protect, assignmentPdf);

module.exports = router;
