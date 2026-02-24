const asyncHandler = require('express-async-handler');
const Team = require('../models/Team');
const Coach = require('../models/Coach');
const Player = require('../models/Player');
const User = require('../models/User');

// @desc    Create a new team
// @route   POST /api/teams
// @access  Private (Head Coach)
const createTeam = asyncHandler(async (req, res) => {
    const { name, description } = req.body;

    if (!name) {
        res.status(400);
        throw new Error('Please add a team name');
    }

    const teamExists = await Team.findOne({ name });
    if (teamExists) {
        res.status(400);
        throw new Error('Team already exists');
    }

    const team = await Team.create({
        name,
        description,
        headCoach: req.user._id,
    });

    res.status(201).json(team);
});

// @desc    Assign staff to team
// @route   POST /api/teams/:id/staff
// @access  Private (Head Coach)
const assignStaffToTeam = asyncHandler(async (req, res) => {
    const { staffId } = req.body;
    const team = await Team.findById(req.params.id);

    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    // Check if staff member exists and is a coach/asst_coach
    const staff = await Coach.findById(staffId);
    if (!staff) {
        res.status(404);
        throw new Error('Staff member not found');
    }

    if (team.coachingStaff.includes(staffId)) {
        res.status(400);
        throw new Error('Staff already assigned to this team');
    }

    team.coachingStaff.push(staffId);
    await team.save();

    // Also update staff's assignedTeams
    if (!staff.assignedTeams.includes(team.name)) {
        staff.assignedTeams.push(team.name);
        await staff.save();
    }

    res.status(200).json(team);
});

// @desc    Add player to team
// @route   POST /api/teams/:id/players
// @access  Private (Coach/Asst Coach/Head Coach)
const addPlayerToTeam = asyncHandler(async (req, res) => {
    const { playerId } = req.body;
    const team = await Team.findById(req.params.id);

    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    const player = await Player.findById(playerId);
    if (!player) {
        res.status(404);
        throw new Error('Player not found');
    }

    if (team.players.includes(playerId)) {
        res.status(400);
        throw new Error('Player already in team');
    }

    team.players.push(playerId);
    await team.save();

    res.status(200).json(team);
});

// @desc    Remove player from team
// @route   DELETE /api/teams/:id/players/:playerId
// @access  Private (Coach/Head Coach)
const removePlayerFromTeam = asyncHandler(async (req, res) => {
    const team = await Team.findById(req.params.id);

    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    // Role check: Assistant Coach cannot remove players
    if (req.user.role === 'assistant_coach') {
        res.status(403);
        throw new Error('Assistant coaches cannot remove players');
    }

    team.players = team.players.filter(
        (id) => id.toString() !== req.params.playerId
    );

    await team.save();
    res.status(200).json(team);
});

// @desc    Get all teams managed by head coach
// @route   GET /api/teams/managed
// @access  Private (Head Coach)
const getManagedTeams = asyncHandler(async (req, res) => {
    const teams = await Team.find({ headCoach: req.user._id })
        .populate('coachingStaff', 'username email role')
        .populate('players', 'username position');
    res.status(200).json(teams);
});

module.exports = {
    createTeam,
    assignStaffToTeam,
    addPlayerToTeam,
    removePlayerFromTeam,
    getManagedTeams,
};
