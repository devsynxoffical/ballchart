const Admin = require('../models/Admin');
const Coach = require('../models/Coach');
const Player = require('../models/Player');

async function findUserById(id) {
    if (!id) return null;
    const admin = await Admin.findById(id).select('-password');
    if (admin) return admin;
    const coach = await Coach.findById(id).select('-password');
    if (coach) return coach;
    const player = await Player.findById(id).select('-password');
    if (player) return player;
    return null;
}

function academyScopeId(user) {
    if (!user) return null;
    if (user.role === 'admin') return user._id;
    return user.managedBy || user._id;
}

function isStaff(user) {
    if (!user) return false;
    return user.role === 'admin' || ['coach', 'head_coach', 'assistant_coach'].includes(user.role);
}

function participantDto(user) {
    if (!user) return null;
    return {
        _id: user._id,
        id: user._id,
        username: user.username,
        role: user.role,
        email: user.email,
        avatarUrl: user.profilePic || user.profileImageUrl || user.logoUrl || null,
    };
}

module.exports = { findUserById, academyScopeId, isStaff, participantDto };
