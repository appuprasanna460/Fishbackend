const mongoose = require('mongoose');

const crewSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    age: {
        type: Number,
        required: true,
        min: 18
    },
    phone: {
        type: String,
        required: true,
        trim: true
    },
    location: {
        type: String,
        required: true,
        trim: true
    },
    role: {
        type: String,
        required: true,
        enum: ['CAPTAIN', 'CREW']
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isAvailable: {
        type: Boolean,
        default: true
    },
    assignedTo: {
        voyageId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Voyage',
            default: null
        },
        boatId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Boat',
            default: null
        },
        assignedAt: {
            type: Date,
            default: null
        }
    },
    experience: {
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

// Indexes for faster querying
crewSchema.index({ ownerId: 1 });
crewSchema.index({ role: 1 });
crewSchema.index({ isAvailable: 1 });

const Crew = mongoose.model('Crew', crewSchema);
module.exports = Crew;
