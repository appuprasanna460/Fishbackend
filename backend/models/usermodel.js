const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const env = require('../config/env');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
        maxlength: 100
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true,
        match: /^\S+@\S+\.\S+$/
    },
    phone: {
        type: String,
        trim: true,
        match: /^[0-9]{10}$/
    },
    password: {
        type: String,
        required: true,
        minlength: 8
    },
    role: {
        type: String,
        enum: ['SUPER_ADMIN', 'COMMISSION_AGENT', 'STAFF', 'FISH_BUYER', 'BOAT_OWNER', 'CAPTAIN', 'CREW', 'MECHANIC', 'ACCOUNTANT'],
        required: true,
        default: 'FISH_BUYER'
    },
    locationId: {
        type: String,
        trim: true
    },
    subLocationId: {
        type: String,
        trim: true
    },
    harbourId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour'
    },
    companyName: {
        type: String,
        trim: true
    },
    referenceBy: {
        type: String,
        trim: true
    },
    // Legacy enum plan field — kept for backward compat with existing users
    subscriptionPlan: {
        type: String,
        default: 'NONE'
    },
    // New dynamic plan reference (set when user registers with a plan ObjectId)
    subscriptionPlanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'SubscriptionPlan'
    },
    // Snapshot of plan name at approval time (for display even if plan is later edited/deleted)
    subscriptionPlanName: {
        type: String,
        trim: true
    },
    // Snapshot of duration in days at approval time
    subscriptionDurationDays: {
        type: Number
    },
    // Subscription lifecycle status
    subscriptionStatus: {
        type: String,
        enum: ['PENDING_APPROVAL', 'ACTIVE', 'EXPIRING_SOON', 'EXPIRED', 'NONE'],
        default: 'NONE'
    },
    subscriptionStartDate: {
        type: Date
    },
    subscriptionEndDate: {
        type: Date
    },
    // Who approved the subscription and when
    subscriptionApprovedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    subscriptionApprovedAt: {
        type: Date
    },
    isApproved: {
        type: Boolean,
        default: true
    },
    agentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    // User Profile fields
    aboutYou: {
        type: String,
        trim: true,
        default: ''
    },
    dateOfBirth: {
        type: Date,
        default: null
    },
    address: {
        type: String,
        trim: true,
        default: ''
    },
    emergencyContactName: {
        type: String,
        trim: true,
        default: ''
    },
    emergencyContactRelationship: {
        type: String,
        trim: true,
        default: ''
    },
    emergencyContactPhone: {
        type: String,
        trim: true,
        default: ''
    },
    // Company profile fields
    companyLogo: {
        type: String,
        trim: true,
        default: ''
    },
    companyId: {
        type: String,
        trim: true,
        default: ''
    },
    companyEstablishedDate: {
        type: String,
        trim: true,
        default: ''
    },
    companyType: {
        type: String,
        trim: true,
        default: ''
    },
    companyRegisteredHarbour: {
        type: String,
        trim: true,
        default: ''
    },
    companyRegisteredAddress: {
        type: String,
        trim: true,
        default: ''
    },
    companyGstNumber: {
        type: String,
        trim: true,
        default: ''
    },
    companyPanNumber: {
        type: String,
        trim: true,
        default: ''
    },
    companyPhone: {
        type: String,
        trim: true,
        default: ''
    },
    companyEmail: {
        type: String,
        trim: true,
        default: ''
    },
    companyIsVerified: {
        type: Boolean,
        default: false
    },
    // Team member/Company user fields
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    assignedBoatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat',
        default: null
    },
    employeeId: {
        type: String,
        trim: true,
        default: ''
    },
    joinedDate: {
        type: Date,
        default: null
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    age: {
        type: Number,
        min: 18,
        max: 100
    },
    documents: [{
        id: {
            type: mongoose.Schema.Types.ObjectId,
            auto: true
        },
        name: {
            type: String,
            required: true,
            trim: true
        },
        url: {
            type: String,
            required: true
        },
        key: {
            type: String,
            required: true
        },
        uploadedAt: {
            type: Date,
            default: Date.now
        }
    }],
    lastLogin: {
        type: Date
    },
    refreshTokens: [{
        token: {
            type: String,
            required: true
        },
        expiresAt: {
            type: Date,
            required: true
        }
    }]
}, {
    timestamps: true
});

// Indexes for performance
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ role: 1 });
userSchema.index({ agentId: 1 });
userSchema.index({ locationId: 1 });
userSchema.index({ isActive: 1, isDeleted: 1 });
userSchema.index({ agentId: 1, role: 1 });
userSchema.index({ agentId: 1, isActive: 1 });

// ✅ FIXED: Pre-save middleware without 'next'
userSchema.pre('save', async function () {
    if (!this.isModified('password')) {
        return;
    }
    try {
        const salt = await bcrypt.genSalt(env.bcryptSaltRounds || 12);
        this.password = await bcrypt.hash(this.password, salt);
        console.log('✅ Password hashed successfully');
    } catch (error) {
        console.error('❌ Password hashing failed:', error);
        throw error;
    }
});

// ✅ FIXED: Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    if (!candidatePassword || !this.password) {
        console.log('❌ Missing password data for comparison');
        return false;
    }
    try {
        const isMatch = await bcrypt.compare(candidatePassword, this.password);
        return isMatch;
    } catch (error) {
        console.error('❌ Error comparing passwords:', error);
        return false;
    }
};

// Instance method to add refresh token
userSchema.methods.addRefreshToken = function (token, expiresAt) {
    this.refreshTokens.push({ token, expiresAt });
    return this.save();
};

// Instance method to remove refresh token
userSchema.methods.removeRefreshToken = async function (token) {
    this.refreshTokens = this.refreshTokens.filter(t => t.token !== token);
    return this.save();
};

// Instance method to clear all refresh tokens
userSchema.methods.clearRefreshTokens = async function () {
    this.refreshTokens = [];
    return this.save();
};

// Static method to find by email
userSchema.statics.findByEmail = function (email) {
    return this.findOne({ email: email.toLowerCase().trim() });
};

// To JSON transformation
userSchema.set('toJSON', {
    transform: (doc, ret) => {
        delete ret.password;
        delete ret.refreshTokens;
        delete ret.__v;
        return ret;
    }
});

const User = mongoose.model('User', userSchema);
module.exports = User;