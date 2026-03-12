const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const asyncHandler = require('express-async-handler');
const Coach = require('../models/Coach');

const Player = require('../models/Player');
const Admin = require('../models/Admin');
const Team = require('../models/Team');

// Helper to generate JWT
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

const ensureAdmin = (req, res) => {
    if (!['head_coach', 'admin'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy admin can perform this action');
    }
};

const normalizeUserResponse = (doc) => {
    if (!doc) return null;
    return {
        _id: doc._id,
        username: doc.username,
        email: doc.email,
        role: doc.role,
        profileCompleted: !!doc.profileCompleted,
        experienceLevel: doc.experienceLevel,
        sports: doc.sports || [],
        achievements: doc.achievements || [],
        additionalInfo: doc.additionalInfo,
        teamName: doc.teamName || doc.academyName,
        assignedTeams: doc.assignedTeams || [],
        assignedTeamIds: doc.assignedTeamIds || [],
        position: doc.position,
        ageRange: doc.ageRange,
        goals: doc.goals || [],
        additionalGoals: doc.additionalGoals,
        stats: doc.stats || { matchesPlayed: 0, wins: 0, points: 0 },
        rank: doc.rank || 0,
        permissions: doc.permissions || null,
        managedBy: doc.managedBy || null,
    };
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

// @desc    Get normalized role profile
// @route   GET /api/auth/profile
// @access  Private
const getProfile = asyncHandler(async (req, res) => {
    res.status(200).json(normalizeUserResponse(req.user));
});

// @desc    Update user profile
// @route   PUT /api/auth/profile
const updateProfile = asyncHandler(async (req, res) => {
    const user = req.user; // from protect middleware
    const { role } = user;

    let updatedUser;
    if (['coach', 'head_coach', 'assistant_coach'].includes(role)) {
        const payload = {};
        const allowedFields = [
            'experienceLevel',
            'sports',
            'achievements',
            'additionalInfo',
            'teamName',
            'assignedTeams',
            'assignedTeamIds',
            'position',
            'ageRange',
        ];
        for (const key of allowedFields) {
            if (Object.prototype.hasOwnProperty.call(req.body, key)) {
                payload[key] = req.body[key];
            }
        }
        payload.profileCompleted = true;
        updatedUser = await Coach.findByIdAndUpdate(
            user._id,
            payload,
            { new: true }
        );
    } else if (role === 'player') {
        const payload = {};
        const allowedFields = [
            'position',
            'ageRange',
            'experienceLevel',
            'goals',
            'additionalGoals',
            'teamName',
        ];
        for (const key of allowedFields) {
            if (Object.prototype.hasOwnProperty.call(req.body, key)) {
                payload[key] = req.body[key];
            }
        }
        payload.profileCompleted = true;
        updatedUser = await Player.findByIdAndUpdate(
            user._id,
            payload,
            { new: true }
        );
    } else if (role === 'admin') {
        const payload = {};
        const allowedFields = ['username', 'academyName', 'logoUrl'];
        for (const key of allowedFields) {
            if (Object.prototype.hasOwnProperty.call(req.body, key)) {
                payload[key] = req.body[key];
            }
        }
        payload.profileCompleted = true;
        updatedUser = await Admin.findByIdAndUpdate(
            user._id,
            payload,
            { new: true }
        );
    }

    if (updatedUser) {
        res.status(200).json(normalizeUserResponse(updatedUser));
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
        approvalStatus: 'approved',
        isTempBanned: false,
        isStopped: false,
        approvedAt: new Date(),
    });

    if (admin) {
        res.status(201).json({
            _id: admin.id,
            username: admin.username,
            email: admin.email,
            role: 'admin',
            academyName: admin.academyName,
            profileCompleted: true,
            approvalStatus: 'approved',
            message: 'Signup successful. You can now log in with your credentials.',
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

    if (admin) {
        // Temporary bypass: approval is not required for admin academy login.
        // Auto-upgrade legacy pending accounts so existing signups can log in.
        if (admin.approvalStatus === 'pending') {
            admin.approvalStatus = 'approved';
            admin.approvedAt = admin.approvedAt || new Date();
            await admin.save();
        }
        if (admin.isTempBanned) {
            res.status(403);
            throw new Error('Academy account is temporarily banned. Please contact admin support.');
        }
        if (admin.isStopped) {
            res.status(403);
            throw new Error('Academy account is currently stopped. Please contact admin support.');
        }
    }

    if (admin && (await bcrypt.compare(password, admin.password))) {
        res.json({
            _id: admin.id,
            username: admin.username,
            email: admin.email,
            role: 'admin',
            academyName: admin.academyName,
            logoUrl: admin.logoUrl || null,
            profileCompleted: true,
            approvalStatus: admin.approvalStatus || 'approved',
            token: generateToken(admin._id, 'admin'),
        });
    } else {
        res.status(400);
        throw new Error('Invalid Admin credentials');
    }
});

// @desc    Update admin academy profile
// @route   PUT /api/auth/admin/profile
// @access  Private (Admin)
const updateAdminProfile = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const admin = await Admin.findById(req.user._id);
    if (!admin) {
        res.status(404);
        throw new Error('Admin not found');
    }

    const { academyName, logoUrl, ownerName, ownerEmail, newPassword } = req.body;

    if (academyName && academyName.trim()) admin.academyName = academyName.trim();
    if (ownerName && ownerName.trim()) admin.username = ownerName.trim();
    if (ownerEmail && ownerEmail.trim()) admin.email = ownerEmail.toLowerCase().trim();
    if (logoUrl !== undefined) admin.logoUrl = logoUrl || null;

    if (newPassword && newPassword.trim()) {
        const salt = await bcrypt.genSalt(10);
        admin.password = await bcrypt.hash(newPassword.trim(), salt);
    }

    const updated = await admin.save();

    res.status(200).json({
        _id: updated._id,
        username: updated.username,
        email: updated.email,
        academyName: updated.academyName,
        logoUrl: updated.logoUrl || null,
        role: 'admin',
    });
});

// @desc    Create staff by Head Coach
// @route   POST /api/auth/staff/create
// @access  Private (Head Coach)
const createStaff = asyncHandler(async (req, res) => {
    const {
        username,
        email,
        password,
        role,
        assignedTeamIds = [],
        permissions = {},
        customRoleName,
    } = req.body;

    ensureAdmin(req, res);

    if (!['coach', 'assistant_coach'].includes(role)) {
        res.status(400);
        throw new Error('Invalid staff role');
    }

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please include username, email and password');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Check if user exists
    const userExists = await Coach.findOne({ email: cleanEmail });
    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const staff = await Coach.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        role,
        managedBy: req.user._id,
        profileCompleted: true, // Auto-complete for managed staff
        assignedTeamIds,
        assignedTeams: assignedTeamIds,
        customRoleName,
        permissions: {
            createPlayer: !!permissions.createPlayer,
            readPlayer: permissions.readPlayer ?? true,
            updatePlayer: !!permissions.updatePlayer,
            deletePlayer: !!permissions.deletePlayer,
            createTeam: !!permissions.createTeam,
            manageStaff: !!permissions.manageStaff,
        },
    });

    res.status(201).json({
        _id: staff.id,
        username: staff.username,
        email: staff.email,
        role: staff.role,
        assignedTeamIds: staff.assignedTeamIds,
        customRoleName: staff.customRoleName,
        permissions: staff.permissions,
    });
});

