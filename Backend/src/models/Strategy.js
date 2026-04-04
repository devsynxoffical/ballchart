const mongoose = require('mongoose');

const strategySchema = mongoose.Schema(
    {
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Admin',
            required: true,
        },
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
        },
        createdByRole: {
            type: String,
            enum: ['admin', 'head_coach', 'coach', 'assistant_coach'],
            required: true,
        },
        title: {
            type: String,
            required: [true, 'Please add a strategy title'],
            trim: true,
        },
        category: {
            type: String,
            enum: ['offense', 'defense', 'drills', 'general'],
            default: 'general',
        },
        sourceType: {
            type: String,
            enum: ['text', 'voice'],
            default: 'text',
        },
        sourceText: {
            type: String,
            default: '',
            trim: true,
        },
        videoUrl: {
            type: String,
            required: [true, 'Please add a strategy video URL'],
            trim: true,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Strategy', strategySchema);
