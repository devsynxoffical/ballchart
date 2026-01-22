const asyncHandler = require('express-async-handler');
const Coach = require('../models/Coach');
const Player = require('../models/Player');
// Note: Coaches and Players are stored in separate collections.

// @desc    Get all users (coaches and players)
// @route   GET /api/admin/users
// @access  Private/Admin
const getAllUsers = asyncHandler(async (req, res) => {
    const coaches = await Coach.find({}).select('-password');
    const players = await Player.find({}).select('-password');

    // Combine and format
    const allUsers = [
        ...coaches.map(c => ({ ...c._doc, type: 'coach' })),
        ...players.map(p => ({ ...p._doc, type: 'player' }))
    ];

    res.json(allUsers);
});

// @desc    Delete user
// @route   DELETE /api/admin/users/:id
// @access  Private/Admin
const deleteUser = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { type } = req.query; // Expecting ?type=coach or ?type=player

    if (type === 'coach') {
        const coach = await Coach.findById(id);
        if (coach) {
            await coach.deleteOne();
            res.json({ message: 'Coach removed' });
        } else {
            res.status(404);
            throw new Error('Coach not found');
        }
    } else if (type === 'player') {
        const player = await Player.findById(id);
        if (player) {
            await player.deleteOne();
            res.json({ message: 'Player removed' });
        } else {
            res.status(404);
            throw new Error('Player not found');
        }
    } else {
        res.status(400);
        throw new Error('Invalid user type');
    }
});


// @desc    Verify/Unverify user
// @route   PUT /api/admin/users/:id/verify
// @access  Private/Admin
const verifyUser = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { type } = req.query; // ?type=coach or ?type=player

    let user;
    if (type === 'coach') {
        user = await Coach.findById(id);
    } else if (type === 'player') {
        user = await Player.findById(id);
    } else {
        res.status(400);
        throw new Error('Invalid user type');
    }

    if (user) {
        user.isVerified = !user.isVerified;
        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            isVerified: updatedUser.isVerified,
            message: `User ${updatedUser.isVerified ? 'verified' : 'unverified'}`,
        });
    } else {
        res.status(404);
        throw new Error('User not found');
    }
});

module.exports = {
    getAllUsers,
    deleteUser,
    verifyUser,
};
