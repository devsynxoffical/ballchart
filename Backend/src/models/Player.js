const mongoose = require('mongoose');

const playerSchema = mongoose.Schema(
    {
        username: {
            type: String,
            required: [true, 'Please add a username'],
            unique: true, // Unique among players
        },
        email: {
            type: String,
            required: [true, 'Please add an email'],
            unique: true, // Unique among players
        },
        password: {
            type: String,
            required: [true, 'Please add a password'],
        },
        role: {
            type: String,
            default: 'player',
        },
        position: {
            type: String,
        },
        ageRange: {
            type: String,
        },
        experienceLevel: {
            type: String,
        },
        goals: {
            type: [String],
            default: [],
        },
        additionalGoals: {
            type: String,
        },
        profileCompleted: {
            type: Boolean,
            default: false,
        },
        isVerified: {
            type: Boolean,
            default: false,
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
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Player', playerSchema);
