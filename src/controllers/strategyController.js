const asyncHandler = require('express-async-handler');
const Strategy = require('../models/Strategy');
const Admin = require('../models/Admin');
const Coach = require('../models/Coach');

const createAllowedRoles = ['admin', 'head_coach', 'coach', 'assistant_coach', 'custom'];

const hasStaffFlag = (user, key) => {
    if (!user) return false;
    if (['admin', 'head_coach'].includes(user.role)) return true;
    if (!createAllowedRoles.includes(user.role)) return false;
    return !!(user.permissions && user.permissions[key] === true);
};

const toIdString = (value) => (value ? value.toString() : '');

const getAcademyScopeId = (user) => {
    if (!user) return null;
    if (user.role === 'admin') return user._id;
    if (['coach', 'assistant_coach', 'head_coach', 'player'].includes(user.role)) {
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

const resolveCreator = async (createdBy, role) => {
    if (role === 'admin') {
        return Admin.findById(createdBy).select('_id username role logoUrl');
    }
    return Coach.findById(createdBy).select('_id username role profilePic profileImageUrl');
};

const creatorAvatar = (creator) => {
    if (!creator) return null;
    return creator.profilePic || creator.profileImageUrl || creator.logoUrl || null;
};

const isValidHttpUrl = (value) => {
    if (!value || typeof value !== 'string') return false;
    try {
        const parsed = new URL(value);
        return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    } catch (error) {
        return false;
    }
};

const youtubeIdFromUrl = (rawUrl) => {
    const raw = (rawUrl || '').toString().trim();
    if (!raw) return null;
    let parsed;
    try {
        parsed = new URL(raw);
    } catch (_) {
        return null;
    }
    const host = (parsed.hostname || '').toLowerCase();
    if (host.includes('youtu.be')) {
        const id = (parsed.pathname || '').split('/').filter(Boolean)[0];
        return id || null;
    }
    if (host.includes('youtube.com') || host.includes('youtube-nocookie.com')) {
        const v = parsed.searchParams.get('v');
        if (v && v.trim()) return v.trim();
        const parts = (parsed.pathname || '').split('/').filter(Boolean);
        for (let i = 0; i < parts.length - 1; i += 1) {
            const s = parts[i].toLowerCase();
            if (s === 'embed' || s === 'shorts' || s === 'live' || s === 'v') {
                return parts[i + 1] || null;
            }
        }
    }
    return null;
};

const thumbnailFromVideoUrl = (videoUrl, explicit) => {
    const explicitTrim = (explicit || '').toString().trim();
    if (explicitTrim && isValidHttpUrl(explicitTrim)) return explicitTrim;
    const id = youtubeIdFromUrl(videoUrl);
    return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : '';
};

const serializeStrategy = (item, creator) => ({
    _id: item._id,
    title: item.title,
    category: item.category,
    sourceType: item.sourceType,
    sourceText: item.sourceText,
    videoUrl: item.videoUrl || '',
    thumbnailUrl:
        (item.thumbnailUrl || '').toString().trim() ||
        thumbnailFromVideoUrl(item.videoUrl || '', ''),
    metadata: item.metadata || {},
    tags: item.tags || [],
    revisionState: item.revisionState || 'draft',
    createdAt: item.createdAt,
    createdBy: creator
        ? {
            _id: creator._id,
            username: creator.username,
            role: creator.role,
            profilePic: creator.profilePic || null,
            profileImageUrl: creator.profileImageUrl || creator.logoUrl || null,
            avatarUrl: creatorAvatar(creator),
        }
        : null,
});

// @desc    Create strategy with video URL
// @route   POST /api/strategies
// @access  Private (academy staff)
const createStrategy = asyncHandler(async (req, res) => {
    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can create strategies');
    }
    if (!hasStaffFlag(req.user, 'createStrategy')) {
        res.status(403);
        throw new Error('You do not have permission to create strategies');
    }

    const { title, category, sourceType, sourceText, videoUrl, thumbnailUrl, metadata, tags, revisionState } = req.body;
    if (!title) {
        res.status(400);
        throw new Error('Title is required');
    }
    const v = (videoUrl || '').toString().trim();
    if (v && !isValidHttpUrl(v)) {
        res.status(400);
        throw new Error('Please provide a valid video URL (http/https)');
    }
    const thumb = thumbnailFromVideoUrl(v, thumbnailUrl);
    if (thumb && !isValidHttpUrl(thumb)) {
        res.status(400);
        throw new Error('Please provide a valid thumbnail URL (http/https)');
    }

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId) {
        res.status(400);
        throw new Error('Academy scope not found for this user');
    }

    const strategy = await Strategy.create({
        managedBy: academyScopeId,
        createdBy: req.user._id,
        createdByRole: req.user.role,
        title: title.trim(),
        category: ['offense', 'defense', 'drills', 'general'].includes(category)
            ? category
            : 'general',
        sourceType: sourceType === 'voice' ? 'voice' : 'text',
        sourceText: (sourceText || '').toString().trim(),
        videoUrl: v,
        thumbnailUrl: thumb,
        metadata: metadata && typeof metadata === 'object' ? metadata : {},
        tags: Array.isArray(tags) ? tags.map((t) => String(t)) : [],
        revisionState: ['draft', 'published', 'archived'].includes(revisionState) ? revisionState : 'draft',
    });

    const creator = await resolveCreator(strategy.createdBy, strategy.createdByRole);
    res.status(201).json(serializeStrategy(strategy, creator));
});

