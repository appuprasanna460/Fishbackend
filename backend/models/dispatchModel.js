const mongoose = require('mongoose');

const dropLocationSchema = new mongoose.Schema({
    destination: {
        type: String,
        required: true
    },
    saleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Sale'
    },
    saleNumber: {
        type: String
    },
    itemsDescription: {
        type: String
    },
    status: {
        type: String,
        enum: ['PENDING', 'DELIVERED'],
        default: 'PENDING'
    }
}, { _id: true });

const dispatchItemSchema = new mongoose.Schema({
    saleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Sale',
        required: true
    },
    saleItemId: {
        type: mongoose.Schema.Types.ObjectId
    },
    speciesName: {
        type: String
    },
    weightKg: {
        type: Number,
        default: 0
    },
    dispatchedWeightKg: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['PENDING', 'DELIVERED'],
        default: 'PENDING'
    }
}, { _id: true });

const dispatchSchema = new mongoose.Schema({
    tripCode: {
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
    idempotencyKey: {
        type: String,
        unique: true,
        sparse: true
    },
    vehicleNumber: {
        type: String,
        required: true,
        trim: true
    },
    vehicleType: {
        type: String,
        enum: ['OWN', 'HIRED'],
        default: 'OWN'
    },
    driverName: {
        type: String,
        required: true,
        trim: true
    },
    driverPhone: {
        type: String,
        required: true,
        trim: true
    },
    sales: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Sale'
    }],
    items: [dispatchItemSchema],
    drops: [dropLocationSchema],
    marketFreight: {
        type: Number,
        default: 0
    },
    totalBoxes: {
        type: Number,
        default: 0
    },
    totalWeightKg: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['LOADING', 'IN_TRANSIT', 'DELIVERED', 'CLOSED'],
        default: 'LOADING'
    },
    departureTime: {
        type: Date
    },
    etaTime: {
        type: Date
    }
}, {
    timestamps: true
});

dispatchSchema.index({ tripCode: 1 }, { unique: true });
dispatchSchema.index({ exporterId: 1, status: 1 });

const Dispatch = mongoose.model('Dispatch', dispatchSchema);
module.exports = Dispatch;
