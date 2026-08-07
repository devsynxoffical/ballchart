const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const asyncHandler = require('express-async-handler');
const Coach = require('../models/Coach');

const Player = require('../models/Player');
const Admin = require('../models/Admin');
const Team = require('../models/Team');
const Battle = require('../models/Battle');

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

const canManagePlayerAction = (user, actionKey) => {
    if (!user) return false;
    if (['admin', 'head_coach'].includes(user.role)) return true;
    if (!['coach', 'assistant_coach', 'custom'].includes(user.role)) return false;
    return user.permissions && user.permissions[actionKey] === true;
};

/** Normalize the full staff permission map used by Flutter admin toggles. */
const normalizeStaffPermissions = (permissions = {}) => ({
    createPlayer: !!permissions.createPlayer,
    readPlayer: permissions.readPlayer !== false,
    updatePlayer: !!permissions.updatePlayer,
    deletePlayer: !!permissions.deletePlayer,
    createTeam: !!permissions.createTeam,
    manageStaff: !!permissions.manageStaff,
    createBattle: !!permissions.createBattle,
    manageBattle: !!permissions.manageBattle,
    createStrategy: !!permissions.createStrategy,
    manageStrategy: !!permissions.manageStrategy,
});

const hasStaffPermission = (user, actionKey) => {
    if (!user) return false;
    if (['admin', 'head_coach'].includes(user.role)) return true;
    if (!['coach', 'assistant_coach', 'custom'].includes(user.role)) return false;
    return user.permissions && user.permissions[actionKey] === true;
};

const roleToTeamLeadField = (role) => {
    if (role === 'coach') return 'coachStaffId';
    if (role === 'assistant_coach') return 'assistantCoachStaffId';
    return null;
};

const normalizeIdList = (ids = []) => (Array.isArray(ids) ? ids.map((id) => id.toString()) : []);

/** Ensure email is free across Admin / Coach / Player (excluding current user). */
const assertEmailAvailable = async (cleanEmail, { excludeId, excludeRole } = {}) => {
    const exclude = (doc, role) => {
        if (!doc) return false;
        if (!excludeId) return true;
        const sameId = doc._id.toString() === excludeId.toString();
        const sameRole =
            !excludeRole ||
            excludeRole === role ||
            (excludeRole === 'admin' && role === 'admin') ||
            (['coach', 'assistant_coach', 'head_coach'].includes(excludeRole) && role === 'coach');
        return !(sameId && sameRole);
    };

    const admin = await Admin.findOne({ email: cleanEmail });
    if (admin && exclude(admin, 'admin')) {
        const err = new Error('Email already exists');
        err.statusCode = 400;
        throw err;
    }
    const coach = await Coach.findOne({ email: cleanEmail });
    if (coach && exclude(coach, 'coach')) {
        const err = new Error('Email already exists');
        err.statusCode = 400;
        throw err;
    }
    const player = await Player.findOne({ email: cleanEmail });
    if (player && exclude(player, 'player')) {
        const err = new Error('Email already exists');
        err.statusCode = 400;
        throw err;
    }
};

const syncStaffLeadAssignments = async ({
    adminId,
    staffId,
    previousRole,
    previousAssignedTeamIds = [],
    nextRole,
    nextAssignedTeamIds = [],
}) => {
    const previousField = roleToTeamLeadField(previousRole);
    const nextField = roleToTeamLeadField(nextRole);
    const previousTeamIds = normalizeIdList(previousAssignedTeamIds);
    const nextTeamIds = normalizeIdList(nextAssignedTeamIds);

    if (previousField && previousTeamIds.length) {
        await Team.updateMany(
            {
                managedBy: adminId,
                _id: { $in: previousTeamIds },
                [previousField]: staffId,
            },
            {
                $set: { [previousField]: null },
                $pull: { coachingStaff: staffId },
            }
        );
    }

    if (nextField && nextTeamIds.length) {
        await Team.updateMany(
            {
                managedBy: adminId,
                _id: { $in: nextTeamIds },
            },
            {
                $set: { [nextField]: staffId },
                $addToSet: { coachingStaff: staffId },
            }
        );
    }
};

