const asyncHandler = require('express-async-handler');
const Admin = require('../models/Admin');
const Coach = require('../models/Coach');
const Player = require('../models/Player');
const Team = require('../models/Team');

const resolveAcademyScope = async (academyId) => {
    const academy = await Admin.findById(academyId).select('_id');
    if (!academy) {
        throw new Error('Academy not found');
    }
    return academy._id;
};

const getUsersByScope = async ({ academyId, role }) => {
    const coachRoleFilter = role === 'coach'
        ? { role: { $in: ['coach', 'assistant_coach', 'head_coach'] } }
        : {};
    const playerRoleFilter = role === 'player' ? { role: 'player' } : {};

    const coaches = role === 'player'
        ? []
        : await Coach.find({
            ...(academyId ? { managedBy: academyId } : {}),
            ...coachRoleFilter,
        }).select('-password');

    const coachIds = coaches.map((coach) => coach._id);

    const players = role === 'coach'
        ? []
        : await Player.find({
            ...(academyId
                ? { $or: [{ managedBy: academyId }, { managedBy: { $in: coachIds } }] }
                : {}),
            ...playerRoleFilter,
        }).select('-password');

    return [
        ...coaches.map((coach) => ({ ...coach.toObject(), type: 'coach' })),
        ...players.map((player) => ({ ...player.toObject(), type: 'player' })),
    ];
};

// @desc    Get all users (optionally scoped by academy/role)
// @route   GET /api/admin/users
// @access  Private/Admin
const getAllUsers = asyncHandler(async (req, res) => {
    const { academyId, role } = req.query;
    let scopedAcademyId = null;

    if (academyId) {
        scopedAcademyId = await resolveAcademyScope(academyId);
    }

    const allUsers = await getUsersByScope({
        academyId: scopedAcademyId,
        role,
    });

    res.json(allUsers);
});

// @desc    List all academies with quick totals
// @route   GET /api/admin/academies
// @access  Private/Admin
const getAcademies = asyncHandler(async (req, res) => {
    const academies = await Admin.find({}).select('-password').sort({ createdAt: -1 });

    const payload = await Promise.all(
        academies.map(async (academy) => {
            const staff = await Coach.find({ managedBy: academy._id }).select('_id');
            const staffIds = staff.map((member) => member._id);
            const [teamsCount, staffCount, playersCount] = await Promise.all([
                Team.countDocuments({ managedBy: academy._id }),
                Promise.resolve(staff.length),
                Player.countDocuments({
                    $or: [
                        { managedBy: academy._id },
                        { managedBy: { $in: staffIds } },
                    ],
                }),
            ]);

            return {
                _id: academy._id,
                academyName: academy.academyName,
                username: academy.username,
                email: academy.email,
                logoUrl: academy.logoUrl || null,
                profileCompleted: academy.profileCompleted,
                approvalStatus: academy.approvalStatus || 'approved',
                isTempBanned: !!academy.isTempBanned,
                isStopped: !!academy.isStopped,
                approvedAt: academy.approvedAt || null,
                createdAt: academy.createdAt,
                counts: {
                    teams: teamsCount,
                    staff: staffCount,
                    players: playersCount,
                },
            };
        })
    );

    res.status(200).json(payload);
});

