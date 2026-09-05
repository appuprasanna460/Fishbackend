const mongoose = require('mongoose');

const notDraft = function() { return this.status !== 'DRAFT'; };

const voyageSchema = new mongoose.Schema({
    boatId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Boat',
        required: notDraft
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    captainId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew',
        required: notDraft
    },
    crewMembers: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew'
    }],
    departureHarbour: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Harbour',
        required: notDraft
    },
    departureDate: {
        type: Date,
        required: notDraft
    },
    departureTime: {
        type: String,
        required: notDraft
    },
    endDate: {
        type: Date,
        required: notDraft
    },
    voyageType: {
        type: String,
        required: notDraft,
        enum: ['DEEP_SEA', 'UNDERDEEP']
    },
    expectedDuration: {
        type: String,
        required: notDraft,
        enum: ['5-7_DAYS', '8-9_DAYS']
    },
    targetSpecies: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish'
    }],
    status: {
        type: String,
        required: true,
        enum: ['DRAFT', 'PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED']
    },
    supplies: {
        fuelItems: [{
            fuelType: {
                type: String,
                required: true
            },
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
            rate: {
                type: Number,
                default: 0
            },
            amount: {
                type: Number,
                default: 0
            }
        }],
        fuelType: {
            type: String,
            default: 'STANDARD DIESEL'
        },
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
        totalAmount: {
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
        iceRate: {
            type: Number,
            default: 0
        },
        iceAmount: {
            type: Number,
            default: 0
        },
        water: {
            type: Number,
            default: 0
        },
        waterRate: {
            type: Number,
            default: 0
        },
        waterAmount: {
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
    isDeleted: {
        type: Boolean,
        default: false
    },
    tokenStatus: {
        type: String,
        enum: ['NONE', 'IN_PROGRESS', 'APPROVED'],
        default: 'NONE'
    },
    tokenImage: {
        type: String,
        default: ''
    },
    tokenNotes: {
        type: String,
        default: ''
    },
    tokenViewed: {
        type: Boolean,
        default: false
    },
    tokenRequestedAt: {
        type: Date,
        default: null
    },
    tokenApprovedAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Virtual for voyageNo
voyageSchema.virtual('voyageNo').get(function () {
    return `VOY-${this._id.toString().substring(18).toUpperCase()}`;
});

// Calculate fuelToCarry, amount, and iceToCarry before saving
voyageSchema.pre('save', function () {
    if (this.supplies) {
        if (Array.isArray(this.supplies.fuelItems) && this.supplies.fuelItems.length > 0) {
            let totalReq = 0;
            let totalTank = 0;
            let totalToCarry = 0;
            let grandTotalAmount = 0;
            this.supplies.fuelItems.forEach(item => {
                item.fuelToCarry = Math.max(0, (item.fuelRequired || 0) - (item.fuelInTank || 0));
                item.amount = item.fuelToCarry * (item.rate || 0);
                totalReq += (item.fuelRequired || 0);
                totalTank += (item.fuelInTank || 0);
                totalToCarry += item.fuelToCarry;
                grandTotalAmount += item.amount;
            });
            this.supplies.fuelRequired = totalReq;
            this.supplies.fuelInTank = totalTank;
            this.supplies.fuelToCarry = totalToCarry;
            this.supplies.totalAmount = grandTotalAmount;
            this.supplies.fuelType = this.supplies.fuelItems.map(i => i.fuelType).join(', ');
        } else {
            this.supplies.fuelToCarry = Math.max(0, (this.supplies.fuelRequired || 0) - (this.supplies.fuelInTank || 0));
        }
        this.supplies.iceToCarry = Math.max(0, (this.supplies.iceRequired || 0) - (this.supplies.iceInStock || 0));
        this.supplies.iceAmount = (this.supplies.iceToCarry || 0) * (this.supplies.iceRate || 0);
        this.supplies.waterAmount = (this.supplies.water || 0) * (this.supplies.waterRate || 0);
    }
});

// Indexes
voyageSchema.index({ ownerId: 1 });
voyageSchema.index({ boatId: 1 });
voyageSchema.index({ status: 1 });
voyageSchema.index({ departureDate: 1 });

const Voyage = mongoose.model('Voyage', voyageSchema);
module.exports = Voyage;
