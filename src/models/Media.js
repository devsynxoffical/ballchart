const mongoose = require('mongoose');

/**
 * Persistent binary media (Railway disk is ephemeral — local /uploads files vanish on redeploy).
 */
const mediaSchema = mongoose.Schema(
    {
        contentType: {
            type: String,
            required: true,
        },
        filename: {
            type: String,
            default: '',
        },
        data: {
            type: Buffer,
            required: true,
        },
        uploadedBy: {
            type: mongoose.Schema.Types.ObjectId,
            default: null,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Media', mediaSchema);
