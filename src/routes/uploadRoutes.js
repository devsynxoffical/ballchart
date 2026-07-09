const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { uploadImage, uploadAudio, uploadFile } = require('../controllers/uploadController');

router.post('/image', protect, ...uploadImage);
router.post('/audio', protect, ...uploadAudio);
router.post('/file', protect, ...uploadFile);
router.post('/document', protect, ...uploadFile);

module.exports = router;
