const FishingGround = require('../models/fishingGroundModel');

class FishingGroundService {
    // Get all fishing grounds for an owner
    async getFishingGrounds(ownerId) {
        return await FishingGround.find({ ownerId })
            .sort({ name: 1 })
            .lean();
    }

    // Get favourite fishing grounds
    async getFavouriteGrounds(ownerId) {
        return await FishingGround.find({ ownerId, isFavourite: true })
            .sort({ name: 1 })
            .lean();
    }

    // Toggle favourite status
    async toggleFavourite(id, ownerId) {
        const ground = await FishingGround.findOne({ _id: id, ownerId });
        if (!ground) {
            throw new Error('Fishing ground not found or access denied');
        }

        ground.isFavourite = !ground.isFavourite;
        await ground.save();
        return ground;
    }

    // Get fishing ground history (with filters)
    async getGroundHistory(ownerId, filters = {}) {
        const query = { ownerId };

        if (filters.search) {
            query.name = { $regex: filters.search, $options: 'i' };
        }

        if (filters.dateRange) {
            try {
                const { from, to } = JSON.parse(filters.dateRange);
                query.lastUsedAt = {
                    $gte: new Date(from),
                    $lte: new Date(to)
                };
            } catch (e) {
                // Ignore parsing errors
            }
        }

        return await FishingGround.find(query)
            .sort({ lastUsedAt: -1, usedCount: -1 })
            .lean();
    }

    // Increment usage (called when haul starts)
    async incrementUsage(ownerId, groundName) {
        if (!groundName) return null;

        // Clean name
        const name = groundName.trim();
        
        let ground = await FishingGround.findOne({ ownerId, name: { $regex: new RegExp(`^${name}$`, 'i') } });

        if (!ground) {
            ground = new FishingGround({
                ownerId,
                name: name,
                usedCount: 1,
                lastUsedAt: new Date(),
                totalCatch: 0
            });
        } else {
            ground.usedCount += 1;
            ground.lastUsedAt = new Date();
        }

        await ground.save();
        return ground;
    }

    // Update total catch (called when catch added/updated/deleted)
    async updateTotalCatch(ownerId, groundName, weightDiff) {
        if (!groundName) return null;

        const name = groundName.trim();
        const ground = await FishingGround.findOne({ ownerId, name: { $regex: new RegExp(`^${name}$`, 'i') } });

        if (ground) {
            ground.totalCatch = Math.max(0, ground.totalCatch + weightDiff);
            await ground.save();
        }
        
        return ground;
    }
}

module.exports = new FishingGroundService();
