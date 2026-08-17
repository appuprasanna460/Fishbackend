const Voyage = require('../models/voyageModel');
const Haul = require('../models/haulModel');
const Crew = require('../models/crewModel');
const logger = require('../config/logger');
// const cron = require('node-cron'); // Optional if cron library is installed, otherwise will just expose the function

// Scheduled job - runs daily at midnight (or can be triggered manually/programmatically)
const autoCompleteVoyages = async () => {
    try {
        const now = new Date();

        // Find all ACTIVE voyages where endDate <= current date
        const voyages = await Voyage.find({
            status: 'ACTIVE',
            endDate: { $lte: now },
            isDeleted: false
        });

        for (const voyage of voyages) {
            // Check if any active or stopped hauls exist
            const pendingHaul = await Haul.findOne({
                voyageId: voyage._id,
                status: { $in: ['ACTIVE', 'STOPPED'] }
            });

            if (pendingHaul) {
                // Active or stopped haul exists - log warning and skip
                logger.warn(`Voyage ${voyage._id} has pending haul ${pendingHaul._id} (${pendingHaul.status}). Cannot auto-complete.`);
                continue;
            }

            // Mark voyage as COMPLETED
            voyage.status = 'COMPLETED';
            voyage.completedAt = now;
            await voyage.save();

            // Release crew members
            const allCrewIds = [voyage.captainId, ...voyage.crewMembers];
            await Crew.updateMany(
                { _id: { $in: allCrewIds } },
                {
                    $set: {
                        isAvailable: true,
                        assignedTo: null
                    }
                }
            );

            logger.info(`Voyage ${voyage._id} auto-completed via scheduler. Crew released.`);
        }
    } catch (error) {
        logger.error('Error in autoCompleteVoyages scheduler:', error);
    }
};

// Start the scheduler using setInterval (runs every hour)
const startVoyageScheduler = () => {
    // Run immediately on startup
    autoCompleteVoyages();

    // Then run every hour (3,600,000 ms)
    setInterval(autoCompleteVoyages, 60 * 60 * 1000);
    logger.info('🗓️  Voyage auto-completion scheduler started (every 1 hour)');
};

module.exports = {
    autoCompleteVoyages,
    startVoyageScheduler
};
