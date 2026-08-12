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
        default: 0,
        min: 0
    },
    // durationDays: number of days this plan is valid for (set by Super Admin, never hardcoded)
    durationDays: {
        type: Number,
        required: true,
        min: 1
    },
    // duration: free-text label for display purposes (e.g. 'Quarter', 'Half')
    duration: {
        type: String,
        trim: true
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
subscriptionPlanSchema.index({ durationDays: 1 });

// Static method to get active plans
subscriptionPlanSchema.statics.getActivePlans = function () {
    return this.find({
        isActive: true,
        isDeleted: false
    }).sort({ durationDays: 1 }).lean();
};

// Static method to get all plans (including inactive)
subscriptionPlanSchema.statics.getAllPlans = function () {
    return this.find({ isDeleted: false })
        .sort({ createdAt: -1 })
        .lean();
};

const SubscriptionPlan = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);
module.exports = SubscriptionPlan;