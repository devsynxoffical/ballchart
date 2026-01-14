const asyncHandler = require('express-async-handler');
const Battle = require('../models/Battle');

// @desc    Create a new battle
// @route   POST /api/battles
// @access  Private
const createBattle = asyncHandler(async (req, res) => {
    const { location, dateTime } = req.body;

    if (!location || !dateTime) {
        res.status(400);
        throw new Error('Please add all fields');
    }

    const battle = await Battle.create({
        host: req.user.id,
        location,
        dateTime,
        participants: [req.user.id], // Host is automatically a participant
    });

    res.status(201).json(battle);
});

// @desc    Get all battles
// @route   GET /api/battles
// @access  Public (or Private)
const getBattles = asyncHandler(async (req, res) => {
    const battles = await Battle.find().populate('host', 'username avatarUrl').sort({ createdAt: -1 });
    res.status(200).json(battles);
});

// @desc    Join a battle
// @route   PUT /api/battles/:id/join
// @access  Private
const joinBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);

    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }

    if (battle.status !== 'pending') {
        res.status(400);
        throw new Error('Battle is already started or finished');
    }

    // Check if user already joined
    if (battle.participants.includes(req.user.id)) {
        res.status(400);
        throw new Error('You have already joined this battle');
    }

    battle.participants.push(req.user.id);
    await battle.save();

    res.status(200).json(battle);
});

module.exports = {
    createBattle,
    getBattles,
    joinBattle,
};
