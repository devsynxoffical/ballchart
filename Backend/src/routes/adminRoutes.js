const express = require('express');
const router = express.Router();
const {
    getAllUsers,
    getAcademies,
    getAcademyDetails,
    updateAcademy,
    updateAcademyStatus,
    deleteAcademy,
    deleteAcademyTeam,
    deleteUser,
    verifyUser,
} = require('../controllers/adminController');
const { protect } = require('../middleware/authMiddleware');

// Middleware to check if user is admin
const admin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(401);
        throw new Error('Not authorized as an admin');
    }
};

router.get('/users', protect, admin, getAllUsers);
router.delete('/users/:id', protect, admin, deleteUser);
router.put('/users/:id/verify', protect, admin, verifyUser);
router.get('/academies', protect, admin, getAcademies);
router.get('/academies/:id', protect, admin, getAcademyDetails);
router.put('/academies/:id', protect, admin, updateAcademy);
router.put('/academies/:id/status', protect, admin, updateAcademyStatus);
router.delete('/academies/:id', protect, admin, deleteAcademy);
router.delete('/academies/:academyId/teams/:teamId', protect, admin, deleteAcademyTeam);

module.exports = router;
