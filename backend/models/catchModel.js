const mongoose = require('mongoose');

const catchSchema = new mongoose.Schema({
    haulId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Haul',
        required: false
    },
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    species: {
        type: String,
        required: true,
        trim: true
    },
    weight: {
        type: Number,
        required: true,
        min: 0.1
    },
    boxes: {
        type: Number,
        required: true,
        min: 1
    },
    sharePercentage: {
        type: Number,
        default: 0,
        min: 0,
        max: 100
    },
    rate: {
        type: Number,
        default: 0
    },
    amount: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Indexes
catchSchema.index({ haulId: 1 });
catchSchema.index({ voyageId: 1 });
catchSchema.index({ ownerId: 1 });
catchSchema.index({ voyageId: 1, species: 1 });

const Catch = mongoose.model('Catch', catchSchema);
module.exports = Catch;
