const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        trim: true
    },
    email: {
        type: String,
        trim: true,
        lowercase: true
    },
    address: {
        type: String,
        trim: true
    },
    gstNumber: {
        type: String,
        trim: true
    },
    creditLimit: {
        type: Number,
        default: 0
    },
    paymentTerms: {
        type: String,
        default: 'NET30'
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isDeleted: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

customerSchema.index({ exporterId: 1, name: 1 });
customerSchema.index({ exporterId: 1, isDeleted: 1 });

module.exports = mongoose.model('Customer', customerSchema);