// @desc    Get complete academy detail
// @route   GET /api/admin/academies/:id
// @access  Private/Admin
const getAcademyDetails = asyncHandler(async (req, res) => {
    const academyId = await resolveAcademyScope(req.params.id);

    const academy = await Admin.findById(academyId).select('-password');
    if (!academy) {
        res.status(404);
        throw new Error('Academy not found');
    }

    const staff = await Coach.find({ managedBy: academyId }).select('-password');
    const teams = await Team.find({ managedBy: academyId })
        .populate('players', 'username email role position ageRange isVerified profileCompleted')
        .populate('coachStaffId', 'username email role isVerified')
        .populate('assistantCoachStaffId', 'username email role isVerified');

    const staffIds = staff.map((member) => member._id);
    const teamPlayerIds = teams.flatMap((team) => (team.players || []).map((player) => player._id));
    const uniquePlayerIds = [...new Set(teamPlayerIds.map((id) => id.toString()))];

    const players = await Player.find({
        $or: [
            { managedBy: academyId },
            { managedBy: { $in: staffIds } },
            uniquePlayerIds.length > 0 ? { _id: { $in: uniquePlayerIds } } : { _id: null },
        ],
    }).select('-password');

    res.status(200).json({
        academy: {
            _id: academy._id,
            academyName: academy.academyName,
            username: academy.username,
            email: academy.email,
            logoUrl: academy.logoUrl || null,
            profileCompleted: academy.profileCompleted,
            approvalStatus: academy.approvalStatus || 'approved',
            isTempBanned: !!academy.isTempBanned,
            isStopped: !!academy.isStopped,
            approvedAt: academy.approvedAt || null,
            createdAt: academy.createdAt,
        },
        teams,
        staff,
        players,
        stats: {
            teams: teams.length,
            staff: staff.length,
            players: players.length,
        },
    });
});

// @desc    Update academy profile by ID
// @route   PUT /api/admin/academies/:id
// @access  Private/Admin
const updateAcademy = asyncHandler(async (req, res) => {
    const academyId = await resolveAcademyScope(req.params.id);
    const academy = await Admin.findById(academyId);

    if (!academy) {
        res.status(404);
        throw new Error('Academy not found');
    }

    const { academyName, username, email, logoUrl } = req.body;

    if (academyName !== undefined) academy.academyName = academyName;
    if (username !== undefined) academy.username = username;
    if (email !== undefined) academy.email = email.toLowerCase().trim();
    if (logoUrl !== undefined) academy.logoUrl = logoUrl || null;

    const updated = await academy.save();

    res.status(200).json({
        _id: updated._id,
        academyName: updated.academyName,
        username: updated.username,
        email: updated.email,
        logoUrl: updated.logoUrl || null,
        profileCompleted: updated.profileCompleted,
        approvalStatus: updated.approvalStatus || 'approved',
        isTempBanned: !!updated.isTempBanned,
        isStopped: !!updated.isStopped,
        approvedAt: updated.approvedAt || null,
    });
});

// @desc    Update academy approval/access status
// @route   PUT /api/admin/academies/:id/status
// @access  Private/Admin
const updateAcademyStatus = asyncHandler(async (req, res) => {
    const academyId = await resolveAcademyScope(req.params.id);
    const academy = await Admin.findById(academyId);

    if (!academy) {
        res.status(404);
        throw new Error('Academy not found');
    }

    const { action } = req.body;
    const normalizedAction = String(action || '').toLowerCase();

    switch (normalizedAction) {
        case 'approve':
            academy.approvalStatus = 'approved';
            academy.isTempBanned = false;
            academy.isStopped = false;
            academy.approvedAt = new Date();
            break;
        case 'reject':
            academy.approvalStatus = 'rejected';
            break;
        case 'temp_ban':
            academy.isTempBanned = true;
            break;
        case 'untemp_ban':
            academy.isTempBanned = false;
            break;
        case 'stop':
            academy.isStopped = true;
            break;
        case 'unstop':
            academy.isStopped = false;
            break;
        case 'reset_access':
            academy.isTempBanned = false;
            academy.isStopped = false;
            if (academy.approvalStatus !== 'approved') {
                academy.approvalStatus = 'approved';
            }
            if (!academy.approvedAt) academy.approvedAt = new Date();
            break;
        default:
            res.status(400);
            throw new Error('Invalid action. Use approve, reject, temp_ban, untemp_ban, stop, unstop, or reset_access');
    }

    const updated = await academy.save();

    res.status(200).json({
        _id: updated._id,
        academyName: updated.academyName,
        approvalStatus: updated.approvalStatus || 'approved',
        isTempBanned: !!updated.isTempBanned,
        isStopped: !!updated.isStopped,
        approvedAt: updated.approvedAt || null,
    });
});

