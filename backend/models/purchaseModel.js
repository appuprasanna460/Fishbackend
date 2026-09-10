const mongoose = require('mongoose');

const purchaseItemSchema = new mongoose.Schema({
    speciesId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish'
    },
    speciesName: {
        type: String,
        required: true,
        trim: true
    },
    unit: {
        type: String,
        required: true,
        trim: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 0.01
    },
    ratePerUnit: {
        type: Number,
        required: true,
        min: 0.01
    },
    amount: {
        type: Number,
        required: true
    },
    grade: {
        type: String,
        default: 'STANDARD'
    },
    size: {
        type: String,
        default: 'STANDARD'
    },
    knownWeightKg: {
        type: Number,
        default: null
    }
}, { _id: true });

const purchaseSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    idempotencyKey: {
        type: String,
        unique: true,
        sparse: true
    },
    parentPurchaseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Purchase'
    },
    harbourId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour',
        required: true
    },
    purchaseStaffId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: false
    },
    purchaseStaffName: {
        type: String,
        trim: true
    },
    purchaseNumber: {
        type: String,
        required: true,
        unique: true
    },
    purchaseDate: {
        type: Date,
        default: Date.now
    },
    purchaseTime: {
        type: String,
        default: () => new Date().toLocaleTimeString('en-US', { hour12: false })
    },
    sellerType: {
        type: String,
        enum: ['BOAT_OWNER', 'COMMISSION_AGENT', 'AGENT', 'SUPPLIER'],
        required: true
    },
    sellerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    sellerName: {
        type: String,
        required: true,
        trim: true
    },
    sellerPhone: {
        type: String,
        trim: true
    },
    boatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat'
    },
    boatName: {
        type: String,
        trim: true,
        default: 'Nil'
    },
    boatNumber: {
        type: String,
        trim: true
    },
    paymentMethod: {
        type: String,
        enum: ['CASH', 'UPI', 'CARD', 'CREDIT'],
        default: 'CASH'
    },
    items: [purchaseItemSchema],
    totalAmount: {
        type: Number,
        required: true
    },
    notes: {
        type: String,
        default: ''
    },
    photos: [{
        type: String
    }],
    status: {
        type: String,
        enum: ['DRAFT', 'PENDING', 'CONFIRMED', 'RECEIVED', 'COMPLETED', 'CANCELLED', 'REVERSED'],
        default: 'DRAFT'
    },
    isImmutable: {
        type: Boolean,
        default: false
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    approvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    approvedAt: {
        type: Date
    }
}, {
    timestamps: true
});

purchaseSchema.index({ purchaseNumber: 1 }, { unique: true });
purchaseSchema.index({ harbourId: 1, status: 1 });
purchaseSchema.index({ exporterId: 1, status: 1 });

const Purchase = mongoose.model('Purchase', purchaseSchema);
module.exports = Purchase;
