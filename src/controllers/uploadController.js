const path = require('path');
const multer = require('multer');
const asyncHandler = require('express-async-handler');
const Media = require('../models/Media');

// Keep files in memory so we can persist them in MongoDB (survives Railway redeploys).
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 12 * 1024 * 1024 },
});

async function persistUpload(req, res, file) {
    const contentType = file.mimetype || 'application/octet-stream';
    const filename = file.originalname || `upload-${Date.now()}${path.extname(file.originalname || '')}`;
    const doc = await Media.create({
        contentType,
        filename,
        data: file.buffer,
        uploadedBy: req.user?._id || null,
    });
    const url = `/uploads/media/${doc._id}`;
    res.status(201).json({ url, fileUrl: url, path: url, id: doc._id });
}

const uploadImage = [
    upload.single('image'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No image file provided');
        }
        await persistUpload(req, res, req.file);
    }),
];

const uploadAudio = [
    upload.single('audio'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No audio file provided');
        }
        await persistUpload(req, res, req.file);
    }),
];

const uploadFile = [
    upload.single('file'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No file provided');
        }
        await persistUpload(req, res, req.file);
    }),
];

/** Public GET — Image.network / audio players do not send auth headers. */
const serveMedia = asyncHandler(async (req, res) => {
    const doc = await Media.findById(req.params.id).select('data contentType filename');
    if (!doc || !doc.data) {
        res.status(404);
        throw new Error('Media not found');
    }
    res.set('Content-Type', doc.contentType || 'application/octet-stream');
    res.set('Cache-Control', 'public, max-age=31536000, immutable');
    if (doc.filename) {
        res.set('Content-Disposition', `inline; filename="${doc.filename.replace(/"/g, '')}"`);
    }
    res.send(doc.data);
});

module.exports = { uploadImage, uploadAudio, uploadFile, serveMedia };
