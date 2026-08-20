const mongoose = require('mongoose');

const catchBySpeciesSchema = new mongoose.Schema({
    species: {
        type: String,
        required: true
    },
    weight: {
        type: Number,
        required: true,
        min: 0
    },
    boxes: {
        type: Number,
        required: true,
        min: 0
    }
});

const landingEntrySchema = new mongoose.Schema({
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
    landingHarbour: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour',
        required: true
    },
    landingDate: {
        type: Date,
        required: true
    },
    landingTime: {
        type: String,
        required: true
    },
    totalCatch: {
        type: Number,
        required: true,
        default: 0
    },
    catchBySpecies: [catchBySpeciesSchema],
    notes: {
        type: String,
        trim: true,
        default: ''
    }
}, {
    timestamps: true
});

landingEntrySchema.index({ voyageId: 1 }, { unique: true });
landingEntrySchema.index({ ownerId: 1 });

const LandingEntry = mongoose.model('LandingEntry', landingEntrySchema);
module.exports = LandingEntry;
