const mongoose = require('mongoose');

const gradeSplitSchema = new mongoose.Schema({
    grade: {
        type: String,
        required: true
    },
    weight: {
        type: Number,
        required: true,
        min: 0
    },
    splitPercentage: {
        type: Number,
        default: 0
    }
}, { _id: false });

const issueReportSchema = new mongoose.Schema({
    reason: {
        type: String,
        enum: ['SHORTAGE', 'DAMAGE', 'QUALITY_ISSUE', 'OTHER'],
        required: true
    },
    quantityKg: {
        type: Number,
        required: true
    },
    notes: {
        type: String,
        default: ''
    },
    reportedAt: {
        type: Date,
        default: Date.now
    },
    reportedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, { _id: true });

const purchaseLotSchema = new mongoose.Schema({
    parentLotId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'PurchaseLot'
    },
    purchaseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Purchase',
        required: true
    },
    lotNumber: {
        type: String,
        required: true,
        unique: true
    },
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    harbourId: {
        type: String,
        required: true
    },
    harbourName: {
        type: String,
        required: true
    },
    sellerName: {
        type: String,
        required: true
    },
    species: {
        type: String,
        required: true
    },
    purchaseUnit: {
        type: String,
        required: true
    },
    purchaseQty: {
        type: Number,
        required: true
    },
    purchaseAmount: {
        type: Number,
        required: true
    },
    weighedWeightKg: {
        type: Number,
        default: null
    },
    costPerKg: {
        type: Number,
        default: null
    },
    gradeSplits: [gradeSplitSchema],
    issueReports: [issueReportSchema],
    rejectedWeightKg: {
        type: Number,
        default: 0
    },
    qualityNotes: {
        type: String,
        default: ''
    },
    batchVehicleNumber: {
        type: String,
        default: ''
    },
    batchDriverName: {
        type: String,
        default: ''
    },
    status: {
        type: String,
        enum: ['PENDING', 'RECEIVING', 'WEIGHED', 'DONE', 'CLOSED'],
        default: 'PENDING'
    },
    isImmutable: {
        type: Boolean,
        default: false
    },
    receivedAt: {
        type: Date
    }
}, {
    timestamps: true
});

purchaseLotSchema.pre('save', function (next) {
    if (!this.isNew && this.isDirectModified('isImmutable') === false && this.isImmutable) {
        // If immutable, reject mutations except adding issueReports
        if (this.isModified() && !this.isModified('issueReports')) {
            return next(new Error('Cannot modify immutable PurchaseLot'));
        }
    }
    next();
});

purchaseLotSchema.index({ lotNumber: 1 }, { unique: true });
purchaseLotSchema.index({ exporterId: 1, status: 1 });

const PurchaseLot = mongoose.model('PurchaseLot', purchaseLotSchema);
module.exports = PurchaseLot;
