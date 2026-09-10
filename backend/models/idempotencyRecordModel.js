const mongoose = require('mongoose');

const idempotencyRecordSchema = new mongoose.Schema({
    key: {
        type: String,
        required: true,
        index: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    endpoint: {
        type: String,
        required: true
    },
    requestHash: {
        type: String
    },
    responseBody: {
        type: mongoose.Schema.Types.Mixed,
        required: true
    },
    statusCode: {
        type: Number,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 86400 // 24 hours TTL
    }
}, { timestamps: true });

idempotencyRecordSchema.index({ key: 1, userId: 1, endpoint: 1 }, { unique: true });

module.exports = mongoose.model('IdempotencyRecord', idempotencyRecordSchema);
