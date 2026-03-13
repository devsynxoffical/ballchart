const express = require('express');
const router = express.Router();
const { createBattle, getBattles, joinBattle } = require('../controllers/battleController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getBattles).post(protect, createBattle);
router.route('/:id/join').put(protect, joinBattle);

module.exports = router;
