const mongoose = require('mongoose');

const saleItemSchema = new mongoose.Schema({
    stockId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Stock'
    },
    speciesId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish'
    },
    speciesName: {
        type: String,
        required: true
    },
    grade: {
        type: String,
        default: 'STANDARD'
    },
    boxes: {
        type: Number,
        default: 0
    },
    weightKg: {
        type: Number,
        required: true,
        min: 0.01
    },
    dispatchedQuantity: {
        type: Number,
        default: 0,
        min: 0
    },
    ratePerKg: {
        type: Number,
        required: true,
        min: 0.01
    },
    amount: {
        type: Number,
        required: true
    },
    purchaseCost: {
        type: Number,
        default: 0
    },
    margin: {
        type: Number,
        default: 0
    }
}, { _id: true });

const saleSchema = new mongoose.Schema({
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
    customerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true
    },
    customerName: {
        type: String,
        required: true,
        trim: true
    },
    customerPhone: {
        type: String,
        trim: true
    },
    customerType: {
        type: String,
        enum: ['WHOLESALE_MARKET', 'HOTEL', 'RESTAURANT', 'SEAFOOD_SHOP', 'WHOLESALER', 'DISTRIBUTOR', 'RETAILER', 'INSTITUTIONAL'],
        default: 'WHOLESALE_MARKET'
    },
    saleNumber: {
        type: String,
        required: true,
        unique: true
    },
    invoiceNumber: {
        type: String,
        sparse: true
    },
    saleDate: {
        type: Date,
        default: Date.now
    },
    marketId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Location'
    },
    marketName: {
        type: String,
        default: ''
    },
    items: [saleItemSchema],
    totalItems: {
        type: Number,
        default: 0
    },
    totalWeightKg: {
        type: Number,
        required: true
    },
    avgRatePerKg: {
        type: Number,
        default: 0
    },
    totalAmount: {
        type: Number,
        required: true
    },
    charges: {
        loadingCharge: { type: Number, default: 0 },
        marketCharge: { type: Number, default: 0 },
        transportationCharge: { type: Number, default: 0 },
        otherCharges: { type: Number, default: 0 }
    },
    discount: {
        type: Number,
        default: 0
    },
    netAmount: {
        type: Number,
        required: true
    },
    paymentMode: {
        type: String,
        enum: ['CASH', 'CREDIT', 'ADVANCE', 'UPI', 'BANK_TRANSFER'],
        default: 'CREDIT'
    },
    paymentTerms: {
        type: String,
        enum: ['IMMEDIATE', '7_DAYS', '15_DAYS', '30_DAYS', '45_DAYS'],
        default: 'IMMEDIATE'
    },
    amountReceived: {
        type: Number,
        default: 0
    },
    balanceAmount: {
        type: Number,
        default: 0
    },
    paymentStatus: {
        type: String,
        enum: ['PAID', 'PART_PAID', 'PENDING', 'OVERDUE'],
        default: 'PENDING'
    },
    dispatchStatus: {
        type: String,
        enum: ['PENDING', 'PARTIAL', 'DISPATCHED', 'COMPLETED', 'CANCELLED'],
        default: 'PENDING'
    },
    status: {
        type: String,
        enum: ['DRAFT', 'CONFIRMED', 'CANCELLED'],
        default: 'DRAFT'
    },
    isImmutable: {
        type: Boolean,
        default: false
    },
    notes: {
        type: String,
        default: ''
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }
}, {
    timestamps: true
});

saleSchema.index({ saleNumber: 1 }, { unique: true });
saleSchema.index({ exporterId: 1, saleDate: -1 });
saleSchema.index({ exporterId: 1, dispatchStatus: 1 });

const Sale = mongoose.model('Sale', saleSchema);
module.exports = Sale;
