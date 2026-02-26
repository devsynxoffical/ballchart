const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const asyncHandler = require('express-async-handler');
const Coach = require('../models/Coach');

const Player = require('../models/Player');
const Admin = require('../models/Admin');

// Helper to generate JWT
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Register new Coach
// @route   POST /api/auth/coach/signup
const registerCoach = asyncHandler(async (req, res) => {
    res.status(403);
    throw new Error('Public coach registration is disabled. Ask academy admin to create your account.');
});

// @desc    Register new Player
// @route   POST /api/auth/player/signup
const registerPlayer = asyncHandler(async (req, res) => {
    res.status(403);
    throw new Error('Public player registration is disabled. Ask academy admin to create your account.');
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
            role: coach.role,
            profileCompleted: coach.profileCompleted,
            token: generateToken(coach._id, coach.role),
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
            role: player.role,
            profileCompleted: player.profileCompleted,
            token: generateToken(player._id, player.role),
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

// @desc    Update user profile
// @route   PUT /api/auth/profile
const updateProfile = asyncHandler(async (req, res) => {
    const user = req.user; // from protect middleware
    const { role } = user;

    let updatedUser;
    if (['coach', 'head_coach', 'assistant_coach'].includes(role)) {
        updatedUser = await Coach.findByIdAndUpdate(
            user._id,
            { ...req.body, profileCompleted: true },
            { new: true }
        );
    } else if (role === 'player') {
        updatedUser = await Player.findByIdAndUpdate(
            user._id,
            { ...req.body, profileCompleted: true },
            { new: true }
        );
    }

    if (updatedUser) {
        res.status(200).json({
            _id: updatedUser.id,
            username: updatedUser.username,
            email: updatedUser.email,
            role: updatedUser.role,
            profileCompleted: updatedUser.profileCompleted,
            // include other fields as needed
        });
    } else {
        res.status(404);
        throw new Error('User not found');
    }
});



// @desc    Register new Admin
// @route   POST /api/auth/admin/signup
const registerAdmin = asyncHandler(async (req, res) => {
    const { username, email, password, academyName } = req.body;

    if (!username || !email || !password || !academyName) {
        res.status(400);
        throw new Error('Please add all fields');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Check if admin exists
    const adminExists = await Admin.findOne({ email: cleanEmail });
    if (adminExists) {
        res.status(400);
        throw new Error('Admin with this email already exists');
    }

    // Prevent email overlap with other user types
    const coachExists = await Coach.findOne({ email: cleanEmail });
    const playerExists = await Player.findOne({ email: cleanEmail });
    if (coachExists || playerExists) {
        res.status(400);
        throw new Error('Email already exists in another account type');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create admin
    const admin = await Admin.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        role: 'admin',
        academyName,
        profileCompleted: true,
    });

    if (admin) {
        res.status(201).json({
            _id: admin.id,
            username: admin.username,
            email: admin.email,
            role: 'admin',
            academyName: admin.academyName,
            profileCompleted: true,
            token: generateToken(admin._id, 'admin'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid admin data');
    }
});

// @desc    Login Admin
// @route   POST /api/auth/admin/login
const loginAdmin = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        res.status(400);
        throw new Error('Please include all fields');
    }

    // Normalize email
    const cleanEmail = email.toLowerCase().trim();

    // Check for admin email
    const admin = await Admin.findOne({ email: cleanEmail });

    if (admin && (await bcrypt.compare(password, admin.password))) {
        res.json({
            _id: admin.id,
            username: admin.username,
            email: admin.email,
            role: 'admin',
            academyName: admin.academyName,
            profileCompleted: true,
            token: generateToken(admin._id, 'admin'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid Admin credentials');
    }
});

// @desc    Create staff by Head Coach
// @route   POST /api/auth/staff/create
// @access  Private (Head Coach)
const createStaff = asyncHandler(async (req, res) => {
    const { username, email, password, role } = req.body;

    if (!['head_coach', 'admin'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy admin can create staff');
    }

    if (!['coach', 'assistant_coach'].includes(role)) {
        res.status(400);
        throw new Error('Invalid staff role');
    }

    // Check if user exists
    const userExists = await Coach.findOne({ email });
    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const staff = await Coach.create({
        username,
        email,
        password: hashedPassword,
        role,
        managedBy: req.user._id,
        profileCompleted: true, // Auto-complete for managed staff
    });

    res.status(201).json({
        _id: staff.id,
        username: staff.username,
        email: staff.email,
        role: staff.role,
    });
});

// @desc    Create player account by Coach/Asst Coach
// @route   POST /api/auth/player/create
// @access  Private (Coach/Asst Coach/Head Coach)
const createPlayerByCoach = asyncHandler(async (req, res) => {
    const { username, email, password } = req.body;

    if (!['head_coach', 'coach', 'assistant_coach', 'admin'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Not authorized to create players');
    }

    // Check if player exists
    const playerExists = await Player.findOne({ email });
    if (playerExists) {
        res.status(400);
        throw new Error('Player already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const player = await Player.create({
        username,
        email,
        password: hashedPassword,
        role: 'player',
        managedBy: req.user._id,
        profileCompleted: true,
        isVerified: true,
    });

    res.status(201).json({
        _id: player.id,
        username: player.username,
        email: player.email,
        role: player.role,
    });
});

// @desc    Get staff credentials for Head Coach
// @route   GET /api/auth/staff/credentials
// @access  Private (Head Coach)
const getStaffCredentials = asyncHandler(async (req, res) => {
    if (!['head_coach', 'admin'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy admin can access staff credentials');
    }

    const staff = await Coach.find({ managedBy: req.user._id }).select('-password');
    res.status(200).json(staff);
});

module.exports = {
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
};
