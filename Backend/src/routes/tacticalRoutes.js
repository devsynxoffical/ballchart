const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { parseCommand } = require('../controllers/tacticalController');

const router = express.Router();

router.post('/parse-command', protect, parseCommand);

module.exports = router;
