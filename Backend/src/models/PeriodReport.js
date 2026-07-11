const mongoose = require('mongoose');

const areaSchema = mongoose.Schema({
    key: String,
    label: String,
    rating: Number,
    performanceComment: String,
    strengths: String,
    focusArea: String,
}, { _id: false });

const periodReportSchema = mongoose.Schema(
    {
        playerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true, index: true },
        year: { type: Number, required: true },
        month: { type: Number, required: true },
        managedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
        ageCategory: { type: String, default: '' },
        evaluationPeriod: { type: String, default: '' },
        areas: { type: [areaSchema], default: [] },
        summary: { type: String, default: '' },
        goals: { type: [String], default: [] },
        playerGoals: { type: [String], default: [] },
        nextEvaluationDate: { type: String, default: '' },
    },
    { timestamps: true }
);

periodReportSchema.index({ playerId: 1, year: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('PeriodReport', periodReportSchema);
