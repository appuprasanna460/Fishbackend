const mongoose = require('mongoose');

const stockSchema = new mongoose.Schema({
    exporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    speciesId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish'
    },
    speciesName: {
        type: String,
        required: true,
        trim: true
    },
    grade: {
        type: String,
        default: 'STANDARD'
    },
    size: {
        type: String,
        default: 'STANDARD'
    },
    locationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Location'
    },
    subLocationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'SubLocation'
    },
    availableWeightKg: {
        type: Number,
        default: 0,
        min: 0
    },
    reservedWeightKg: {
        type: Number,
        default: 0,
        min: 0
    },
    dispatchedWeightKg: {
        type: Number,
        default: 0,
        min: 0
    },
    totalBoxes: {
        type: Number,
        default: 0
    },
    avgCostPerKg: {
        type: Number,
        default: 0
    },
    totalPurchaseCost: {
        type: Number,
        default: 0
    },
    sellingPricePerKg: {
        type: Number,
        default: 0
    },
    rackLocation: {
        type: String,
        default: 'Rack A-1'
    },
    lotIds: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'PurchaseLot'
    }],
    status: {
        type: String,
        enum: ['READY', 'RESERVED', 'DISPATCHED', 'CLOSED'],
        default: 'READY'
    }
}, {
    timestamps: true
});

stockSchema.index({ exporterId: 1, speciesName: 1, grade: 1, status: 1 });
stockSchema.index(
    { exporterId: 1, speciesName: 1, grade: 1 },
    { unique: true, partialFilterExpression: { status: 'READY' } }
);

const Stock = mongoose.model('Stock', stockSchema);
module.exports = Stock;
