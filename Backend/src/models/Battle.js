const mongoose = require('mongoose');

const battleSchema = mongoose.Schema(
    {
        host: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
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
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Battle', battleSchema);
