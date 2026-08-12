// controllers/subscriptionController.js
const subscriptionService = require('../services/subscriptionService');
const subscriptionPlanService = require('../services/subscriptionPlanService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

// ─── GET /api/subscription/my ─────────────────────────────────────────────────
// Returns current user's subscription status + pending renewal request
exports.getMySubscription = async (req, res) => {
    try {
        const data = await subscriptionService.getMySubscription(req.user._id);
        return successResponse(res, 200, 'Subscription details fetched', data);
    } catch (error) {
        logger.error('getMySubscription error:', error);
        return errorResponse(res, 500, error.message);
    }
};

// ─── GET /api/subscription/plans ─────────────────────────────────────────────
// Returns all active plans (used by plan selection screen)
exports.getActivePlans = async (req, res) => {
    try {
        const plans = await subscriptionPlanService.getActivePlans();
        return successResponse(res, 200, 'Active plans fetched', plans);
    } catch (error) {
        logger.error('getActivePlans error:', error);
        return errorResponse(res, 500, error.message);
    }
};

// ─── POST /api/subscription/renewal ──────────────────────────────────────────
// Creates a new renewal request for the logged-in user
exports.createRenewalRequest = async (req, res) => {
    try {
        const { planId } = req.body;
        if (!planId) {
            return errorResponse(res, 400, 'planId is required');
        }

        const request = await subscriptionService.createRenewalRequest(req.user._id, planId);
        return successResponse(res, 201, 'Renewal request submitted. Awaiting admin approval.', {
            requestId: request._id,
            planName: request.requestedPlanName,
            durationDays: request.requestedDurationDays,
            status: request.status
        });
    } catch (error) {
        logger.error('createRenewalRequest error:', error);
        return errorResponse(res, 400, error.message);
    }
};

// ─── GET /api/subscription/renewal/status ────────────────────────────────────
// Returns the most recent renewal request status for the logged-in user
exports.getMyRenewalStatus = async (req, res) => {
    try {
        const request = await subscriptionService.getMyRenewalStatus(req.user._id);
        return successResponse(res, 200, 'Renewal status fetched', request);
    } catch (error) {
        logger.error('getMyRenewalStatus error:', error);
        return errorResponse(res, 500, error.message);
    }
};

// ─── GET /api/subscription/renewals (Super Admin) ────────────────────────────
// Returns all pending renewal requests
exports.getRenewalRequests = async (req, res) => {
    try {
        const requests = await subscriptionService.getAllRenewalRequests();
        return successResponse(res, 200, 'Renewal requests fetched', requests);
    } catch (error) {
        logger.error('getRenewalRequests error:', error);
        return errorResponse(res, 500, error.message);
    }
};

// ─── POST /api/subscription/renewals/:id/approve (Super Admin) ───────────────
exports.approveRenewal = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await subscriptionService.approveRenewal(id, req.user._id);
        return successResponse(res, 200, `Renewal approved. Subscription active until ${result.newEndDate.toDateString()}.`, {
            planName: result.planName,
            newEndDate: result.newEndDate
        });
    } catch (error) {
        logger.error('approveRenewal error:', error);
        return errorResponse(res, 400, error.message);
    }
};

// ─── POST /api/subscription/renewals/:id/reject (Super Admin) ────────────────
exports.rejectRenewal = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        await subscriptionService.rejectRenewal(id, req.user._id, reason);
        return successResponse(res, 200, 'Renewal request rejected');
    } catch (error) {
        logger.error('rejectRenewal error:', error);
        return errorResponse(res, 400, error.message);
    }
};