const normalizeUserResponse = (doc) => {
    if (!doc) return null;
    const role = doc.role;
    let permissions = doc.permissions || null;
    if (permissions && typeof permissions === 'object') {
        const raw = typeof permissions.toObject === 'function' ? permissions.toObject() : { ...permissions };
        // Legacy coach docs only had 6 flags — fill missing battle/strategy keys from role defaults.
        if (raw.createBattle === undefined) {
            raw.createBattle = role === 'coach';
        }
        if (raw.manageBattle === undefined) {
            raw.manageBattle = role === 'coach';
        }
        if (raw.createStrategy === undefined) {
            raw.createStrategy = role === 'coach';
        }
        if (raw.manageStrategy === undefined) {
            raw.manageStrategy = role === 'coach';
        }
        permissions = normalizeStaffPermissions(raw);
    }
    return {
        _id: doc._id,
        username: doc.username,
        email: doc.email,
        tempPassword: doc.tempPassword,
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
        permissions,
        managedBy: doc.managedBy || null,
        profilePic: doc.profilePic || doc.profileImageUrl || doc.logoUrl || null,
        profileImageUrl: doc.profileImageUrl || doc.profilePic || doc.logoUrl || null,
        logoUrl: doc.logoUrl || null,
        academyName: doc.academyName || null,
    };
};

const assertEmailAvailableAcrossRoles = async (
    cleanEmail,
    { excludeAdminId = null, excludeCoachId = null, excludePlayerId = null } = {}
) => {
    if (!cleanEmail) return;

    const [admin, coach, player] = await Promise.all([
        Admin.findOne({
            email: cleanEmail,
            ...(excludeAdminId ? { _id: { $ne: excludeAdminId } } : {}),
        }).select('_id'),
        Coach.findOne({
            email: cleanEmail,
            ...(excludeCoachId ? { _id: { $ne: excludeCoachId } } : {}),
        }).select('_id'),
        Player.findOne({
            email: cleanEmail,
            ...(excludePlayerId ? { _id: { $ne: excludePlayerId } } : {}),
        }).select('_id'),
    ]);

    if (admin || coach || player) {
        throw new Error('Email already exists in another account');
    }
};

