const mongoose = require('mongoose');

const haulSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
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
    haulNumber: {
        type: Number,
        required: true
    },
    fishingGround: {
        type: String,
        required: false,
        trim: true,
        default: 'General'
    },
    gearType: {
        type: String,
        required: false,
        trim: true,
        default: 'Standard'
    },
    netLength: {
        type: Number,
        required: false,
        min: 0,
        default: 0
    },
    startLocation: {
        latitude: {
            type: Number,
            required: true
        },
        longitude: {
            type: Number,
            required: true
        }
    },
    gpsTrack: [{
        latitude: {
            type: Number,
            required: true
        },
        longitude: {
            type: Number,
            required: true
        },
        timestamp: {
            type: Date,
            default: Date.now
        }
    }],
    startedAt: {
        type: Date,
        required: true
    },
    endedAt: {
        type: Date,
        default: null
    },
    duration: {
        type: Number, // in minutes
        default: 0
    },
    distance: {
        type: Number, // in km
        default: 0
    },
    averageSpeed: {
        type: Number, // in km/h
        default: 0
    },
    status: {
        type: String,
        required: true,
        enum: ['ACTIVE', 'STOPPED', 'COMPLETED'],
        default: 'ACTIVE'
    },
    notes: {
        type: String,
        trim: true,
        default: ''
    }
}, {
    timestamps: true
});

// Indexes for faster querying
haulSchema.index({ voyageId: 1 });
haulSchema.index({ ownerId: 1 });
haulSchema.index({ status: 1 });

const Haul = mongoose.model('Haul', haulSchema);
module.exports = Haul;
