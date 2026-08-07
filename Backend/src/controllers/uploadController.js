const path = require('path');
const multer = require('multer');
const asyncHandler = require('express-async-handler');
const Media = require('../models/Media');

// Keep files in memory so we can persist them in MongoDB (survives Railway redeploys).
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 12 * 1024 * 1024 },
});

// iOS AVPlayer refuses extension-less URLs, so media URLs carry a hint
// derived from the uploaded content type. The route accepts an optional
// trailing extension so existing extension-less URLs keep working.
const EXT_BY_MIME = {
    'audio/mp4': '.m4a',
    'audio/m4a': '.m4a',
    'audio/x-m4a': '.m4a',
    'audio/aac': '.m4a',
    'audio/mpeg': '.mp3',
    'audio/mp3': '.mp3',
    'audio/wav': '.wav',
    'audio/x-wav': '.wav',
    'audio/wave': '.wav',
    'audio/ogg': '.ogg',
    'application/pdf': '.pdf',
    'video/mp4': '.mp4',
    'video/quicktime': '.mov',
    'video/webm': '.webm',
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/heic': '.heic',
    'image/heif': '.heic',
    'image/bmp': '.bmp',
};

function extensionForContentType(contentType) {
    const base = (contentType || '').split(';')[0].trim().toLowerCase();
    if (EXT_BY_MIME[base]) return EXT_BY_MIME[base];
    if (base.startsWith('image/')) return '.img';
    if (base.startsWith('audio/')) return '.m4a';
    return '';
}

async function persistUpload(req, res, file) {
    const contentType = file.mimetype || 'application/octet-stream';
    const filename = file.originalname || `upload-${Date.now()}${path.extname(file.originalname || '')}`;
    const doc = await Media.create({
        contentType,
        filename,
        data: file.buffer,
        uploadedBy: req.user?._id || null,
    });
    const ext = extensionForContentType(contentType);
    const url = `/uploads/media/${doc._id}${ext}`;
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

/** Public GET — Image.network / audio players do not send auth headers.
 *  Supports optional trailing `.ext` (for AVPlayer) and HTTP Range so iOS
 *  streaming audio sources load reliably. */
const serveMedia = asyncHandler(async (req, res) => {
    const doc = await Media.findById(req.params.id).select('data contentType filename');
    if (!doc || !doc.data) {
        res.status(404);
        throw new Error('Media not found');
    }
    const buffer = doc.data;
    const contentType = doc.contentType || 'application/octet-stream';

    res.set('Content-Type', contentType);
    res.set('Accept-Ranges', 'bytes');
    res.set('Cache-Control', 'public, max-age=31536000, immutable');
    if (doc.filename) {
        res.set('Content-Disposition', `inline; filename="${doc.filename.replace(/"/g, '')}"`);
    }

    const range = req.headers.range;
    if (range) {
        const match = /bytes=(\d*)-(\d*)/.exec(String(range));
        let start = match && match[1] !== '' ? parseInt(match[1], 10) : NaN;
        let end = match && match[2] !== '' ? parseInt(match[2], 10) : NaN;
        const total = buffer.length;
        if (match && Number.isNaN(start)) {
            // Suffix range (last N bytes): bytes=-500
            if (Number.isNaN(end) || end <= 0) {
                res.set('Content-Range', `bytes */${total}`);
                return res.status(416).end();
            }
            start = Math.max(0, total - end);
            end = total - 1;
        } else {
            if (Number.isNaN(start) || start < 0 || start >= total) {
                res.set('Content-Range', `bytes */${total}`);
                return res.status(416).end();
            }
            if (Number.isNaN(end) || end >= total) end = total - 1;
        }
        if (start > end) {
            res.set('Content-Range', `bytes */${total}`);
            return res.status(416).end();
        }
        res.status(206);
        res.set('Content-Range', `bytes ${start}-${end}/${total}`);
        res.set('Content-Length', String(end - start + 1));
        return res.send(buffer.subarray(start, end + 1));
    }

    res.set('Content-Length', String(buffer.length));
    res.send(buffer);
});

module.exports = { uploadImage, uploadAudio, uploadFile, serveMedia };
