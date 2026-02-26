const mongoose = require('mongoose');

const teamSchema = mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Please add a team name'],
            unique: true,
        },
        headCoach: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User', // Reference to the Head Coach
            required: true,
        },
        coachingStaff: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Coach', // Reference to Coaches or Assistant Coaches
        }],
        players: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Player', // Reference to Players
        }],
        description: {
            type: String,
        },
        ageGroup: {
            type: String,
            default: 'Open',
        },
        colorValue: {
            type: Number,
            default: 0xFFF59E0B,
        },
        logoPath: {
            type: String,
        },
        coachStaffId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Coach',
        },
        assistantCoachStaffId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Coach',
        },
        managedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Admin',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Team', teamSchema);
