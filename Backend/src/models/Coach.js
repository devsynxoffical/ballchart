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
        assignedTeams: {
            type: [String], // Array of team names or IDs
            default: [],
        },
        assignedTeamIds: {
            type: [String],
            default: [],
        },
        customRoleName: {
            type: String,
        },
        permissions: {
            createPlayer: { type: Boolean, default: false },
            readPlayer: { type: Boolean, default: true },
            updatePlayer: { type: Boolean, default: false },
            deletePlayer: { type: Boolean, default: false },
            createTeam: { type: Boolean, default: false },
            manageStaff: { type: Boolean, default: false },
        },
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Admin',
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
