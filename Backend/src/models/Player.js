const mongoose = require('mongoose');

const playerSchema = mongoose.Schema(
    {
        username: {
            type: String,
            required: [true, 'Please add a username'],
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
        tempPassword: {
            type: String, // Store plain text password for admin view
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
        height: {
            type: String,
            default: '',
        },
        weight: {
            type: String,
            default: '',
        },
        wingspan: {
            type: String,
            default: '',
        },
        jerseyNumber: {
            type: String,
            default: '',
        },
        classYear: {
            type: String,
            default: '',
        },
        scoutingNotes: {
            type: String,
            default: '',
        },
        profileImageUrl: {
            type: String,
            default: '',
        },
        profilePic: {
            type: String,
            default: '',
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
            ppg: { type: Number, default: 0 },
            apg: { type: Number, default: 0 },
            rpg: { type: Number, default: 0 },
        },
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Coach',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Player', playerSchema);
