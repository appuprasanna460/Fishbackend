// services/subscriptionService.js
const User = require('../models/usermodel');
const SubscriptionPlan = require('../models/subscriptionPlanModel');
const RenewalRequest = require('../models/renewalRequestModel');
const Notification = require('../models/notificationmodel');
const logger = require('../config/logger');

class SubscriptionService {
    /**
     * Helper: calculate remaining days from a date
     */
    _remainingDays(endDate) {
        if (!endDate) return 0;
        const now = new Date();
        const diff = new Date(endDate).getTime() - now.getTime();
        return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
    }

    /**
     * Helper: compute subscription status from endDate
     */
    _computeStatus(endDate, currentStatus) {
        if (!endDate) return currentStatus || 'NONE';
        const remaining = this._remainingDays(endDate);
        if (remaining === 0) return 'EXPIRED';
        if (remaining <= 3) return 'EXPIRING_SOON';
        return 'ACTIVE';
    }

    /**
     * Get current user's subscription details
     */
    async getMySubscription(userId) {
        const user = await User.findById(userId)
            .select('name subscriptionPlan subscriptionPlanId subscriptionPlanName subscriptionDurationDays subscriptionStatus subscriptionStartDate subscriptionEndDate subscriptionApprovedAt subscriptionApprovedBy isActive isApproved')
            .lean();

        if (!user) throw new Error('User not found');

        const remaining = this._remainingDays(user.subscriptionEndDate);
        const computedStatus = this._computeStatus(user.subscriptionEndDate, user.subscriptionStatus);

        // Check for pending renewal request
        const pendingRenewal = await RenewalRequest.findOne({
            userId,
            status: 'PENDING'
        }).lean();

        return {
            planName: user.subscriptionPlanName || user.subscriptionPlan || 'None',
            planId: user.subscriptionPlanId || null,
            status: computedStatus,
            startDate: user.subscriptionStartDate || null,
            expiryDate: user.subscriptionEndDate || null,
            durationDays: user.subscriptionDurationDays || null,
            remainingDays: remaining,
            isActive: user.isActive,
            pendingRenewal: pendingRenewal ? {
                id: pendingRenewal._id,
                requestedPlanName: pendingRenewal.requestedPlanName,
                requestedDurationDays: pendingRenewal.requestedDurationDays,
                requestedAt: pendingRenewal.requestedAt,
                status: pendingRenewal.status
            } : null
        };
    }

    /**
     * Create a renewal request
     * Prevents duplicate PENDING requests for the same user
     */
    async createRenewalRequest(userId, requestedPlanId) {
        // Check for existing pending request
        const existing = await RenewalRequest.findOne({ userId, status: 'PENDING' });
        if (existing) {
            throw new Error('You already have a pending renewal request. Please wait for approval.');
        }

        // Fetch the requested plan
        const plan = await SubscriptionPlan.findOne({ _id: requestedPlanId, isActive: true, isDeleted: false });
        if (!plan) throw new Error('Selected plan not found or no longer active');

        // Get user info for notification message
        const user = await User.findById(userId).select('name subscriptionPlanName subscriptionEndDate').lean();
        if (!user) throw new Error('User not found');

        // Create the renewal request
        const request = await RenewalRequest.create({
            userId,
            requestedPlanId: plan._id,
            requestedPlanName: plan.name,
            requestedDurationDays: plan.durationDays,
            status: 'PENDING',
            requestedAt: new Date()
        });

        // Notify all Super Admins
        const superAdmins = await User.find({ role: 'SUPER_ADMIN', isActive: true, isDeleted: false }).select('_id').lean();
        const notifications = superAdmins.map(admin => ({
            userId: admin._id,
            type: 'RENEWAL_REQUEST',
            title: 'Subscription Renewal Request',
            message: `${user.name} has requested to renew with the ${plan.name} plan for ${plan.durationDays} days.`,
            relatedId: request._id,
            relatedType: 'RENEWAL_REQUEST'
        }));
        if (notifications.length > 0) {
            await Notification.insertMany(notifications);
        }

        logger.info(`Renewal request created: userId=${userId} planId=${plan._id}`);
        return request;
    }

    /**
     * Get renewal request status for a user
     */
    async getMyRenewalStatus(userId) {
        const request = await RenewalRequest.findOne({ userId })
            .sort({ requestedAt: -1 })
            .lean();
        return request;
    }

    /**
     * Get all pending renewal requests (Super Admin)
     */
    async getAllRenewalRequests() {
        return RenewalRequest.find({ status: 'PENDING' })
            .populate('userId', 'name email subscriptionPlanName subscriptionEndDate subscriptionStatus')
            .populate('requestedPlanId', 'name durationDays')
            .sort({ requestedAt: -1 })
            .lean();
    }

