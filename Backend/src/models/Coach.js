const mongoose = require('mongoose');

const coachSchema = mongoose.Schema(
    {
        username: {
            type: String,
            required: [true, 'Please add a username'],
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
            default: 'coach',
        },
        // Coach specific fields
        experienceLevel: {
            type: String,
        },
        sports: {
            type: [String],
            default: [],
        },
        achievements: {
            type: [String],
            default: [],
        },
        additionalInfo: {
            type: String,
        },
        teamName: {
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
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Coach', coachSchema);
