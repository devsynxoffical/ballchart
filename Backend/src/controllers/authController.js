const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const asyncHandler = require('express-async-handler');
const Coach = require('../models/Coach');
const Player = require('../models/Player');

// Helper to generate JWT
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Register new Coach
// @route   POST /api/auth/coach/signup
const registerCoach = asyncHandler(async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please add all fields');
    }

    // Check if email is already used by a Player
    const playerExists = await Player.findOne({ email });
    if (playerExists) {
        res.status(400);
        throw new Error('Email is already registered as a Player. You cannot register as a Coach.');
    }

    // Check if coach exists
    const coachExists = await Coach.findOne({ email });
    if (coachExists) {
        res.status(400);
        throw new Error('Coach with this email already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create coach
    const coach = await Coach.create({
        username,
        email,
        password: hashedPassword,
        role: 'coach',
    });

    if (coach) {
        res.status(201).json({
            _id: coach.id,
            username: coach.username,
            email: coach.email,
            role: 'coach',
            token: generateToken(coach._id, 'coach'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid coach data');
    }
});

// @desc    Register new Player
// @route   POST /api/auth/player/signup
const registerPlayer = asyncHandler(async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please add all fields');
    }

    // Check if email is already used by a Coach
    const coachExists = await Coach.findOne({ email });
    if (coachExists) {
        res.status(400);
        throw new Error('Email is already registered as a Coach. You cannot register as a Player.');
    }

    // Check if player exists
    const playerExists = await Player.findOne({ email });
    if (playerExists) {
        res.status(400);
        throw new Error('Player with this email already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create player
    const player = await Player.create({
        username,
        email,
        password: hashedPassword,
        role: 'player',
    });

    if (player) {
        res.status(201).json({
            _id: player.id,
            username: player.username,
            email: player.email,
            role: 'player',
            token: generateToken(player._id, 'player'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid player data');
    }
});

// @desc    Login Coach
// @route   POST /api/auth/coach/login
const loginCoach = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Check for coach email
    const coach = await Coach.findOne({ email });

    if (coach && (await bcrypt.compare(password, coach.password))) {
        res.json({
            _id: coach.id,
            username: coach.username,
            email: coach.email,
            role: 'coach',
            token: generateToken(coach._id, 'coach'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid Coach credentials');
    }
});

// @desc    Login Player
// @route   POST /api/auth/player/login
const loginPlayer = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Check for player email
    const player = await Player.findOne({ email });

    if (player && (await bcrypt.compare(password, player.password))) {
        res.json({
            _id: player.id,
            username: player.username,
            email: player.email,
            role: 'player',
            token: generateToken(player._id, 'player'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid Player credentials');
    }
});

// @desc    Get current user (Generic)
// @route   GET /api/auth/me
const getMe = asyncHandler(async (req, res) => {
    // req.user is set by authMiddleware
    res.status(200).json(req.user);
});

module.exports = {
    registerCoach,
    registerPlayer,
    loginCoach,
    loginPlayer,
    getMe,
};
