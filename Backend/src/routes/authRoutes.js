const express = require('express');
const router = express.Router();
const {
    registerCoach,
    registerPlayer,
    loginCoach,
    loginPlayer,
    getMe,
    updateProfile,
    registerAdmin,
    loginAdmin,
    createStaff,
    createPlayerByCoach,
    getStaffCredentials
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/coach/signup', registerCoach);
router.post('/coach/login', loginCoach);
router.post('/player/signup', registerPlayer);
router.post('/player/login', loginPlayer);
router.post('/admin/signup', registerAdmin);
router.post('/admin/login', loginAdmin);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);

// Management Routes
router.post('/staff/create', protect, createStaff);
router.get('/staff/credentials', protect, getStaffCredentials);
router.post('/player/create', protect, createPlayerByCoach);

module.exports = router;
