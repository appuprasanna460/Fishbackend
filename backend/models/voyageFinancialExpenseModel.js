const mongoose = require('mongoose');

const voyageFinancialExpenseSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
    },
    expenseName: {
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
        required: true,
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
    },
    isCustom: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Compound index to prevent duplicate standard expense records (e.g. Fuel) on the same voyage
voyageFinancialExpenseSchema.index({ voyageId: 1, expenseName: 1 }, { unique: true });
voyageFinancialExpenseSchema.index({ voyageId: 1 });

const VoyageFinancialExpense = mongoose.model('VoyageFinancialExpense', voyageFinancialExpenseSchema, 'voyage_expenses');
module.exports = VoyageFinancialExpense;
