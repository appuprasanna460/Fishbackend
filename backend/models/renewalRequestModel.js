// models/renewalRequestModel.js
const mongoose = require('mongoose');

const renewalRequestSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    // The plan the user is requesting to renew/switch to
    requestedPlanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'SubscriptionPlan',
        required: true
    },
    // Snapshot of plan details at request time
    requestedPlanName: {
        type: String,
        required: true,
        trim: true
    },
    requestedDurationDays: {
        type: Number,
        required: true
    },
    // Status lifecycle: PENDING → APPROVED or REJECTED; user can CANCEL
    status: {
        type: String,
        enum: ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'],
        default: 'PENDING'
    },
    requestedAt: {
        type: Date,
        default: Date.now
    },
    approvedAt: {
        type: Date
    },
    approvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    rejectedAt: {
        type: Date
    },
    rejectedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    rejectionReason: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Indexes
renewalRequestSchema.index({ userId: 1, status: 1 });
renewalRequestSchema.index({ status: 1 });
renewalRequestSchema.index({ requestedAt: -1 });

const RenewalRequest = mongoose.model('RenewalRequest', renewalRequestSchema);
module.exports = RenewalRequest;