// @desc    Create player account by Coach/Asst Coach
// @route   POST /api/auth/player/create
// @access  Private (Coach/Asst Coach/Head Coach)
const createPlayerByCoach = asyncHandler(async (req, res) => {
    const { username, email, password, teamId, position, ageRange } = req.body;

    if (!['head_coach', 'coach', 'assistant_coach', 'admin'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Not authorized to create players');
    }

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please include username, email and password');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Check if player exists
    const playerExists = await Player.findOne({ email: cleanEmail });
    if (playerExists) {
        res.status(400);
        throw new Error('Player already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const player = await Player.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        role: 'player',
        managedBy: req.user._id,
        profileCompleted: true,
        isVerified: true,
        position,
        ageRange,
    });

    if (teamId) {
        const team = await Team.findById(teamId);
        if (team) {
            if (!team.players.some((id) => id.toString() === player._id.toString())) {
                team.players.push(player._id);
            }
            await team.save();
        }
    }

    res.status(201).json({
        _id: player.id,
        username: player.username,
        email: player.email,
        role: player.role,
        position: player.position,
        ageRange: player.ageRange,
    });
});

// @desc    Get staff credentials for Head Coach
// @route   GET /api/auth/staff/credentials
// @access  Private (Head Coach)
const getStaffCredentials = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const staff = await Coach.find({ managedBy: req.user._id }).select('-password');
    res.status(200).json(staff);
});

