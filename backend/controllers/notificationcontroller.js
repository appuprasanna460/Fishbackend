const Notification = require('../models/notificationmodel');
const User = require('../models/usermodel');

// Get all pending registrations for Super Admin
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ isActioned: false })
            .populate({
                path: 'userId',
                populate: {
                    path: 'harbourId',
                    model: 'Harbour',
                    select: 'name'
                }
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

// Approve user registration
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

        // Set subscription dates based on plan choice
        const startDate = new Date();
        let months = 3; // Default Quarterly
        if (user.subscriptionPlan === 'HALF_YEARLY') {
            months = 6;
        } else if (user.subscriptionPlan === 'YEARLY') {
            months = 12;
        }

        const endDate = new Date();
        endDate.setMonth(startDate.getMonth() + months);

        user.isApproved = true;
        user.isActive = true;
        user.subscriptionStartDate = startDate;
        user.subscriptionEndDate = endDate;
        await user.save();

        notification.isActioned = true;
        notification.isRead = true;
        await notification.save();

        return res.status(200).json({
            success: true,
            message: 'User approved and subscription activated successfully',
            data: user
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to approve registration',
            error: error.message
        });
    }
};

// Reject / delete user registration
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
