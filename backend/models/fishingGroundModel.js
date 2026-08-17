const mongoose = require('mongoose');

const fishingGroundSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    isFavourite: {
        type: Boolean,
        default: false
    },
    usedCount: {
        type: Number,
        default: 0
    },
    lastUsedAt: {
        type: Date,
        default: null
    },
    totalCatch: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Indexes
fishingGroundSchema.index({ ownerId: 1 });
fishingGroundSchema.index({ ownerId: 1, name: 1 }, { unique: true }); // Prevent duplicate fishing ground names per owner

const FishingGround = mongoose.model('FishingGround', fishingGroundSchema);
module.exports = FishingGround;
