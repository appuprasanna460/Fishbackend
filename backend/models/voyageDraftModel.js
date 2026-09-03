const mongoose = require('mongoose');

const voyageDraftSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true // One draft per owner
    },
    draftData: {
        type: Object,
        required: true,
        default: {}
    }
}, {
    timestamps: true
});

const VoyageDraft = mongoose.model('VoyageDraft', voyageDraftSchema);

module.exports = VoyageDraft;
