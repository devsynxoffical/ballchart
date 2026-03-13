const asyncHandler = require('express-async-handler');
const Strategy = require('../models/Strategy');
const Admin = require('../models/Admin');
const Coach = require('../models/Coach');

const createAllowedRoles = ['admin', 'head_coach', 'coach', 'assistant_coach'];

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
        return Admin.findById(createdBy).select('_id username role');
    }
    return Coach.findById(createdBy).select('_id username role');
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

// @desc    Create strategy with video URL
// @route   POST /api/strategies
// @access  Private (academy staff)
const createStrategy = asyncHandler(async (req, res) => {
    if (!createAllowedRoles.includes(req.user.role)) {
        res.status(403);
        throw new Error('Only academy staff can create strategies');
    }

    const { title, category, sourceType, sourceText, videoUrl } = req.body;
    if (!title || !videoUrl) {
        res.status(400);
        throw new Error('Title and video URL are required');
    }
    if (!isValidHttpUrl(videoUrl)) {
        res.status(400);
        throw new Error('Please provide a valid video URL (http/https)');
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
        videoUrl: videoUrl.trim(),
    });

    const creator = await resolveCreator(strategy.createdBy, strategy.createdByRole);
    res.status(201).json({
        _id: strategy._id,
        title: strategy.title,
        category: strategy.category,
        sourceType: strategy.sourceType,
        sourceText: strategy.sourceText,
        videoUrl: strategy.videoUrl,
        createdAt: strategy.createdAt,
        createdBy: creator
            ? {
                _id: creator._id,
                username: creator.username,
                role: creator.role,
            }
            : null,
    });
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
        Admin.find({ _id: { $in: creatorIdsByRole.admin } }).select('_id username role').lean(),
        Coach.find({ _id: { $in: creatorIdsByRole.staff } }).select('_id username role').lean(),
    ]);

    const creatorMap = new Map();
    [...admins, ...staffs].forEach((item) => {
        creatorMap.set(toIdString(item._id), item);
    });

    res.status(200).json(
        strategies.map((item) => ({
            _id: item._id,
            title: item.title,
            category: item.category,
            sourceType: item.sourceType,
            sourceText: item.sourceText,
            videoUrl: item.videoUrl,
            createdAt: item.createdAt,
            createdBy:
                creatorMap.get(toIdString(item.createdBy)) || {
                    _id: item.createdBy,
                    username: 'Unknown',
                    role: item.createdByRole,
                },
        }))
    );
});

module.exports = {
    createStrategy,
    getStrategies,
};
