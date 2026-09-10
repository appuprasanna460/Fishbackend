const mongoose = require('mongoose');

const gradeMasterSchema = new mongoose.Schema({
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
    description: {
        type: String,
        trim: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    sortOrder: {
        type: Number,
        default: 0
    }
}, { timestamps: true });

gradeMasterSchema.index({ exporterId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('GradeMaster', gradeMasterSchema);