// @desc    Delete academy and all managed resources
// @route   DELETE /api/admin/academies/:id
// @access  Private/Admin
const deleteAcademy = asyncHandler(async (req, res) => {
    const academyId = await resolveAcademyScope(req.params.id);

    const academy = await Admin.findById(academyId);
    if (!academy) {
        res.status(404);
        throw new Error('Academy not found');
    }

    const staff = await Coach.find({ managedBy: academyId }).select('_id');
    const staffIds = staff.map((member) => member._id);

    await Team.deleteMany({ managedBy: academyId });
    await Player.deleteMany({
        $or: [
            { managedBy: academyId },
            { managedBy: { $in: staffIds } },
        ],
    });
    await Coach.deleteMany({ managedBy: academyId });
    await academy.deleteOne();

    res.status(200).json({ message: 'Academy and related data deleted successfully' });
});

// @desc    Delete team inside an academy
// @route   DELETE /api/admin/academies/:academyId/teams/:teamId
// @access  Private/Admin
const deleteAcademyTeam = asyncHandler(async (req, res) => {
    const academyId = await resolveAcademyScope(req.params.academyId);
    const team = await Team.findOne({ _id: req.params.teamId, managedBy: academyId });

    if (!team) {
        res.status(404);
        throw new Error('Team not found in this academy');
    }

    await team.deleteOne();
    res.status(200).json({ message: 'Team deleted successfully' });
});

const fetchUserByTypeOrAuto = async (id, type) => {
    if (type === 'coach') {
        const coach = await Coach.findById(id);
        return coach ? { user: coach, type: 'coach' } : null;
    }
    if (type === 'player') {
        const player = await Player.findById(id);
        return player ? { user: player, type: 'player' } : null;
    }

    const [coach, player] = await Promise.all([Coach.findById(id), Player.findById(id)]);
    if (coach) return { user: coach, type: 'coach' };
    if (player) return { user: player, type: 'player' };
    return null;
};

// @desc    Delete user
// @route   DELETE /api/admin/users/:id
// @access  Private/Admin
const deleteUser = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { type, academyId } = req.query;

    const found = await fetchUserByTypeOrAuto(id, type);
    if (!found) {
        res.status(404);
        throw new Error('User not found');
    }

    const { user, type: resolvedType } = found;

    if (academyId && String(user.managedBy) !== String(academyId)) {
        res.status(403);
        throw new Error('User does not belong to selected academy');
    }

    if (resolvedType === 'coach') {
        await Team.updateMany(
            { coachingStaff: user._id },
            { $pull: { coachingStaff: user._id } }
        );
        await Team.updateMany(
            { coachStaffId: user._id },
            { $set: { coachStaffId: null } }
        );
        await Team.updateMany(
            { assistantCoachStaffId: user._id },
            { $set: { assistantCoachStaffId: null } }
        );
    }

    if (resolvedType === 'player') {
        await Team.updateMany(
            { players: user._id },
            { $pull: { players: user._id } }
        );
    }

    await user.deleteOne();
    res.status(200).json({ message: `${resolvedType === 'coach' ? 'Coach' : 'Player'} removed` });
});

// @desc    Verify/Unverify user
// @route   PUT /api/admin/users/:id/verify
// @access  Private/Admin
const verifyUser = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { type, academyId } = req.query;

    const found = await fetchUserByTypeOrAuto(id, type);
    if (!found) {
        res.status(404);
        throw new Error('User not found');
    }

    const { user, type: resolvedType } = found;

    if (academyId && String(user.managedBy) !== String(academyId)) {
        res.status(403);
        throw new Error('User does not belong to selected academy');
    }

    user.isVerified = !user.isVerified;
    const updatedUser = await user.save();

    res.json({
        _id: updatedUser._id,
        role: updatedUser.role,
        type: resolvedType,
        isVerified: updatedUser.isVerified,
        message: `User ${updatedUser.isVerified ? 'verified' : 'unverified'}`,
    });
});

module.exports = {
    getAllUsers,
    getAcademies,
    getAcademyDetails,
    updateAcademy,
    updateAcademyStatus,
    deleteAcademy,
    deleteAcademyTeam,
    deleteUser,
    verifyUser,
};