// @desc    Get live strategy feed for academy
// @route   GET /api/strategies
// @access  Private
const getStrategies = asyncHandler(async (req, res) => {
    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId) {
        res.status(200).json([]);
        return;
    }

    const strategies = await Strategy.find({ managedBy: academyScopeId }).sort({ createdAt: -1 }).lean();
    const creatorIdsByRole = {
        admin: [],
        staff: [],
    };

    strategies.forEach((item) => {
        if (item.createdByRole === 'admin') {
            creatorIdsByRole.admin.push(item.createdBy);
        } else {
            creatorIdsByRole.staff.push(item.createdBy);
        }
    });

    const [admins, staffs] = await Promise.all([
        Admin.find({ _id: { $in: creatorIdsByRole.admin } }).select('_id username role logoUrl').lean(),
        Coach.find({ _id: { $in: creatorIdsByRole.staff } }).select('_id username role profilePic profileImageUrl').lean(),
    ]);

    const creatorMap = new Map();
    [...admins, ...staffs].forEach((item) => {
        creatorMap.set(toIdString(item._id), item);
    });

    res.status(200).json(
        strategies.map((item) =>
            serializeStrategy(item, creatorMap.get(toIdString(item.createdBy)) || {
                _id: item.createdBy,
                username: 'Unknown',
                role: item.createdByRole,
            })
        )
    );
});

// @desc    Update strategy tactical payload / metadata
// @route   PUT /api/strategies/:id
// @access  Private (academy staff)
const updateStrategy = asyncHandler(async (req, res) => {
    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can update strategies');
    }
    if (!hasStaffFlag(req.user, 'manageStrategy') && !hasStaffFlag(req.user, 'createStrategy')) {
        res.status(403);
        throw new Error('You do not have permission to manage strategies');
    }

    const strategy = await Strategy.findById(req.params.id);
    if (!strategy) {
        res.status(404);
        throw new Error('Strategy not found');
    }

    const academyScopeId = await resolveAcademyScopeId(req.user);
    if (!academyScopeId || toIdString(strategy.managedBy) !== toIdString(academyScopeId)) {
        res.status(403);
        throw new Error('Not authorized to update this strategy');
    }

    const { title, category, sourceText, videoUrl, thumbnailUrl, metadata, tags, revisionState, sourceType } = req.body;
    if (title) strategy.title = title.toString().trim();
    if (category && ['offense', 'defense', 'drills', 'general'].includes(category)) strategy.category = category;
    if (sourceText !== undefined) strategy.sourceText = (sourceText || '').toString().trim();
    if (sourceType === 'voice' || sourceType === 'text') strategy.sourceType = sourceType;
    if (videoUrl !== undefined) {
        const v = (videoUrl || '').toString().trim();
        if (v && !isValidHttpUrl(v)) {
            res.status(400);
            throw new Error('Invalid video URL');
        }
        strategy.videoUrl = v;
        strategy.thumbnailUrl = thumbnailFromVideoUrl(v, thumbnailUrl ?? strategy.thumbnailUrl);
    } else if (thumbnailUrl !== undefined) {
        const t = (thumbnailUrl || '').toString().trim();
        if (t && !isValidHttpUrl(t)) {
            res.status(400);
            throw new Error('Invalid thumbnail URL');
        }
        strategy.thumbnailUrl = t;
    }
    if (metadata && typeof metadata === 'object') {
        strategy.metadata = { ...(strategy.metadata || {}), ...metadata };
    }
    if (Array.isArray(tags)) strategy.tags = tags.map((t) => String(t));
    if (revisionState && ['draft', 'published', 'archived'].includes(revisionState)) {
        strategy.revisionState = revisionState;
    }

    await strategy.save();
    const creator = await resolveCreator(strategy.createdBy, strategy.createdByRole);
    res.status(200).json(serializeStrategy(strategy, creator));
});

module.exports = {
    createStrategy,
    getStrategies,
    updateStrategy,
};
