const mongoose = require('mongoose');

const voyageCrewSettlementSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
    },
    crewMemberId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Crew',
        required: true
    },
    crewMemberName: {
        type: String,
        required: true,
        trim: true
    },
    role: {
        type: String,
        required: true,
        trim: true
    },
    advance: {
        type: Number,
        default: 0,
        min: 0
    },
    paidAmount: {
        type: Number,
        default: 0,
        min: 0
    },
    paid: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

voyageCrewSettlementSchema.index({ voyageId: 1, crewMemberId: 1 }, { unique: true });
voyageCrewSettlementSchema.index({ voyageId: 1 });

const VoyageCrewSettlement = mongoose.model('VoyageCrewSettlement', voyageCrewSettlementSchema, 'voyage_crew_settlement');
module.exports = VoyageCrewSettlement;
