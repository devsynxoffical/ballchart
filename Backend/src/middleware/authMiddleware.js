const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');
const User = require('../models/User');
const Coach = require('../models/Coach');
const Player = require('../models/Player');
const Admin = require('../models/Admin');

const protect = asyncHandler(async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Use role encoded in token to fetch from the right collection
            if (decoded.role === 'admin') {
                req.user = await Admin.findById(decoded.id).select('-password');
            } else if (decoded.role === 'coach') {
                req.user = await Coach.findById(decoded.id).select('-password');
            } else if (decoded.role === 'player') {
                req.user = await Player.findById(decoded.id).select('-password');
            }

            if (!req.user) {
                res.status(401);
                throw new Error('Not authorized');
            }

            next();
        } catch (error) {
            console.log(error);
            res.status(401);
            throw new Error('Not authorized');
        }
    }

    if (!token) {
        res.status(401);
        throw new Error('Not authorized, no token');
    }
});

module.exports = { protect };