// @desc    Update staff account by admin
// @route   PUT /api/auth/staff/:id
// @access  Private (Admin)
const updateStaff = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const staff = await Coach.findOne({ _id: req.params.id, managedBy: req.user._id });
    if (!staff) {
        res.status(404);
        throw new Error('Staff not found');
    }

    const {
        username,
        email,
        password,
        role,
        assignedTeamIds,
        permissions,
        customRoleName,
    } = req.body;

    if (username) staff.username = username;
    if (email) staff.email = email.toLowerCase().trim();
    if (role && ['coach', 'assistant_coach'].includes(role)) staff.role = role;
    if (customRoleName !== undefined) staff.customRoleName = customRoleName;
    if (Array.isArray(assignedTeamIds)) {
        staff.assignedTeamIds = assignedTeamIds;
        staff.assignedTeams = assignedTeamIds;
    }
    if (permissions) {
        staff.permissions = {
            createPlayer: !!permissions.createPlayer,
            readPlayer: permissions.readPlayer ?? true,
            updatePlayer: !!permissions.updatePlayer,
            deletePlayer: !!permissions.deletePlayer,
            createTeam: !!permissions.createTeam,
            manageStaff: !!permissions.manageStaff,
        };
    }
    if (password && password.trim()) {
        const salt = await bcrypt.genSalt(10);
        staff.password = await bcrypt.hash(password.trim(), salt);
    }

    const updated = await staff.save();
    res.status(200).json({
        _id: updated._id,
        username: updated.username,
        email: updated.email,
        role: updated.role,
        assignedTeamIds: updated.assignedTeamIds || [],
        permissions: updated.permissions,
        customRoleName: updated.customRoleName || null,
    });
});

// @desc    Delete staff account by admin
// @route   DELETE /api/auth/staff/:id
// @access  Private (Admin)
const deleteStaff = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const staff = await Coach.findOne({ _id: req.params.id, managedBy: req.user._id });
    if (!staff) {
        res.status(404);
        throw new Error('Staff not found');
    }

    await Team.updateMany(
        { managedBy: req.user._id },
        { $pull: { coachingStaff: staff._id } }
    );
    await Team.updateMany(
        { managedBy: req.user._id, coachStaffId: staff._id },
        { $set: { coachStaffId: null } }
    );
    await Team.updateMany(
        { managedBy: req.user._id, assistantCoachStaffId: staff._id },
        { $set: { assistantCoachStaffId: null } }
    );

    await staff.deleteOne();
    res.status(200).json({ message: 'Staff deleted successfully' });
});

// @desc    Create team by admin
// @route   POST /api/auth/team/create
// @access  Private (Admin)
const createTeamByAdmin = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);
    const { name, ageGroup, colorValue, logoPath, description } = req.body;

    if (!name || !name.trim()) {
        res.status(400);
        throw new Error('Please add a team name');
    }

    const exists = await Team.findOne({ name: name.trim(), managedBy: req.user._id });
    if (exists) {
        res.status(400);
        throw new Error('Team already exists');
    }

    const team = await Team.create({
        name: name.trim(),
        ageGroup: ageGroup || 'Open',
        colorValue: typeof colorValue === 'number' ? colorValue : 0xFFF59E0B,
        logoPath: logoPath || null,
        description,
        headCoach: req.user._id,
        managedBy: req.user._id,
        coachingStaff: [],
        players: [],
    });

    res.status(201).json(team);
});

