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
        // Coach specific fields can go here
        teamName: {
            type: String,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Coach', coachSchema);
