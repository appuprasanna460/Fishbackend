const mongoose = require('mongoose');

const voyageSchema = new mongoose.Schema({
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
    captainId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew',
        required: true
    },
    crewMembers: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew',
        required: true
    }],
    departureHarbour: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour',
        required: true
    },
    departureDate: {
        type: Date,
        required: true
    },
    departureTime: {
        type: String,
        required: true
    },
    endDate: {
        type: Date,
        required: true
    },
    voyageType: {
        type: String,
        required: true,
        enum: ['DEEP_SEA', 'UNDERDEEP']
    },
    expectedDuration: {
        type: String,
        required: true,
        enum: ['5-7_DAYS', '8-9_DAYS']
    },
    targetSpecies: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish'
    }],
    status: {
        type: String,
        required: true,
        enum: ['PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED'],
        default: 'PLANNED'
    },
    supplies: {
        fuelRequired: {
            type: Number,
            default: 0
        },
        fuelInTank: {
            type: Number,
            default: 0
        },
        fuelToCarry: {
            type: Number,
            default: 0
        },
        iceRequired: {
            type: Number,
            default: 0
        },
        iceInStock: {
            type: Number,
            default: 0
        },
        iceToCarry: {
            type: Number,
            default: 0
        },
        water: {
            type: Number,
            default: 0
        },
        foodSupplies: {
            type: String,
            trim: true,
            default: ''
        },
        otherSupplies: {
            type: String,
            trim: true,
            default: ''
        }
    },
    checklist: {
        type: Map,
        of: String,
        default: {}
    },
    notes: {
        type: String,
        trim: true,
        default: ''
    },
    startedAt: {
        type: Date,
        default: null
    },
    completedAt: {
        type: Date,
        default: null
    },
    cancelledAt: {
        type: Date,
        default: null
    },
    isDeleted: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Calculate fuelToCarry and iceToCarry before saving
voyageSchema.pre('save', function () {
    if (this.supplies) {
        this.supplies.fuelToCarry = Math.max(0, (this.supplies.fuelRequired || 0) - (this.supplies.fuelInTank || 0));
        this.supplies.iceToCarry = Math.max(0, (this.supplies.iceRequired || 0) - (this.supplies.iceInStock || 0));
    }
});

// Indexes
voyageSchema.index({ ownerId: 1 });
voyageSchema.index({ boatId: 1 });
voyageSchema.index({ status: 1 });
voyageSchema.index({ departureDate: 1 });

const Voyage = mongoose.model('Voyage', voyageSchema);
module.exports = Voyage;
