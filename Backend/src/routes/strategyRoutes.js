const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { createStrategy, getStrategies, updateStrategy } = require('../controllers/strategyController');

router.route('/').get(protect, getStrategies).post(protect, createStrategy);
router.route('/:id').put(protect, updateStrategy);

module.exports = router;
