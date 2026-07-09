const mongoose = require('mongoose');

const trainingAssignmentSchema = mongoose.Schema(
    {
        playerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true, index: true },
        managedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
        focusArea: { type: String, required: true },
        drillName: { type: String, required: true },
        sessionIntent: { type: String, default: 'training' },
        status: { type: String, enum: ['pending', 'completed'], default: 'pending' },
        pointsValue: { type: Number, default: 10 },
        dueAt: { type: Date },
        notes: { type: String, default: '' },
        playerNotes: { type: String, default: '' },
        completedAt: { type: Date },
        assignedBy: { type: mongoose.Schema.Types.ObjectId },
    },
    { timestamps: true }
);

module.exports = mongoose.model('TrainingAssignment', trainingAssignmentSchema);