// @desc    Assign team leads by admin
// @route   PUT /api/auth/team/:id/leads
// @access  Private (Admin)
const assignTeamLeadsByAdmin = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const { coachStaffId = null, assistantCoachStaffId = null } = req.body;
    const team = await Team.findOne({ _id: req.params.id, managedBy: req.user._id });
    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    if (coachStaffId) {
        const coach = await Coach.findOne({ _id: coachStaffId, managedBy: req.user._id });
        if (!coach) {
            res.status(400);
            throw new Error('Coach not found');
        }
        team.coachStaffId = coach._id;
    } else {
        team.coachStaffId = null;
    }

    if (assistantCoachStaffId) {
        const assistant = await Coach.findOne({ _id: assistantCoachStaffId, managedBy: req.user._id });
        if (!assistant) {
            res.status(400);
            throw new Error('Assistant coach not found');
        }
        team.assistantCoachStaffId = assistant._id;
    } else {
        team.assistantCoachStaffId = null;
    }

    const staffIds = [team.coachStaffId, team.assistantCoachStaffId].filter(Boolean);
    team.coachingStaff = staffIds;
    await team.save();

    res.status(200).json(team);
});

// @desc    Get admin overview data
// @route   GET /api/auth/admin/overview
// @access  Private (Admin)
const getAdminOverview = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const admin = await Admin.findById(req.user._id).select('-password');
    if (!admin) {
        res.status(404);
        throw new Error('Admin not found');
    }

    const [staff, teams] = await Promise.all([
        Coach.find({ managedBy: req.user._id }).select('-password'),
        Team.find({ managedBy: req.user._id }).populate('players', 'username position ageRange'),
    ]);

    res.status(200).json({
        admin: {
            _id: admin._id,
            username: admin.username,
            email: admin.email,
            academyName: admin.academyName,
            logoUrl: admin.logoUrl || null,
        },
        staff,
        teams,
    });
});

// @desc    Coach/assistant dashboard data
// @route   GET /api/auth/dashboard/coach
// @access  Private (Coach-family + Admin)
const getCoachDashboard = asyncHandler(async (req, res) => {
    const allowed = ['coach', 'assistant_coach', 'head_coach', 'admin'];
    if (!allowed.includes(req.user.role)) {
        res.status(403);
        throw new Error('Not authorized to access coach dashboard');
    }

    const coachDoc = req.user.role === 'admin'
        ? null
        : await Coach.findById(req.user._id).select('-password');

    const teamQuery = req.user.role === 'admin'
        ? { managedBy: req.user._id }
        : {
            $or: [
                { coachStaffId: req.user._id },
                { assistantCoachStaffId: req.user._id },
                { coachingStaff: req.user._id },
                { managedBy: req.user.managedBy || null },
            ],
        };

    const teams = await Team.find(teamQuery)
        .populate('players', 'username position ageRange stats')
        .populate('coachStaffId', 'username email role')
        .populate('assistantCoachStaffId', 'username email role');

    let staff = [];
    if (req.user.role === 'admin') {
        staff = await Coach.find({ managedBy: req.user._id }).select('-password');
    } else if (req.user.managedBy) {
        staff = await Coach.find({ managedBy: req.user.managedBy }).select('-password');
    }

    res.status(200).json({
        profile: normalizeUserResponse(coachDoc || req.user),
        teams,
        staff: staff.map((s) => normalizeUserResponse(s)),
    });
});

// @desc    Player dashboard data
// @route   GET /api/auth/dashboard/player
// @access  Private (Player)
const getPlayerDashboard = asyncHandler(async (req, res) => {
    if (req.user.role !== 'player') {
        res.status(403);
        throw new Error('Not authorized to access player dashboard');
    }

    const player = await Player.findById(req.user._id).select('-password');
    if (!player) {
        res.status(404);
        throw new Error('Player not found');
    }

    const team = await Team.findOne({ players: player._id })
        .populate('coachStaffId', 'username email role')
        .populate('assistantCoachStaffId', 'username email role')
        .populate('players', 'username position ageRange stats');

    const teammates = (team?.players || [])
        .filter((p) => p._id.toString() !== player._id.toString());

    res.status(200).json({
        profile: normalizeUserResponse(player),
        team,
        coachingStaff: [team?.coachStaffId, team?.assistantCoachStaffId].filter(Boolean),
        teammates,
    });
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
    updateStaff,
    deleteStaff,
    createTeamByAdmin,
    assignTeamLeadsByAdmin,
    updateAdminProfile,
    getAdminOverview,
    getProfile,
    getCoachDashboard,
    getPlayerDashboard,
};
