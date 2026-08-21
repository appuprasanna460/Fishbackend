const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    documentName: {
        type: String,
        required: true,
        trim: true
    },
    documentNumber: {
        type: String,
        required: true,
        trim: true
    },
    boatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat',
        default: null
    },
    crewMemberId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew',
        default: null
    },
    issueDate: {
        type: Date,
        required: true
    },
    expiryDate: {
        type: Date,
        required: true
    },
    issuedBy: {
        type: String,
        required: true,
        trim: true
    },
    files: [{
        url: {
            type: String,
            required: true
        },
        key: {
            type: String,
            required: true
        },
        originalName: {
            type: String
        },
        mimeType: {
            type: String
        },
        sizeBytes: {
            type: Number
        }
    }],
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

// Indexes for query performance
documentSchema.index({ ownerId: 1 });
documentSchema.index({ boatId: 1 });
documentSchema.index({ crewMemberId: 1 });
documentSchema.index({ isActive: 1, isDeleted: 1 });

// Virtual property for remaining days
documentSchema.virtual('remainingDays').get(function () {
    if (!this.expiryDate) return 0;
    const diff = new Date(this.expiryDate) - new Date();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
});

// Virtual property for status badge validation
documentSchema.virtual('status').get(function () {
    if (!this.expiryDate) return 'Expired';
    const remaining = this.remainingDays;
    if (remaining <= 0) return 'Expired';
    if (remaining <= 30) return 'Expiring Soon';
    return 'Valid';
});

// Ensure virtuals are serialized
documentSchema.set('toJSON', { virtuals: true });
documentSchema.set('toObject', { virtuals: true });

const Document = mongoose.model('Document', documentSchema);
module.exports = Document;
