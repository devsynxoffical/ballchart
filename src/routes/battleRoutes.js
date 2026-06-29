const express = require('express');
const router = express.Router();
const { createBattle, getBattles, joinBattle, appendBattleEvent, updateBattle } = require('../controllers/battleController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getBattles).post(protect, createBattle);
router.route('/:id').put(protect, updateBattle);
router.route('/:id/join').put(protect, joinBattle);
router.route('/:id/events').post(protect, appendBattleEvent);

module.exports = router;
