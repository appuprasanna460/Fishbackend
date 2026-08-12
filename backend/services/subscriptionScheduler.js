// services/subscriptionScheduler.js
const User = require('../models/usermodel');
const Notification = require('../models/notificationmodel');
const logger = require('../config/logger');

const SCHEDULER_INTERVAL_MS = 60 * 60 * 1000; // every hour

/**
 * Mark expired subscriptions as EXPIRED and deactivate users.
 * Does NOT affect SUPER_ADMIN users.
 */
async function processExpiredSubscriptions() {
    try {
        const now = new Date();

        // Find users whose subscription has expired but are still active
        const expired = await User.find({
            role: { $ne: 'SUPER_ADMIN' },
            isActive: true,
            isDeleted: false,
            subscriptionEndDate: { $lt: now, $exists: true },
            subscriptionStatus: { $in: ['ACTIVE', 'EXPIRING_SOON'] }
        }).select('_id name subscriptionPlanName subscriptionEndDate');

        if (expired.length > 0) {
            const ids = expired.map(u => u._id);
            await User.updateMany(
                { _id: { $in: ids } },
                { $set: { subscriptionStatus: 'EXPIRED', isActive: false } }
            );
            logger.info(`[Scheduler] Expired ${expired.length} subscription(s)`);
        }
    } catch (err) {
        logger.error('[Scheduler] Error processing expired subscriptions:', err);
    }
}

/**
 * Generate expiry warning notifications for 3, 2, 1 day(s) remaining.
 * Deduplicated: checks for existing notification with same relatedType + userId.
 */
async function processExpiryWarnings() {
    try {
        const now = new Date();
        const warningDays = [3, 2, 1];

        for (const days of warningDays) {
            // Users with subscription expiring in exactly `days` days
            const from = new Date(now);
            from.setDate(from.getDate() + days - 1);
            from.setHours(0, 0, 0, 0);

            const to = new Date(now);
            to.setDate(to.getDate() + days);
            to.setHours(23, 59, 59, 999);

            const usersExpiringSoon = await User.find({
                role: { $ne: 'SUPER_ADMIN' },
                isActive: true,
                isDeleted: false,
                subscriptionEndDate: { $gte: from, $lte: to },
                subscriptionStatus: { $in: ['ACTIVE', 'EXPIRING_SOON'] }
            }).select('_id name subscriptionPlanName subscriptionEndDate');

            for (const user of usersExpiringSoon) {
                const relatedTypeKey = `${days}_DAY_WARNING`;

                // Check if this warning notification already exists for this user
                const exists = await Notification.findOne({
                    userId: user._id,
                    type: 'SUBSCRIPTION_EXPIRY_WARNING',
                    relatedType: relatedTypeKey
                });

                if (!exists) {
                    const dayLabel = days === 1 ? 'tomorrow' : `in ${days} days`;
                    await Notification.create({
                        userId: user._id,
                        type: 'SUBSCRIPTION_EXPIRY_WARNING',
                        title: 'Subscription Expiring Soon',
                        message: `Your ${user.subscriptionPlanName || 'subscription'} plan expires ${dayLabel}.`,
                        relatedType: relatedTypeKey
                    });

                    // Also update subscriptionStatus to EXPIRING_SOON
                    await User.findByIdAndUpdate(user._id, {
                        subscriptionStatus: 'EXPIRING_SOON'
                    });

                    logger.info(`[Scheduler] Expiry warning (${days}d) sent to userId=${user._id}`);
                }
            }
        }
    } catch (err) {
        logger.error('[Scheduler] Error processing expiry warnings:', err);
    }
}

/**
 * Main scheduler job — runs expiry detection and warning generation
 */
async function runSchedulerJob() {
    logger.info('[Scheduler] Running subscription check...');
    await processExpiryWarnings();
    await processExpiredSubscriptions();
    logger.info('[Scheduler] Subscription check complete.');
}

/**
 * Start the scheduler.
 * Runs immediately on startup, then every SCHEDULER_INTERVAL_MS.
 */
function startSubscriptionScheduler() {
    logger.info('[Scheduler] Subscription scheduler started (interval: 1 hour)');

    // Run immediately at startup (after a short delay for DB to be ready)
    setTimeout(runSchedulerJob, 5000);

    // Then run every hour
    setInterval(runSchedulerJob, SCHEDULER_INTERVAL_MS);
}

module.exports = { startSubscriptionScheduler };
