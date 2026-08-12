const Notification = require('../models/notificationmodel');
const User = require('../models/usermodel');
const SubscriptionPlan = require('../models/subscriptionPlanModel');

// ─── Helper: fallback duration for legacy users without planId ────────────────
function legacyDurationDays(subscriptionPlan) {
    switch (subscriptionPlan) {
        case 'QUARTERLY': return 90;
        case 'HALF_YEARLY': return 180;
        case 'YEARLY': return 365;
        default: return 90;
    }
}

// ─── Get all pending registrations for Super Admin ────────────────────────────
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({
            isActioned: false,
            type: { $in: ['NEW_USER_REGISTRATION', 'RENEWAL_REQUEST'] }
        })
            .populate({
                path: 'userId',
                populate: [
                    {
                        path: 'harbourId',
                        model: 'Harbour',
                        select: 'name'
                    },
                    {
                        path: 'subscriptionPlanId',
                        model: 'SubscriptionPlan',
                        select: 'name durationDays price'
                    }
                ]
            })
            .sort({ createdAt: -1 });

        // Filter out notifications with deleted users
        const validNotifications = notifications.filter(n => n.userId !== null);

        return res.status(200).json({
            success: true,
            data: validNotifications
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to fetch notifications',
            error: error.message
        });
    }
};

// ─── Get notifications for the logged-in user (non-admin) ─────────────────────
exports.getMyNotifications = async (req, res) => {
    try {
        const userId = req.user._id;
        const notifications = await Notification.find({ userId })
            .sort({ createdAt: -1 })
            .limit(50)
            .lean();

        return res.status(200).json({
            success: true,
            data: notifications
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to fetch notifications',
            error: error.message
        });
    }
};

// ─── Mark notification as read ────────────────────────────────────────────────
exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        await Notification.findOneAndUpdate(
            { _id: id, userId },
            { isRead: true }
        );
        return res.status(200).json({ success: true, message: 'Notification marked as read' });
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Failed to mark notification as read' });
    }
};

// ─── Approve user registration ────────────────────────────────────────────────
exports.approveRegistration = async (req, res) => {
    try {
        const { id } = req.params; // Notification ID

        const notification = await Notification.findById(id);
        if (!notification) {
            return res.status(404).json({ success: false, message: 'Notification not found' });
        }

        const user = await User.findById(notification.userId);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const now = new Date();
        let durationDays;
        let planName;

        // Try to look up plan via new subscriptionPlanId first (dynamic)
        if (user.subscriptionPlanId) {
            const plan = await SubscriptionPlan.findById(user.subscriptionPlanId);
            if (plan) {
                durationDays = plan.durationDays;
                planName = plan.name;
            }
        }

        // Fallback to legacy enum-based calculation for existing users
        if (!durationDays) {
            durationDays = legacyDurationDays(user.subscriptionPlan);
            planName = user.subscriptionPlan || 'Standard';
        }

        const endDate = new Date(now);
        endDate.setDate(endDate.getDate() + durationDays);

        // Activate subscription with full snapshot
        user.isApproved = true;
        user.isActive = true;
        user.subscriptionStartDate = now;
        user.subscriptionEndDate = endDate;
        user.subscriptionStatus = 'ACTIVE';
        user.subscriptionPlanName = planName;
        user.subscriptionDurationDays = durationDays;
        user.subscriptionApprovedBy = req.user._id;
        user.subscriptionApprovedAt = now;
        await user.save();

        notification.isActioned = true;
        notification.isRead = true;
        await notification.save();

        return res.status(200).json({
            success: true,
            message: `User approved. Subscription active for ${durationDays} days (until ${endDate.toDateString()}).`,
            data: {
                userId: user._id,
                planName,
                durationDays,
                startDate: now,
                endDate
            }
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to approve registration',
            error: error.message
        });
    }
};

// ─── Reject / delete user registration ────────────────────────────────────────
exports.rejectRegistration = async (req, res) => {
    try {
        const { id } = req.params; // Notification ID

        const notification = await Notification.findById(id);
        if (!notification) {
            return res.status(404).json({ success: false, message: 'Notification not found' });
        }

        // Delete user permanently so they can register again with the same credentials
        if (notification.userId) {
            await User.findByIdAndDelete(notification.userId);
        }

        notification.isActioned = true;
        notification.isRead = true;
        await notification.save();

        return res.status(200).json({
            success: true,
            message: 'Registration rejected and user account removed'
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to reject registration',
            error: error.message
        });
    }
};

