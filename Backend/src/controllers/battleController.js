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
        metadata: battle.metadata || {},
        battleType: battle.battleType || 'scrimmage_5v5',
        maxParticipants: battle.maxParticipants || 10,
        description: battle.description || '',
        tags: battle.tags || [],
        viewCount: battle.viewCount || 0,
    };
};

// @desc    Create a new battle
// @route   POST /api/battles
// @access  Private
const createBattle = asyncHandler(async (req, res) => {
    const { location, dateTime, battleType, maxParticipants, description, tags, metadata } = req.body;

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
        participants: [req.user.id],
        battleType: battleType || 'scrimmage_5v5',
        maxParticipants: maxParticipants || 10,
        description: description?.trim() || '',
        tags: Array.isArray(tags) ? tags : [],
        metadata: metadata && typeof metadata === 'object' ? metadata : {},
    });

    req.io.emit('BATTLE_CREATED', { academyId: academyScopeId, battleId: battle._id });

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

    req.io.emit('BATTLE_JOINED', { battleId: battle._id, userId: req.user.id });

    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

// @desc    Append execution / analytics event (Phase 3)
// @route   POST /api/battles/:id/events
// @access  Private
const appendBattleEvent = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId || toIdString(battle.managedBy) !== toIdString(academyScopeId)) {
        res.status(403);
        throw new Error('Not authorized');
    }

    const { type, payload } = req.body;
    if (!type) {
        res.status(400);
        throw new Error('Event type is required');
    }

    const meta = battle.metadata && typeof battle.metadata === 'object' ? battle.metadata : {};
    const events = Array.isArray(meta.events) ? meta.events : [];
    events.push({
        id: `evt_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
        at: new Date().toISOString(),
        type: String(type),
        payload: payload && typeof payload === 'object' ? payload : {},
    });
    meta.events = events;
    battle.metadata = meta;
    await battle.save();

    req.io.emit('BATTLE_EVENT', { battleId: battle._id, type, academyId: academyScopeId });

    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

// @desc    Update a scheduled battle
// @route   PUT /api/battles/:id
// @access  Private (staff)
const updateBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }

    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can update battles');
    }

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId || toIdString(battle.managedBy) !== toIdString(academyScopeId)) {
        res.status(403);
        throw new Error('Not authorized');
    }

    if (battle.status !== 'pending') {
        res.status(400);
        throw new Error('Only scheduled games can be edited');
    }

    const { location, dateTime, battleType, maxParticipants, description, tags, metadata, status } = req.body;

    if (location != null) battle.location = String(location).trim();
    if (dateTime != null) {
        const parsedDate = new Date(dateTime);
        if (Number.isNaN(parsedDate.getTime())) {
            res.status(400);
            throw new Error('Invalid battle date/time');
        }
        battle.dateTime = parsedDate;
    }
    if (battleType != null) battle.battleType = String(battleType);
    if (maxParticipants != null) battle.maxParticipants = maxParticipants;
    if (description != null) battle.description = String(description);
    if (tags != null) battle.tags = Array.isArray(tags) ? tags : [];
    if (metadata != null && typeof metadata === 'object') {
        battle.metadata = { ...(battle.metadata || {}), ...metadata };
    }
    if (status != null && ['pending', 'ongoing', 'finished', 'cancelled'].includes(status)) {
        battle.status = status;
    }

    await battle.save();
    req.io.emit('BATTLE_UPDATED', { academyId: academyScopeId, battleId: battle._id });

    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

async function loadScopedBattles(req) {
    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId) return { academyScopeId, battles: [] };
    const battles = await Battle.find({ managedBy: academyScopeId }).sort({ dateTime: 1, createdAt: -1 });
    return { academyScopeId, battles };
}

async function respondBattles(req, res, battles) {
    const allUserIds = [];
    battles.forEach((battle) => {
        allUserIds.push(battle.host);
        (battle.participants || []).forEach((participant) => allUserIds.push(participant));
    });
    const usersMap = await resolveUsersByIds(allUserIds);
    const currentUserId = toIdString(req.user._id);
    res.status(200).json(battles.map((battle) => serializeBattle(battle, usersMap, currentUserId)));
}

const getMyBattles = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    const uid = toIdString(req.user._id);
    const mine = battles.filter((b) => toIdString(b.host) === uid || (b.participants || []).some((p) => toIdString(p) === uid));
    await respondBattles(req, res, mine);
});

const getUpcomingBattles = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    const now = Date.now();
    const list = battles.filter((b) => b.status === 'pending' && new Date(b.dateTime).getTime() > now);
    await respondBattles(req, res, list);
});

const getOngoingBattles = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    await respondBattles(req, res, battles.filter((b) => b.status === 'ongoing'));
});

const getFinishedBattles = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    const now = Date.now();
    const list = battles.filter((b) => b.status === 'finished' || b.status === 'cancelled' || (b.status === 'pending' && new Date(b.dateTime).getTime() <= now));
    await respondBattles(req, res, list);
});

const getBattleStats = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    res.status(200).json({
        total: battles.length,
        pending: battles.filter((b) => b.status === 'pending').length,
        ongoing: battles.filter((b) => b.status === 'ongoing').length,
        finished: battles.filter((b) => b.status === 'finished').length,
    });
});

const getBattleLocations = asyncHandler(async (req, res) => {
    const { battles } = await loadScopedBattles(req);
    const locs = [...new Set(battles.map((b) => (b.location || '').trim()).filter(Boolean))];
    res.status(200).json(locs);
});

const leaveBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    battle.participants = (battle.participants || []).filter((p) => toIdString(p) !== toIdString(req.user._id));
    await battle.save();
    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

const startBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    battle.status = 'ongoing';
    await battle.save();
    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

const finishBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    battle.status = 'finished';
    if (req.body?.result) battle.result = String(req.body.result);
    await battle.save();
    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

const cancelBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    battle.status = 'cancelled';
    await battle.save();
    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

const deleteBattle = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can delete battles');
    }
    await battle.deleteOne();
    res.status(200).json({ ok: true });
});

const incrementViewCount = asyncHandler(async (req, res) => {
    const battle = await Battle.findById(req.params.id);
    if (!battle) {
        res.status(404);
        throw new Error('Battle not found');
    }
    battle.viewCount = (battle.viewCount || 0) + 1;
    await battle.save();
    const usersMap = await resolveUsersByIds([battle.host, ...(battle.participants || [])]);
    res.status(200).json(serializeBattle(battle, usersMap, toIdString(req.user._id)));
});

module.exports = {
    createBattle,
    getBattles,
    getMyBattles,
    getUpcomingBattles,
    getOngoingBattles,
    getFinishedBattles,
    getBattleStats,
    getBattleLocations,
    joinBattle,
    leaveBattle,
    startBattle,
    finishBattle,
    cancelBattle,
    deleteBattle,
    incrementViewCount,
    appendBattleEvent,
    updateBattle,
};
