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
        academyName: {
            type: String,
            required: [true, 'Please add academy name'],
        },
        logoUrl: {
            type: String,
        },
        profileCompleted: {
            type: Boolean,
            default: true,
        },
        approvalStatus: {
            type: String,
            enum: ['pending', 'approved', 'rejected'],
            default: 'approved',
        },
        isTempBanned: {
            type: Boolean,
            default: false,
        },
        isStopped: {
            type: Boolean,
            default: false,
        },
        approvedAt: {
            type: Date,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Admin', adminSchema);
