const mongoose = require('mongoose');

const notificationSchema = mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
        title: { type: String, required: true },
        message: { type: String, required: true },
        type: { type: String, default: 'system' },
        isRead: { type: Boolean, default: false },
        relatedUserId: { type: mongoose.Schema.Types.ObjectId },
        relatedTeamId: { type: mongoose.Schema.Types.ObjectId },
        managedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
