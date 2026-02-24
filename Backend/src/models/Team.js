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
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Team', teamSchema);
