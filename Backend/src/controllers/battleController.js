const asyncHandler = require('express-async-handler');
const Battle = require('../models/Battle');
const Admin = require('../models/Admin');
const Coach = require('../models/Coach');
const Player = require('../models/Player');

const createAllowedRoles = ['admin', 'head_coach', 'coach', 'assistant_coach'];

const toIdString = (value) => (value ? value.toString() : '');

const getAcademyScopeId = (user) => {
    if (!user) return null;
    if (user.role === 'admin') return user._id;
    if (['coach', 'assistant_coach', 'head_coach'].includes(user.role)) {
        return user.managedBy || null;
    }
    if (user.role === 'player') {
        return user.managedBy || null;
    }
    return null;
};

const resolveAcademyScopeId = async (user) => {
    const scopeId = getAcademyScopeId(user);
    if (!scopeId) return null;

    if (user.role !== 'player') return scopeId;

    const admin = await Admin.findById(scopeId).select('_id');
    if (admin) return admin._id;

    const coach = await Coach.findById(scopeId).select('managedBy');
    if (coach?.managedBy) return coach.managedBy;

    return scopeId;
};

const resolveUsersByIds = async (ids) => {
    const uniqueIds = [...new Set((ids || []).map((id) => id.toString()))];
    if (!uniqueIds.length) return new Map();

    const [admins, coaches, players] = await Promise.all([
        Admin.find({ _id: { $in: uniqueIds } }).select('_id username role'),
        Coach.find({ _id: { $in: uniqueIds } }).select('_id username role'),
        Player.find({ _id: { $in: uniqueIds } }).select('_id username role'),
    ]);

    const map = new Map();
    [...admins, ...coaches, ...players].forEach((doc) => {
        map.set(doc._id.toString(), {
            _id: doc._id,
            username: doc.username,
            role: doc.role,
        });
    });
    return map;
};

const serializeBattle = (battle, usersMap, currentUserId) => {
    const hostId = toIdString(battle.host);
    const participantIds = (battle.participants || []).map((id) => toIdString(id));
    const isJoined = participantIds.includes(currentUserId);

    return {
        _id: battle._id,
        location: battle.location,
        dateTime: battle.dateTime,
        status: battle.status,
        result: battle.result || null,
        createdAt: battle.createdAt,
        updatedAt: battle.updatedAt,
        host: usersMap.get(hostId) || { _id: battle.host, username: 'Unknown', role: 'unknown' },
        participants: participantIds.map((id) => usersMap.get(id) || { _id: id, username: 'Unknown', role: 'unknown' }),
        participantCount: participantIds.length,
        isJoined,
        canJoin: battle.status === 'pending' && !isJoined,
    };
};

// @desc    Create a new battle
// @route   POST /api/battles
// @access  Private
const createBattle = asyncHandler(async (req, res) => {
    const { location, dateTime } = req.body;

    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can create battles');
    }

    if (!location || !dateTime) {
        res.status(400);
        throw new Error('Please add all fields');
    }

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId) {
        res.status(400);
        throw new Error('Academy scope not found for this user');
    }

    const parsedDate = new Date(dateTime);
    if (Number.isNaN(parsedDate.getTime())) {
        res.status(400);
        throw new Error('Invalid battle date/time');
    }
    if (parsedDate.getTime() <= Date.now()) {
        res.status(400);
        throw new Error('Battle time must be in the future');
    }

    const battle = await Battle.create({
        host: req.user._id,
        location: location.trim(),
        dateTime: parsedDate,
        managedBy: academyScopeId,
        createdByRole: req.user.role,
        participants: [req.user.id], // Host is automatically a participant
    });

    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(201).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

// @desc    Get all battles
// @route   GET /api/battles
// @access  Private
const getBattles = asyncHandler(async (req, res) => {
    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId) {
        res.status(200).json([]);
        return;
    }

    const battles = await Battle.find({ managedBy: academyScopeId }).sort({ dateTime: 1, createdAt: -1 });

    const allUserIds = [];
    battles.forEach((battle) => {
        allUserIds.push(battle.host);
        (battle.participants || []).forEach((participant) => allUserIds.push(participant));
    });

    const usersMap = await resolveUsersByIds(allUserIds);
    const currentUserId = toIdString(req.user._id);
    const payload = battles.map((battle) => serializeBattle(battle, usersMap, currentUserId));
    res.status(200).json(payload);
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

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId || toIdString(battle.managedBy) !== toIdString(academyScopeId)) {
        res.status(403);
        throw new Error('You can only join battles from your academy');
    }

    if (battle.status !== 'pending') {
        res.status(400);
        throw new Error('Battle is already started or finished');
    }

    // Check if user already joined
    if ((battle.participants || []).some((participantId) => toIdString(participantId) === toIdString(req.user._id))) {
        res.status(400);
        throw new Error('You have already joined this battle');
    }

    battle.participants.push(req.user.id);
    await battle.save();

    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

module.exports = {
    createBattle,
    getBattles,
    joinBattle,
};
