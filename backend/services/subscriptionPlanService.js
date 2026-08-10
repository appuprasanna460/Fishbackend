// services/subscriptionPlanService.js
const SubscriptionPlan = require('../models/subscriptionPlanModel');
const logger = require('../config/logger');

class SubscriptionPlanService {
    /**
     * Get active plans (public - for registration)
     */
    async getActivePlans() {
        return SubscriptionPlan.getActivePlans();
    }

    /**
     * Get all plans (Super Admin only - includes inactive)
     */
    async getAllPlans() {
        return SubscriptionPlan.getAllPlans();
    }

    /**
     * Create a new subscription plan
     */
    async createPlan(data, userId) {
        const plan = new SubscriptionPlan({
            ...data,
            createdBy: userId,
            updatedBy: userId
        });
        await plan.save();
        logger.info(`Subscription plan created: ${plan.name} by user ${userId}`);
        return plan;
    }

    /**
     * Update a subscription plan
     */
    async updatePlan(planId, data, userId) {
        const plan = await SubscriptionPlan.findOne({ _id: planId, isDeleted: false });
        if (!plan) {
            throw new Error('Subscription plan not found');
        }

        if (data.name !== undefined) plan.name = data.name.trim();
        if (data.price !== undefined) plan.price = data.price;
        if (data.duration !== undefined) {
            plan.duration = data.duration;
            plan.billingCycle = data.duration;
        }
        if (data.features !== undefined) plan.features = data.features;
        if (data.isActive !== undefined) plan.isActive = data.isActive;
        plan.updatedBy = userId;

        await plan.save();
        logger.info(`Subscription plan updated: ${plan._id}`);
        return plan;
    }

    /**
     * Toggle plan active status
     */
    async togglePlanStatus(planId, userId) {
        const plan = await SubscriptionPlan.findOne({ _id: planId, isDeleted: false });
        if (!plan) {
            throw new Error('Subscription plan not found');
        }

        plan.isActive = !plan.isActive;
        plan.updatedBy = userId;
        await plan.save();
        logger.info(`Subscription plan status toggled: ${plan._id} -> ${plan.isActive}`);
        return plan;
    }

    /**
     * Delete a subscription plan (soft delete)
     */
    async deletePlan(planId) {
        const plan = await SubscriptionPlan.findOne({ _id: planId, isDeleted: false });
        if (!plan) {
            throw new Error('Subscription plan not found');
        }

        plan.isDeleted = true;
        plan.isActive = false;
        await plan.save();
        logger.info(`Subscription plan deleted: ${planId}`);
        return plan;
    }
}

module.exports = new SubscriptionPlanService();