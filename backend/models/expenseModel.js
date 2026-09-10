const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    category: {
        type: String,
        required: true,
        trim: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0.01
    },
    date: {
        type: Date,
        default: Date.now
    },
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    paymentMethod: {
        type: String,
        enum: ['CASH', 'BANK_TRANSFER', 'UPI', 'CHEQUE'],
        default: 'CASH'
    },
    notes: {
        type: String,
        default: ''
    },
    attachmentUrl: {
        type: String,
        default: ''
    }
}, {
    timestamps: true
});

expenseSchema.index({ exporterId: 1, date: -1 });
expenseSchema.index({ exporterId: 1, category: 1 });

const Expense = mongoose.model('Expense', expenseSchema);
module.exports = Expense;
