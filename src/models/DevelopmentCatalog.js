const mongoose = require('mongoose');

const developmentCatalogSchema = mongoose.Schema(
    {
        managedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true, unique: true },
        focusAreas: { type: [String], default: [] },
        drillTemplates: { type: [String], default: [] },
        formationEngagementPct: { type: Number },
        drillCompletionPct: { type: Number },
    },
    { timestamps: true }
);

module.exports = mongoose.model('DevelopmentCatalog', developmentCatalogSchema);