// @desc    Register new Coach
// @route   POST /api/auth/coach/signup
const registerCoach = asyncHandler(async (req, res) => {
    const { username, email, password, academyName } = req.body;

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please include username, email and password');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Prevent duplicate emails
    await assertEmailAvailableAcrossRoles(cleanEmail);

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Find academy if provided
    let academyId = null;
    if (academyName) {
        const admin = await Admin.findOne({ academyName: new RegExp(`^${academyName}$`, 'i') });
        if (admin) academyId = admin._id;
    }

    const coach = await Coach.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        role: 'coach',
        managedBy: academyId,
        profileCompleted: false,
        isVerified: false,
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
    const { username, email, password, academyName } = req.body;

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please include username, email and password');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Prevent duplicate emails
    await assertEmailAvailableAcrossRoles(cleanEmail);

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Find academy if provided
    let academyId = null;
    if (academyName) {
        const admin = await Admin.findOne({ academyName: new RegExp(`^${academyName}$`, 'i') });
        if (admin) academyId = admin._id;
    }

    const player = await Player.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        tempPassword: password, // Store plain text for management view
        role: 'player',
        managedBy: academyId,
        profileCompleted: false,
        isVerified: false,
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
    res.status(200).json(normalizeUserResponse(req.user));
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

    // Login email can be changed here — next login must use the new email.
    if (Object.prototype.hasOwnProperty.call(req.body, 'email') && req.body.email) {
        const cleanEmail = String(req.body.email).toLowerCase().trim();
        if (!cleanEmail.includes('@')) {
            res.status(400);
            throw new Error('Please enter a valid email address');
        }
        const current = (user.email || '').toLowerCase().trim();
        if (cleanEmail !== current) {
            try {
                await assertEmailAvailable(cleanEmail, { excludeId: user._id, excludeRole: role });
            } catch (e) {
                res.status(e.statusCode || 400);
                throw e;
            }
            req.body.email = cleanEmail;
        } else {
            req.body.email = current;
        }
    }

    let updatedUser;
    if (['coach', 'head_coach', 'assistant_coach', 'custom'].includes(role)) {
        const payload = {};
        const allowedFields = [
            'username',
            'email',
            'experienceLevel',
            'sports',
            'achievements',
            'additionalInfo',
            'teamName',
            'assignedTeams',
            'assignedTeamIds',
            'position',
            'ageRange',
            'profilePic',
            'profileImageUrl',
        ];
        for (const key of allowedFields) {
            if (Object.prototype.hasOwnProperty.call(req.body, key)) {
                payload[key] = req.body[key];
            }
        }
        const pic = payload.profilePic || payload.profileImageUrl;
        if (pic) {
            payload.profilePic = pic;
            payload.profileImageUrl = pic;
        }
        payload.profileCompleted = true;
        updatedUser = await Coach.findByIdAndUpdate(
            user._id,
            payload,
            { new: true, runValidators: false }
        );
    } else if (role === 'player') {
        const payload = {};
        const allowedFields = [
            'username',
            'email',
            'position',
            'ageRange',
            'experienceLevel',
            'goals',
            'additionalGoals',
            'teamName',
            'profileImageUrl',
            'profilePic',
        ];
        for (const key of allowedFields) {
            if (Object.prototype.hasOwnProperty.call(req.body, key)) {
                payload[key] = req.body[key];
            }
        }
        const pic = payload.profileImageUrl || payload.profilePic;
        if (pic) {
            payload.profileImageUrl = pic;
            payload.profilePic = pic;
        }
        payload.profileCompleted = true;
        updatedUser = await Player.findByIdAndUpdate(
            user._id,
            payload,
            { new: true, runValidators: false }
        );
    } else if (role === 'admin') {
        const payload = {};
        const allowedFields = ['username', 'email', 'academyName', 'logoUrl'];
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
    if (ownerEmail && ownerEmail.trim()) {
        const cleanEmail = ownerEmail.toLowerCase().trim();
        if (!cleanEmail.includes('@')) {
            res.status(400);
            throw new Error('Please enter a valid email address');
        }
        if (cleanEmail !== (admin.email || '').toLowerCase().trim()) {
            try {
                await assertEmailAvailable(cleanEmail, { excludeId: admin._id, excludeRole: 'admin' });
            } catch (e) {
                res.status(e.statusCode || 400);
                throw e;
            }
            admin.email = cleanEmail;
        }
    }
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

// @desc    Change password (verify current password first)
// @route   PUT /api/auth/change-password
// @access  Private
const changePassword = asyncHandler(async (req, res) => {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
        res.status(400);
        throw new Error('Current password and new password are required');
    }
    if (String(newPassword).trim().length < 6) {
        res.status(400);
        throw new Error('New password must be at least 6 characters');
    }

    const role = req.user.role;
    let Model;
    if (role === 'admin' || role === 'head_coach') {
        Model = Admin;
    } else if (['coach', 'assistant_coach'].includes(role)) {
        Model = Coach;
    } else if (role === 'player') {
        Model = Player;
    } else {
        res.status(400);
        throw new Error('Unsupported account type');
    }

    const doc = await Model.findById(req.user._id);
    if (!doc) {
        res.status(404);
        throw new Error('User not found');
    }

    const matches = await bcrypt.compare(String(oldPassword), doc.password);
    if (!matches) {
        res.status(400);
        throw new Error('Current password is incorrect');
    }

    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(String(newPassword).trim(), salt);
    doc.password = hashed;
    if (role === 'player' && Object.prototype.hasOwnProperty.call(doc.toObject(), 'tempPassword')) {
        doc.tempPassword = String(newPassword).trim();
    }
    await doc.save();

    res.status(200).json({ ok: true, message: 'Password updated successfully' });
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

    const validRoles = ['coach', 'assistant_coach', 'custom'];
    if (!validRoles.includes(role)) {
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
    const adminExists = await Admin.findOne({ email: cleanEmail });
    const playerExists = await Player.findOne({ email: cleanEmail });
    if (userExists || adminExists || playerExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const normalizedAssignedTeamIds = normalizeIdList(assignedTeamIds);

    const staff = await Coach.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        role,
        managedBy: req.user._id,
        profileCompleted: true, // Auto-complete for managed staff
        assignedTeamIds: normalizedAssignedTeamIds,
        assignedTeams: normalizedAssignedTeamIds,
        customRoleName: role === 'custom' ? (customRoleName || null) : null,
        permissions: normalizeStaffPermissions(permissions),
    });

    await syncStaffLeadAssignments({
        adminId: req.user._id,
        staffId: staff._id,
        previousRole: null,
        previousAssignedTeamIds: [],
        nextRole: staff.role,
        nextAssignedTeamIds: normalizedAssignedTeamIds,
    });

    req.io?.emit('STAFF_CREATED', { academyId: req.user._id, staffId: staff._id });

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
    const { username, email, password, teamId, position, ageRange, profileImageUrl, profilePic } = req.body;

    if (!['head_coach', 'coach', 'assistant_coach', 'admin', 'custom'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Not authorized to create players');
    }
    if (!canManagePlayerAction(req.user, 'createPlayer')) {
        res.status(403);
        throw new Error('You do not have permission to create players');
    }

    if (!username || !email || !password) {
        res.status(400);
        throw new Error('Please include username, email and password');
    }

    const cleanEmail = email.toLowerCase().trim();

    // Check if email exists in any user role to avoid profile crossover.
    try {
        await assertEmailAvailableAcrossRoles(cleanEmail);
    } catch (error) {
        res.status(400);
        throw new Error('Email already exists');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const avatar = profileImageUrl || profilePic || '';
    const player = await Player.create({
        username,
        email: cleanEmail,
        password: hashedPassword,
        tempPassword: password, // Store plain text for management view
        role: 'player',
        managedBy: req.user._id,
        profileCompleted: true,
        isVerified: true,
        position,
        ageRange,
        profileImageUrl: avatar,
        profilePic: avatar,
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

    req.io?.emit('PLAYER_CREATED', { academyId: req.user._id, teamId, playerId: player._id });

    res.status(201).json({
        _id: player.id,
        username: player.username,
        email: player.email,
        tempPassword: player.tempPassword,
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
    res.status(200).json(staff.map((s) => normalizeUserResponse(s)));
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
        profilePic,
    } = req.body;

    const previousRole = staff.role;
    const previousAssignedTeamIds = normalizeIdList(staff.assignedTeamIds);

    if (username) staff.username = username;
    if (email) {
        const cleanEmail = email.toLowerCase().trim();
        if (cleanEmail !== staff.email) {
            try {
                await assertEmailAvailableAcrossRoles(cleanEmail, { excludeCoachId: staff._id });
            } catch (error) {
                res.status(400);
                throw new Error('Email already exists');
            }
        }
        staff.email = cleanEmail;
    }
    if (role && ['coach', 'assistant_coach', 'custom'].includes(role)) staff.role = role;
    if (customRoleName !== undefined) staff.customRoleName = customRoleName;
    if (profilePic !== undefined) {
        staff.profilePic = profilePic;
        staff.profileImageUrl = profilePic;
    }
    if (req.body.profileImageUrl !== undefined) {
        staff.profileImageUrl = req.body.profileImageUrl;
        staff.profilePic = req.body.profileImageUrl;
    }
    if (Array.isArray(assignedTeamIds)) {
        const normalizedAssignedTeamIds = normalizeIdList(assignedTeamIds);
        staff.assignedTeamIds = normalizedAssignedTeamIds;
        staff.assignedTeams = normalizedAssignedTeamIds;
    }
    if (permissions) {
        staff.permissions = normalizeStaffPermissions(permissions);
        staff.markModified('permissions');
    }
    if (password && password.trim()) {
        const salt = await bcrypt.genSalt(10);
        staff.password = await bcrypt.hash(password.trim(), salt);
    }

    const updated = await staff.save();

    await syncStaffLeadAssignments({
        adminId: req.user._id,
        staffId: updated._id,
        previousRole,
        previousAssignedTeamIds,
        nextRole: updated.role,
        nextAssignedTeamIds: normalizeIdList(updated.assignedTeamIds),
    });

    req.io.emit('STAFF_UPDATED', { academyId: req.user._id, staffId: updated._id });

    const savedPerms = normalizeStaffPermissions(
        updated.permissions && typeof updated.permissions.toObject === 'function'
            ? updated.permissions.toObject()
            : (updated.permissions || {})
    );

    res.status(200).json({
        _id: updated._id,
        username: updated.username,
        email: updated.email,
        role: updated.role,
        assignedTeamIds: updated.assignedTeamIds || [],
        permissions: savedPerms,
        customRoleName: updated.customRoleName || null,
        profilePic: updated.profilePic || updated.profileImageUrl || null,
        profileImageUrl: updated.profileImageUrl || updated.profilePic || null,
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
    req.io.emit('STAFF_DELETED', { academyId: req.user._id, staffId: req.params.id });

    res.status(200).json({ message: 'Staff deleted successfully' });
});

// @desc    Create team by admin
// @route   POST /api/auth/team/create
// @access  Private (Admin)
const createTeamByAdmin = asyncHandler(async (req, res) => {
    const isOwner = ['admin', 'head_coach'].includes(req.user.role);
    if (!isOwner && !hasStaffPermission(req.user, 'createTeam')) {
        res.status(403);
        throw new Error('You do not have permission to create teams');
    }

    const academyId = isOwner ? req.user._id : (req.user.managedBy || req.user._id);
    const { 
        name, 
        ageGroup, 
        colorValue, 
        logoPath, 
        description,
        coachStaffId,
        assistantCoachStaffId
    } = req.body;

    if (!name || !name.trim()) {
        res.status(400);
        throw new Error('Please add a team name');
    }

    const exists = await Team.findOne({ name: name.trim(), managedBy: academyId });
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
        headCoach: academyId,
        managedBy: academyId,
        coachStaffId: coachStaffId || null,
        assistantCoachStaffId: assistantCoachStaffId || null,
        coachingStaff: [],
        players: [],
    });

    req.io.emit('TEAM_CREATED', { academyId, teamId: team._id });

    res.status(201).json(team);
});

// @desc    Update team details by admin
// @route   PUT /api/auth/team/:id
// @access  Private (Admin)
const updateTeamByAdmin = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const { name, ageGroup, colorValue, logoPath, description, coachStaffId, assistantCoachStaffId } = req.body;
    const team = await Team.findOne({ _id: req.params.id, managedBy: req.user._id });
    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    if (name !== undefined) {
        if (!name || !name.trim()) {
            res.status(400);
            throw new Error('Please add a team name');
        }
        const duplicate = await Team.findOne({
            _id: { $ne: team._id },
            managedBy: req.user._id,
            name: name.trim(),
        });
        if (duplicate) {
            res.status(400);
            throw new Error('Team with this name already exists');
        }
        team.name = name.trim();
    }

    if (ageGroup !== undefined) team.ageGroup = ageGroup || 'Open';
    if (colorValue !== undefined) {
        team.colorValue = typeof colorValue === 'number' ? colorValue : team.colorValue;
    }
    if (logoPath !== undefined) team.logoPath = logoPath || null;
    if (description !== undefined) team.description = description;
    if (coachStaffId !== undefined) team.coachStaffId = coachStaffId || null;
    if (assistantCoachStaffId !== undefined) team.assistantCoachStaffId = assistantCoachStaffId || null;

    const updated = await team.save();

    req.io.emit('TEAM_UPDATED', { academyId: req.user._id, teamId: updated._id });

    res.status(200).json(updated);
});

// @desc    Delete team by admin
// @route   DELETE /api/auth/team/:id
// @access  Private (Admin)
const deleteTeamByAdmin = asyncHandler(async (req, res) => {
    ensureAdmin(req, res);

    const team = await Team.findOne({ _id: req.params.id, managedBy: req.user._id });
    if (!team) {
        res.status(404);
        throw new Error('Team not found');
    }

    const teamIdString = team._id.toString();
    await Coach.updateMany(
        { managedBy: req.user._id },
        {
            $pull: {
                assignedTeamIds: teamIdString,
                assignedTeams: team.name,
            },
        }
    );

    await team.deleteOne();

    req.io.emit('TEAM_DELETED', { academyId: req.user._id, teamId: teamIdString });

    res.status(200).json({ message: 'Team deleted successfully' });
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

    req.io.emit('TEAM_LEADS_UPDATED', { academyId: req.user._id, teamId: team._id });

    res.status(200).json(team);
});

const getManagedPlayerForAdmin = async (adminId, playerId) => {
    const staff = await Coach.find({ managedBy: adminId }).select('_id');
    const staffIds = staff.map((member) => member._id);
    return Player.findOne({
        _id: playerId,
        $or: [
            { managedBy: adminId },
            { managedBy: { $in: staffIds } },
        ],
    });
};

const getManagedPlayerForUser = async (user, playerId) => {
    if (['admin', 'head_coach'].includes(user.role)) {
        return getManagedPlayerForAdmin(user._id, playerId);
    }
    if (!['coach', 'assistant_coach'].includes(user.role)) return null;

    const academyId = user.managedBy;
    if (!academyId) return null;
    const staff = await Coach.find({ managedBy: academyId }).select('_id');
    const staffIds = staff.map((member) => member._id);
    return Player.findOne({
        _id: playerId,
        $or: [
            { managedBy: academyId },
            { managedBy: { $in: staffIds } },
            { managedBy: user._id },
        ],
    });
};

// @desc    Update player by admin
// @route   PUT /api/auth/player/:id
// @access  Private (Admin)
const updatePlayerByAdmin = asyncHandler(async (req, res) => {
    if (!canManagePlayerAction(req.user, 'updatePlayer')) {
        res.status(403);
        throw new Error('You do not have permission to update players');
    }

    const player = await getManagedPlayerForUser(req.user, req.params.id);
    if (!player) {
        res.status(404);
        throw new Error('Player not found');
    }

    const { username, email, password, position, ageRange } = req.body;
    if (username !== undefined) player.username = username;
    if (position !== undefined) player.position = position;
    if (ageRange !== undefined) player.ageRange = ageRange;
    if (email !== undefined && email.trim()) {
        const cleanEmail = email.toLowerCase().trim();
        if (cleanEmail !== player.email) {
            try {
                await assertEmailAvailableAcrossRoles(cleanEmail, { excludePlayerId: player._id });
            } catch (error) {
                res.status(400);
                throw new Error('Email already exists');
            }
        }
        player.email = cleanEmail;
    }
    if (password !== undefined && password.trim()) {
        const salt = await bcrypt.genSalt(10);
        player.password = await bcrypt.hash(password.trim(), salt);
        player.tempPassword = password.trim(); // Update temp password as well
    }

    const updated = await player.save();

    req.io.emit('PLAYER_UPDATED', { academyId: req.user._id, playerId: updated._id });

    res.status(200).json({
        _id: updated._id,
        username: updated.username,
        email: updated.email,
        role: updated.role,
        position: updated.position,
        ageRange: updated.ageRange,
    });
});

// @desc    Delete player by admin
// @route   DELETE /api/auth/player/:id
// @access  Private (Admin)
const deletePlayerByAdmin = asyncHandler(async (req, res) => {
    if (!canManagePlayerAction(req.user, 'deletePlayer')) {
        res.status(403);
        throw new Error('You do not have permission to delete players');
    }

    const player = await getManagedPlayerForUser(req.user, req.params.id);
    if (!player) {
        res.status(404);
        throw new Error('Player not found');
    }

    const adminScopeId = ['admin', 'head_coach'].includes(req.user.role)
        ? req.user._id
        : req.user.managedBy;
    await Team.updateMany(
        { managedBy: adminScopeId, players: player._id },
        { $pull: { players: player._id } }
    );
    await player.deleteOne();

    req.io.emit('PLAYER_DELETED', { academyId: adminScopeId, playerId: player._id });

    res.status(200).json({ message: 'Player deleted successfully' });
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

    const [staffRaw, teams] = await Promise.all([
        Coach.find({ managedBy: req.user._id }).select('-password'),
        Team.find({ managedBy: req.user._id }).populate('players', 'username position ageRange profileImageUrl profilePic'),
    ]);

    const staff = staffRaw.map((s) => normalizeUserResponse(s));

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

    const assignedTeamIds = normalizeIdList(req.user.assignedTeamIds);
    const teamQuery = req.user.role === 'admin'
        ? { managedBy: req.user._id }
        : {
            $or: [
                { coachStaffId: req.user._id },
                { assistantCoachStaffId: req.user._id },
                { coachingStaff: req.user._id },
                ...(assignedTeamIds.length ? [{ _id: { $in: assignedTeamIds } }] : []),
            ],
        };

    const teams = await Team.find(teamQuery)
        .populate('players', 'username email position ageRange stats profileImageUrl profilePic')
        .populate('coachStaffId', 'username email role profilePic profileImageUrl')
        .populate('assistantCoachStaffId', 'username email role profilePic profileImageUrl');

    let staff = [];
    if (req.user.role === 'admin') {
        staff = await Coach.find({ managedBy: req.user._id }).select('-password');
    } else if (req.user.managedBy) {
        staff = await Coach.find({ managedBy: req.user.managedBy }).select('-password');
    }

    // Same academy scope used by the battles API so coaches see the games they schedule.
    const academyScopeId = req.user.role === 'admin' ? req.user._id : (req.user.managedBy || null);
    const upcomingBattles = academyScopeId
        ? await Battle.find({
              managedBy: academyScopeId,
              status: 'pending',
              dateTime: { $gt: new Date() },
          })
              .sort({ dateTime: 1, createdAt: -1 })
              .limit(5)
        : [];

    res.status(200).json({
        profile: normalizeUserResponse(coachDoc || req.user),
        teams,
        staff: staff.map((s) => normalizeUserResponse(s)),
        upcomingBattles,
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
        .populate('players', 'username position ageRange stats profileImageUrl profilePic');

    const teammates = (team?.players || [])
        .filter((p) => p._id.toString() !== player._id.toString());

    res.status(200).json({
        profile: normalizeUserResponse(player),
        team,
        coachingStaff: [team?.coachStaffId, team?.assistantCoachStaffId].filter(Boolean),
        teammates,
    });
});

// @desc    Get player by id (staff)
// @route   GET /api/auth/player/:id
// @access  Private (Staff)
const getPlayerById = asyncHandler(async (req, res) => {
    if (!canManagePlayerAction(req.user, 'updatePlayer') && !['admin', 'head_coach', 'coach', 'assistant_coach'].includes(req.user.role)) {
        res.status(403);
        throw new Error('Access denied');
    }
    const player = await getManagedPlayerForUser(req.user, req.params.id);
    if (!player) {
        res.status(404);
        throw new Error('Player not found');
    }
    const team = await Team.findOne({ players: player._id, managedBy: player.managedBy }).select('name ageGroup');
    res.status(200).json({
        _id: player._id,
        id: player._id,
        username: player.username,
        email: player.email,
        role: player.role,
        position: player.position,
        ageRange: player.ageRange,
        jersey: player.jersey,
        profileImageUrl: player.profileImageUrl || player.profilePic || null,
        profilePic: player.profilePic || player.profileImageUrl || null,
        teamName: team?.name,
        teamId: team?._id,
    });
});

// @desc    Delete authenticated user's account
// @route   POST /api/auth/account/delete
// @access  Private
const deleteMyAccount = asyncHandler(async (req, res) => {
    const phrase = (req.body?.confirmPhrase || '').toString().trim();
    if (phrase !== 'DELETE MY ACCOUNT') {
        res.status(400);
        throw new Error('Confirmation phrase required');
    }
    const userId = req.user._id;
    const role = req.user.role;
    if (role === 'admin' || role === 'head_coach') {
        await Admin.findByIdAndDelete(userId);
    } else if (['coach', 'assistant_coach'].includes(role)) {
        await Coach.findByIdAndDelete(userId);
    } else if (role === 'player') {
        await Player.findByIdAndDelete(userId);
        await Team.updateMany({ players: userId }, { $pull: { players: userId } });
    } else {
        res.status(400);
        throw new Error('Unsupported account type');
    }
    res.status(200).json({ ok: true, message: 'Account deleted' });
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
    updateTeamByAdmin,
    deleteTeamByAdmin,
    assignTeamLeadsByAdmin,
    updatePlayerByAdmin,
    deletePlayerByAdmin,
    updateAdminProfile,
    getAdminOverview,
    getProfile,
    getCoachDashboard,
    getPlayerDashboard,
    getPlayerById,
    deleteMyAccount,
    changePassword,
};
