const mongoose = require('mongoose');

const conversationSchema = mongoose.Schema(
    {
        participants: [{
            userId: { type: mongoose.Schema.Types.ObjectId, required: true },
            role: { type: String, required: true },
        }],
        kind: { type: String, enum: ['direct', 'team'], default: 'direct' },
        teamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
        teamName: { type: String },
        managedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
        lastMessagePreview: { type: String, default: '' },
        lastMessageAt: { type: Date },
        readBy: [{
            userId: { type: mongoose.Schema.Types.ObjectId, required: true },
            lastReadAt: { type: Date, default: Date.now },
        }],
    },
    { timestamps: true }
);

conversationSchema.index({ managedBy: 1, 'participants.userId': 1 });

module.exports = mongoose.model('Conversation', conversationSchema);
