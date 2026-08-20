const mongoose = require('mongoose');

const returnEntrySchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true,
        unique: true
    },
    boatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat',
        required: true
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    returningToHarbour: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour',
        required: true
    },
    returnDate: {
        type: Date,
        required: true
    },
    returnTime: {
        type: String,
        required: true
    },
    seaCondition: {
        type: String,
        required: true,
        enum: ['Calm', 'Moderate', 'Rough']
    },
    distanceFromHarbour: {
        type: Number,
        default: 0
    },
    fuelInTank: {
        type: Number,
        default: 0
    },
    iceInStock: {
        type: Number,
        default: 0
    },
    notes: {
        type: String,
        trim: true,
        default: ''
    }
}, {
    timestamps: true
});

returnEntrySchema.index({ voyageId: 1 }, { unique: true });
returnEntrySchema.index({ ownerId: 1 });

const ReturnEntry = mongoose.model('ReturnEntry', returnEntrySchema);
module.exports = ReturnEntry;
