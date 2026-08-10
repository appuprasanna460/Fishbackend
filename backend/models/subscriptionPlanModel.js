// models/subscriptionPlanModel.js
const mongoose = require('mongoose');

const subscriptionPlanSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    price: {
        type: Number,
        required: true,
        min: 0
    },
    duration: {
        type: String,
        enum: ['QUARTERLY', 'HALF_YEARLY', 'YEARLY'],
        required: true
    },
    billingCycle: {
        type: String,
        enum: ['QUARTERLY', 'HALF_YEARLY', 'YEARLY'],
        default: function () { return this.duration; }
    },
    features: [{
        type: String,
        trim: true
    }],
    isActive: {
        type: Boolean,
        default: true
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, {
    timestamps: true
});

// Indexes
subscriptionPlanSchema.index({ isActive: 1, isDeleted: 1 });
subscriptionPlanSchema.index({ duration: 1 });

// Static method to get active plans
subscriptionPlanSchema.statics.getActivePlans = function () {
    return this.find({
        isActive: true,
        isDeleted: false
    }).sort({ price: 1 }).lean();
};

// Static method to get all plans (including inactive)
subscriptionPlanSchema.statics.getAllPlans = function () {
    return this.find({ isDeleted: false })
        .sort({ createdAt: -1 })
        .lean();
};

const SubscriptionPlan = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);
module.exports = SubscriptionPlan;