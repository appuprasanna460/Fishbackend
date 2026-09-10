const mongoose = require('mongoose');

const payablePaymentLogSchema = new mongoose.Schema({
    amount: {
        type: Number,
        required: true,
        min: 0.01
    },
    paymentDate: {
        type: Date,
        default: Date.now
    },
    paymentMethod: {
        type: String,
        enum: ['BANK_TRANSFER', 'CASH', 'CHEQUE', 'UPI'],
        required: true
    },
    referenceNumber: {
        type: String,
        default: ''
    },
    notes: {
        type: String,
        default: ''
    }
}, { _id: true });

const payableSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    sellerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    sellerName: {
        type: String,
        required: true
    },
    purchaseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Purchase',
        required: true
    },
    purchaseNumber: {
        type: String,
        required: true
    },
    totalAmount: {
        type: Number,
        required: true
    },
    paidAmount: {
        type: Number,
        default: 0
    },
    balanceAmount: {
        type: Number,
        required: true
    },
    dueDate: {
        type: Date
    },
    status: {
        type: String,
        enum: ['PENDING', 'PART_PAID', 'PAID', 'OVERDUE'],
        default: 'PENDING'
    },
    paymentHistory: [payablePaymentLogSchema]
}, {
    timestamps: true
});

payableSchema.index({ exporterId: 1, status: 1 });
payableSchema.index({ exporterId: 1, sellerName: 1 });

const Payable = mongoose.model('Payable', payableSchema);
module.exports = Payable;
