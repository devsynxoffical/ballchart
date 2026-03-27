const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { createStrategy, getStrategies } = require('../controllers/strategyController');

router.route('/').get(protect, getStrategies).post(protect, createStrategy);

module.exports = router;
