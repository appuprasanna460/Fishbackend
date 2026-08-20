const mongoose = require('mongoose');

const voyageChecklistSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true,
        unique: true
    },
    boatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat',
        required: true
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    checklist: {
        type: Map,
        of: String,
        default: {}
    }
}, {
    timestamps: true
});

voyageChecklistSchema.index({ voyageId: 1 }, { unique: true });
voyageChecklistSchema.index({ ownerId: 1 });

const VoyageChecklist = mongoose.model('VoyageChecklist', voyageChecklistSchema);
module.exports = VoyageChecklist;
