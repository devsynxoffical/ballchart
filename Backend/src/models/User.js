const mongoose = require('mongoose');

const userSchema = mongoose.Schema(
    {
        username: {
            type: String,
            required: [true, 'Please add a username'],
            unique: true,
        },
        email: {
            type: String,
            required: [true, 'Please add an email'],
            unique: true,
        },
        password: {
            type: String,
            required: [true, 'Please add a password'],
        },
        role: {
            type: String,
            enum: ['player', 'coach', 'head_coach', 'assistant_coach', 'fan'],
            default: 'player',
        },
        teamName: {
            type: String,
        },
        rank: {
            type: Number,
            default: 0,
        },
        stats: {
            matchesPlayed: { type: Number, default: 0 },
            wins: { type: Number, default: 0 },
            points: { type: Number, default: 0 },
        },
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('User', userSchema);
