const mongoose = require('mongoose');

const paymentLogSchema = new mongoose.Schema({
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
    },
    recordedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, { _id: true });

const receivableSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    customerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true
    },
    customerName: {
        type: String,
        required: true
    },
    saleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Sale',
        required: true
    },
    invoiceNumber: {
        type: String,
        required: true
    },
    invoiceDate: {
        type: Date,
        default: Date.now
    },
    dueDate: {
        type: Date
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
    status: {
        type: String,
        enum: ['PENDING', 'PART_PAID', 'PAID', 'OVERDUE'],
        default: 'PENDING'
    },
    daysOverdue: {
        type: Number,
        default: 0
    },
    paymentHistory: [paymentLogSchema]
}, {
    timestamps: true
});

receivableSchema.index({ exporterId: 1, status: 1 });
receivableSchema.index({ exporterId: 1, customerId: 1 });

const Receivable = mongoose.model('Receivable', receivableSchema);
module.exports = Receivable;
