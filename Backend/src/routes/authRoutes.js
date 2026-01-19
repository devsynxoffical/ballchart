const express = require('express');
const router = express.Router();
const { registerCoach, registerPlayer, loginCoach, loginPlayer, getMe, updateProfile } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/coach/signup', registerCoach);
router.post('/coach/login', loginCoach);
router.post('/player/signup', registerPlayer);
router.post('/player/login', loginPlayer);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);

module.exports = router;
