const path = require('path');
const fs = require('fs');
const multer = require('multer');
const asyncHandler = require('express-async-handler');

const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadsDir),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname || '') || '';
        const safe = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
        cb(null, safe);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 },
});

function respondUpload(res, file) {
    const url = `/uploads/${file.filename}`;
    res.status(201).json({ url, fileUrl: url, path: url });
}

const uploadImage = [
    upload.single('image'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No image file provided');
        }
        respondUpload(res, req.file);
    }),
];

const uploadAudio = [
    upload.single('audio'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No audio file provided');
        }
        respondUpload(res, req.file);
    }),
];

const uploadFile = [
    upload.single('file'),
    asyncHandler(async (req, res) => {
        if (!req.file) {
            res.status(400);
            throw new Error('No file provided');
        }
        respondUpload(res, req.file);
    }),
];

module.exports = { uploadImage, uploadAudio, uploadFile };
