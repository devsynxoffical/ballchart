const express = require('express');
const router = express.Router();
const { registerCoach, registerPlayer, loginCoach, loginPlayer, getMe } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/coach/signup', registerCoach);
router.post('/coach/login', loginCoach);
router.post('/player/signup', registerPlayer);
router.post('/player/login', loginPlayer);
router.get('/me', protect, getMe);

module.exports = router;
