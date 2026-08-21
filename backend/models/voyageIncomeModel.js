const mongoose = require('mongoose');

const voyageIncomeSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
    },
    speciesId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish',
        default: null
    },
    speciesName: {
        type: String,
        required: true,
        trim: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 0
    },
    unit: {
        type: String,
        default: 'kg',
        trim: true
    },
    rate: {
        type: Number,
        required: true,
        min: 0
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    }
}, {
    timestamps: true
});

// Compound unique index to ensure one rate record per species per voyage
voyageIncomeSchema.index({ voyageId: 1, speciesName: 1 }, { unique: true });
voyageIncomeSchema.index({ voyageId: 1 });

const VoyageIncome = mongoose.model('VoyageIncome', voyageIncomeSchema, 'voyage_income');
module.exports = VoyageIncome;
