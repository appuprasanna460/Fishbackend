const mongoose = require('mongoose');

// Dedicated voyage expense model for tracking per-day fuel, ice, and water usage
// scoped to a specific voyage. Separate from the manual ledger for clean querying.
const voyageExpenseSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
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
    date: {
        type: Date,
        required: true
    },
    fuelUsed: {
        type: Number,
        default: 0,
        min: 0  // in Litres
    },
    iceUsed: {
        type: Number,
        default: 0,
        min: 0  // in Kg
    },
    waterUsed: {
        type: Number,
        default: 0,
        min: 0  // in Litres
    },
    notes: {
        type: String,
        trim: true,
        default: ''
    }
}, {
    timestamps: true
});

// Ensure one expense record per voyage per day
voyageExpenseSchema.index({ voyageId: 1, date: 1 }, { unique: true });
voyageExpenseSchema.index({ ownerId: 1 });
voyageExpenseSchema.index({ voyageId: 1 });

const VoyageExpense = mongoose.model('VoyageExpense', voyageExpenseSchema);
module.exports = VoyageExpense;
