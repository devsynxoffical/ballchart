const express = require('express');
const router = express.Router();
const {
    registerCoach,
    registerPlayer,
    loginCoach,
    loginPlayer,
    getMe,
    getProfile,
    updateProfile,
    registerAdmin,
    loginAdmin,
    createStaff,
    createPlayerByCoach,
    getStaffCredentials,
    updateStaff,
    deleteStaff,
    createTeamByAdmin,
    updateTeamByAdmin,
    assignTeamLeadsByAdmin,
    updateAdminProfile,
    getAdminOverview,
    getCoachDashboard,
    getPlayerDashboard,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/coach/signup', registerCoach);
router.post('/coach/login', loginCoach);
router.post('/player/signup', registerPlayer);
router.post('/player/login', loginPlayer);
router.post('/admin/signup', registerAdmin);
router.post('/admin/login', loginAdmin);
router.get('/me', protect, getMe);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);

// Management Routes
router.post('/staff/create', protect, createStaff);
router.get('/staff/credentials', protect, getStaffCredentials);
router.put('/staff/:id', protect, updateStaff);
router.delete('/staff/:id', protect, deleteStaff);
router.post('/player/create', protect, createPlayerByCoach);
router.post('/team/create', protect, createTeamByAdmin);
router.put('/team/:id', protect, updateTeamByAdmin);
router.put('/team/:id/leads', protect, assignTeamLeadsByAdmin);
router.put('/admin/profile', protect, updateAdminProfile);
router.get('/admin/overview', protect, getAdminOverview);
router.get('/dashboard/coach', protect, getCoachDashboard);
router.get('/dashboard/player', protect, getPlayerDashboard);

module.exports = router;
