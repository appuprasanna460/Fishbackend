const mongoose = require('mongoose');

const unitMasterSchema = new mongoose.Schema({
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
    symbol: {
        type: String,
        required: true,
        trim: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isSystem: {
        type: Boolean,
        default: false
    },
    sortOrder: {
        type: Number,
        default: 0
    }
}, { timestamps: true });

unitMasterSchema.index({ exporterId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('UnitMaster', unitMasterSchema);
