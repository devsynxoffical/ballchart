const express = require('express');
const router = express.Router();
const {
    createTeam,
    assignStaffToTeam,
    addPlayerToTeam,
    removePlayerFromTeam,
    getManagedTeams,
} = require('../controllers/teamController');
const { protect } = require('../middleware/authMiddleware');

// @route   POST /api/teams
// @access  Private (Head Coach)
router.post('/', protect, createTeam);

// @route   GET /api/teams/managed
// @access  Private (Head Coach)
router.get('/managed', protect, getManagedTeams);

// @route   POST /api/teams/:id/staff
// @access  Private (Head Coach)
router.post('/:id/staff', protect, assignStaffToTeam);

// @route   POST /api/teams/:id/players
// @access  Private (Coach/Asst Coach/Head Coach)
router.post('/:id/players', protect, addPlayerToTeam);

// @route   DELETE /api/teams/:id/players/:playerId
// @access  Private (Coach/Head Coach)
router.delete('/:id/players/:playerId', protect, removePlayerFromTeam);

module.exports = router;
