const mongoose = require('mongoose');

const voyageOtherIncomeSchema = new mongoose.Schema({
    voyageId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Voyage',
        required: true
    },
    incomeName: {
        type: String,
        required: true,
        trim: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    }
}, {
    timestamps: true
});

voyageOtherIncomeSchema.index({ voyageId: 1 });

const VoyageOtherIncome = mongoose.model('VoyageOtherIncome', voyageOtherIncomeSchema, 'voyage_other_income');
module.exports = VoyageOtherIncome;
