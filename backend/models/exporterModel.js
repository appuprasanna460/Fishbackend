const mongoose = require('mongoose');

const exporterSchema = new mongoose.Schema({
    businessName: {
        type: String,
        required: true,
        trim: true
    },
    registrationNumber: {
        type: String,
        unique: true,
        trim: true
    },
    gstNumber: {
        type: String,
        trim: true
    },
    panNumber: {
        type: String,
        trim: true
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    operatingHarbours: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour'
    }],
    staffMembers: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    businessSettings: {
        defaultCurrency: { type: String, default: 'INR' },
        autoGenerateInvoices: { type: Boolean, default: true },
        requireWeightConfirmation: { type: Boolean, default: true }
    },
    financialYearStart: {
        type: Date
    },
    financialYearEnd: {
        type: Date
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isDeleted: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

const Exporter = mongoose.model('Exporter', exporterSchema);
module.exports = Exporter;
