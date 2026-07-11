const asyncHandler = require('express-async-handler');
const Notification = require('../models/Notification');

const listNotifications = asyncHandler(async (req, res) => {
    const items = await Notification.find({ userId: req.user._id })
        .sort({ createdAt: -1 })
        .limit(100);
    res.json(items.map((n) => ({
        _id: n._id,
        id: n._id,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: n.isRead,
        relatedUserId: n.relatedUserId,
        relatedTeamId: n.relatedTeamId,
        createdAt: n.createdAt,
        timestamp: n.createdAt,
    })));
});

const markRead = asyncHandler(async (req, res) => {
    await Notification.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id },
        { isRead: true }
    );
    res.json({ ok: true });
});

const markAllRead = asyncHandler(async (req, res) => {
    await Notification.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
    res.json({ ok: true });
});

module.exports = { listNotifications, markRead, markAllRead };
