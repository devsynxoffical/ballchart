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
    getStaffCredentials,
    updateStaff,
    deleteStaff,
    createTeamByAdmin,
    assignTeamLeadsByAdmin,
    getAdminOverview,
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
router.put('/staff/:id', protect, updateStaff);
router.delete('/staff/:id', protect, deleteStaff);
router.post('/player/create', protect, createPlayerByCoach);
router.post('/team/create', protect, createTeamByAdmin);
router.put('/team/:id/leads', protect, assignTeamLeadsByAdmin);
router.get('/admin/overview', protect, getAdminOverview);

module.exports = router;
