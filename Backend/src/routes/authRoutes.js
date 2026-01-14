const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe } = require('../controllers/authController');

// TODO: Add protect middleware later for getMe
router.post('/signup', registerUser);
router.post('/login', loginUser);
// router.get('/me', protect, getMe);

module.exports = router;