    /**
     * Approve a renewal request
     * Date logic:
     *   - If current plan is still valid → newExpiry = currentExpiry + durationDays
     *   - If expired → newExpiry = approvalDate + durationDays
     */
    async approveRenewal(requestId, approvedById) {
        const request = await RenewalRequest.findById(requestId);
        if (!request) throw new Error('Renewal request not found');
        if (request.status !== 'PENDING') throw new Error('Renewal request is no longer pending');

        // Fetch the plan to read authoritative durationDays (never trust client)
        const plan = await SubscriptionPlan.findById(request.requestedPlanId);
        if (!plan) throw new Error('Requested plan no longer exists');

        // Fetch user
        const user = await User.findById(request.userId);
        if (!user) throw new Error('User not found');

        const now = new Date();
        let newStartDate, newEndDate;

        // Date logic: preserve remaining days if still valid
        if (user.subscriptionEndDate && user.subscriptionEndDate > now) {
            // Renewing before expiry — extend from current expiry
            newStartDate = user.subscriptionStartDate || now;
            newEndDate = new Date(user.subscriptionEndDate);
            newEndDate.setDate(newEndDate.getDate() + plan.durationDays);
        } else {
            // Expired or no subscription — start fresh from approval date
            newStartDate = now;
            newEndDate = new Date(now);
            newEndDate.setDate(newEndDate.getDate() + plan.durationDays);
        }

        // Activate the new subscription
        user.subscriptionPlanId = plan._id;
        user.subscriptionPlanName = plan.name;
        user.subscriptionDurationDays = plan.durationDays;
        user.subscriptionPlan = plan.name;  // backward compat
        user.subscriptionStartDate = newStartDate;
        user.subscriptionEndDate = newEndDate;
        user.subscriptionStatus = 'ACTIVE';
        user.subscriptionApprovedBy = approvedById;
        user.subscriptionApprovedAt = now;
        user.isActive = true;
        user.isApproved = true;
        await user.save();

        // Mark request approved
        request.status = 'APPROVED';
        request.approvedAt = now;
        request.approvedBy = approvedById;
        await request.save();

        // Mark related Super Admin notifications as actioned
        await Notification.updateMany(
            { relatedId: request._id, type: 'RENEWAL_REQUEST' },
            { isActioned: true, isRead: true }
        );

        // Notify the user
        await Notification.create({
            userId: request.userId,
            type: 'RENEWAL_APPROVED',
            title: 'Renewal Approved',
            message: `Your renewal request for the ${plan.name} plan (${plan.durationDays} days) has been approved. Your subscription is now active until ${newEndDate.toDateString()}.`,
            relatedId: request._id,
            relatedType: 'RENEWAL_REQUEST'
        });

        logger.info(`Renewal approved: requestId=${requestId} userId=${request.userId} newExpiry=${newEndDate}`);
        return { request, newEndDate, planName: plan.name };
    }

    /**
     * Reject a renewal request
     */
    async rejectRenewal(requestId, rejectedById, reason) {
        const request = await RenewalRequest.findById(requestId);
        if (!request) throw new Error('Renewal request not found');
        if (request.status !== 'PENDING') throw new Error('Renewal request is no longer pending');

        const now = new Date();
        request.status = 'REJECTED';
        request.rejectedAt = now;
        request.rejectedBy = rejectedById;
        request.rejectionReason = reason || 'No reason provided';
        await request.save();

        // Mark Super Admin notifications as actioned
        await Notification.updateMany(
            { relatedId: request._id, type: 'RENEWAL_REQUEST' },
            { isActioned: true, isRead: true }
        );

        // Notify the user
        await Notification.create({
            userId: request.userId,
            type: 'RENEWAL_REJECTED',
            title: 'Renewal Request Rejected',
            message: `Your renewal request for the ${request.requestedPlanName} plan has been rejected. Reason: ${request.rejectionReason}`,
            relatedId: request._id,
            relatedType: 'RENEWAL_REQUEST'
        });

        logger.info(`Renewal rejected: requestId=${requestId} by userId=${rejectedById}`);
        return request;
    }

    /**
     * Get billing/payment history (approved renewal requests)
     */
    async getBillingHistory(userId) {
        return RenewalRequest.find({ userId, status: 'APPROVED' })
            .populate('requestedPlanId')
            .sort({ approvedAt: -1 })
            .lean();
    }
}

module.exports = new SubscriptionService();
