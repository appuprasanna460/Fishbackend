// controllers/subscriptionPlanController.js
const subscriptionPlanService = require('../services/subscriptionPlanService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

/**
 * Get active plans (public - for registration)
 */
const getActivePlans = async (req, res, next) => {
    try {
        const plans = await subscriptionPlanService.getActivePlans();
        successResponse(res, 200, 'Active subscription plans retrieved successfully', plans);
    } catch (error) {
        logger.error('Get active plans error:', error);
        errorResponse(res, 500, error.message || 'Failed to get active plans');
    }
};

/**
 * Get all plans (Super Admin only)
 */
const getAllPlans = async (req, res, next) => {
    try {
        if (req.user.role !== 'SUPER_ADMIN') {
            return errorResponse(res, 403, 'Access denied. Only Super Admin can view all plans');
        }
        const plans = await subscriptionPlanService.getAllPlans();
        successResponse(res, 200, 'Subscription plans retrieved successfully', plans);
    } catch (error) {
        logger.error('Get all plans error:', error);
        errorResponse(res, 500, error.message || 'Failed to get plans');
    }
};

/**
 * Create a new subscription plan (Super Admin only)
 */
const createPlan = async (req, res, next) => {
    try {
        if (req.user.role !== 'SUPER_ADMIN') {
            return errorResponse(res, 403, 'Access denied. Only Super Admin can create plans');
        }
        const plan = await subscriptionPlanService.createPlan(req.body, req.user._id);
        successResponse(res, 201, 'Subscription plan created successfully', plan);
    } catch (error) {
        logger.error('Create plan error:', error);
        errorResponse(res, 400, error.message || 'Failed to create plan');
    }
};

/**
 * Update a subscription plan (Super Admin only)
 */
const updatePlan = async (req, res, next) => {
    try {
        if (req.user.role !== 'SUPER_ADMIN') {
            return errorResponse(res, 403, 'Access denied. Only Super Admin can update plans');
        }
        const plan = await subscriptionPlanService.updatePlan(req.params.id, req.body, req.user._id);
        successResponse(res, 200, 'Subscription plan updated successfully', plan);
    } catch (error) {
        logger.error('Update plan error:', error);
        errorResponse(res, 400, error.message || 'Failed to update plan');
    }
};

/**
 * Toggle plan active status (Super Admin only)
 */
const togglePlanStatus = async (req, res, next) => {
    try {
        if (req.user.role !== 'SUPER_ADMIN') {
            return errorResponse(res, 403, 'Access denied. Only Super Admin can toggle plan status');
        }
        const plan = await subscriptionPlanService.togglePlanStatus(req.params.id, req.user._id);
        successResponse(res, 200, 'Subscription plan status updated successfully', plan);
    } catch (error) {
        logger.error('Toggle plan status error:', error);
        errorResponse(res, 400, error.message || 'Failed to update plan status');
    }
};

/**
 * Delete a subscription plan (Super Admin only)
 */
const deletePlan = async (req, res, next) => {
    try {
        if (req.user.role !== 'SUPER_ADMIN') {
            return errorResponse(res, 403, 'Access denied. Only Super Admin can delete plans');
        }
        await subscriptionPlanService.deletePlan(req.params.id);
        successResponse(res, 200, 'Subscription plan deleted successfully');
    } catch (error) {
        logger.error('Delete plan error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete plan');
    }
};

module.exports = {
    getActivePlans,
    getAllPlans,
    createPlan,
    updatePlan,
    togglePlanStatus,
    deletePlan
};