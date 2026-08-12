const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        default: 'NEW_USER_REGISTRATION'
        // Types: NEW_USER_REGISTRATION, RENEWAL_REQUEST, SUBSCRIPTION_EXPIRY_WARNING,
        //        RENEWAL_APPROVED, RENEWAL_REJECTED
    },
    title: {
        type: String,
        trim: true
    },
    message: {
        type: String,
        required: true
    },
    // Reference to a related document (e.g. RenewalRequest._id)
    relatedId: {
        type: mongoose.Schema.Types.ObjectId
    },
    // Type of the related document for routing (e.g. 'RENEWAL_REQUEST', '3_DAY', '2_DAY', '1_DAY')
    relatedType: {
        type: String,
        trim: true
    },
    isRead: {
        type: Boolean,
        default: false
    },
    isActioned: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

notificationSchema.index({ userId: 1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ isActioned: 1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ relatedId: 1 });

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
