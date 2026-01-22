const mongoose = require('mongoose');

const adminSchema = mongoose.Schema(
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
            default: 'admin',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Admin', adminSchema);
