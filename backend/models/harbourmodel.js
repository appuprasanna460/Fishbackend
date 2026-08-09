const mongoose = require('mongoose');

const harbourSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true,
        trim: true
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

harbourSchema.index({ name: 1 }, { unique: true });
harbourSchema.index({ isActive: 1, isDeleted: 1 });

const Harbour = mongoose.model('Harbour', harbourSchema);
module.exports = Harbour;
