const express = require('express');
const router = express.Router();
const {
    createBattle,
    getBattles,
    getMyBattles,
    getUpcomingBattles,
    getOngoingBattles,
    getFinishedBattles,
    getBattleStats,
    getBattleLocations,
    joinBattle,
    leaveBattle,
    startBattle,
    finishBattle,
    cancelBattle,
    deleteBattle,
    incrementViewCount,
    appendBattleEvent,
    updateBattle,
} = require('../controllers/battleController');
const { protect } = require('../middleware/authMiddleware');

router.get('/locations', protect, getBattleLocations);
router.get('/stats', protect, getBattleStats);
router.get('/my', protect, getMyBattles);
router.get('/upcoming', protect, getUpcomingBattles);
router.get('/ongoing', protect, getOngoingBattles);
router.get('/finished', protect, getFinishedBattles);

router.route('/').get(protect, getBattles).post(protect, createBattle);
router.route('/:id').put(protect, updateBattle).delete(protect, deleteBattle);
router.put('/:id/join', protect, joinBattle);
router.post('/:id/leave', protect, leaveBattle);
router.post('/:id/start', protect, startBattle);
router.post('/:id/finish', protect, finishBattle);
router.post('/:id/cancel', protect, cancelBattle);
router.post('/:id/view', protect, incrementViewCount);
router.post('/:id/events', protect, appendBattleEvent);

module.exports = router;
