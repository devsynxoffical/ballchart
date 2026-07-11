const mongoose = require('mongoose');

const battleSchema = mongoose.Schema(
    {
        host: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
        },
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Admin',
            required: true,
        },
        createdByRole: {
            type: String,
            enum: ['admin', 'head_coach', 'coach', 'assistant_coach'],
            required: true,
        },
        location: {
            type: String,
            required: [true, 'Please add a location'],
        },
        dateTime: {
            type: Date,
            required: [true, 'Please add a date and time'],
        },
        status: {
            type: String,
            enum: ['pending', 'ongoing', 'finished', 'cancelled'],
            default: 'pending',
        },
        participants: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
        ],
        winner: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        result: {
            type: String, // e.g., "15-12"
        },
        metadata: {
            type: mongoose.Schema.Types.Mixed,
            default: {},
        },
        battleType: {
            type: String,
            default: 'scrimmage_5v5',
        },
        maxParticipants: {
            type: Number,
            default: 10,
        },
        description: {
            type: String,
            default: '',
        },
        tags: {
            type: [String],
            default: [],
        },
        viewCount: {
            type: Number,
            default: 0,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Battle', battleSchema);
