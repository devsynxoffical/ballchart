const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');
const User = require('../models/User');

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

            // Try finding in Coach, then in Player
            // Note: In a real app we might encode the role in the token to know which DB to query directly.
            // which we did in generateToken(id, role).

            if (decoded.role === 'coach') {
                req.user = await require('../models/Coach').findById(decoded.id).select('-password');
            } else {
                req.user = await require('../models/Player').findById(decoded.id).select('-password');
            }

            // Fallback for old tokens or mismatch
            if (!req.user) {
                // try the other one just in case
                req.user = await require('../models/Player').findById(decoded.id).select('-password');
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
