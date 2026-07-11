const mongoose = require('mongoose');

const messageSchema = mongoose.Schema(
    {
        conversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', required: true, index: true },
        senderId: { type: mongoose.Schema.Types.ObjectId, required: true },
        body: { type: String, default: '' },
        type: { type: String, enum: ['text', 'voice', 'file'], default: 'text' },
        voiceUrl: { type: String },
        voiceDurationMs: { type: Number, default: 0 },
        fileUrl: { type: String },
        fileName: { type: String },
        mimeType: { type: String },
        replyToMessageId: { type: mongoose.Schema.Types.ObjectId },
        replyBody: { type: String },
        replySenderId: { type: mongoose.Schema.Types.ObjectId },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Message', messageSchema);
