const Haul = require('../models/haulModel');
const Voyage = require('../models/voyageModel');
const fishingGroundService = require('./fishingGroundService');

class HaulService {
    // Start a new haul (only for ACTIVE voyages)
    async startHaul(data, ownerId) {
        const { voyageId, fishingGround, gearType, netLength, startLocation, notes } = data;

        // Verify voyage is active
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }
        if (voyage.status !== 'ACTIVE') {
            throw new Error('Cannot start haul. Voyage must be ACTIVE.');
        }

        // Check if there is already an active or stopped haul for this voyage
        const pendingHaul = await Haul.findOne({ voyageId, status: { $in: ['ACTIVE', 'STOPPED'] } });
        if (pendingHaul) {
            if (pendingHaul.status === 'ACTIVE') {
                throw new Error('Cannot start a new haul while another haul is active on this voyage.');
            }
            throw new Error('Cannot start a new haul. Complete the stopped haul by adding a catch first.');
        }

        // Calculate next haul number
        const haulCount = await Haul.countDocuments({ voyageId });
        const haulNumber = haulCount + 1;

        const haul = new Haul({
            voyageId,
            boatId: voyage.boatId,
            ownerId,
            haulNumber,
            fishingGround,
            gearType,
            netLength,
            startLocation,
            gpsTrack: [{
                latitude: startLocation.latitude,
                longitude: startLocation.longitude,
                timestamp: new Date()
            }],
            startedAt: new Date(),
            status: 'ACTIVE',
            notes: notes || ''
        });

        await haul.save();

        // Update fishing ground statistics
        try {
            await fishingGroundService.incrementUsage(ownerId, fishingGround);
        } catch (error) {
            console.error('Failed to update fishing ground usage:', error);
            // Non-blocking error
        }

        return haul;
    }

    // Get active haul for a voyage
    async getActiveHaul(voyageId) {
        return await Haul.findOne({ voyageId, status: 'ACTIVE' }).lean();
    }

    // Get stopped haul for a voyage (stopped but not yet completed with catch)
    async getStoppedHaul(voyageId) {
        return await Haul.findOne({ voyageId, status: 'STOPPED' }).lean();
    }

    // Get all hauls for a voyage
    async getHaulsByVoyage(voyageId, ownerId) {
        return await Haul.find({ voyageId, ownerId })
            .sort({ haulNumber: -1 })
            .lean();
    }

    // Get a single haul by ID
    async getHaulById(id, ownerId) {
        const haul = await Haul.findOne({ _id: id, ownerId });
        if (!haul) {
            throw new Error('Haul not found or access denied');
        }
        return haul;
    }

    // Update GPS track (periodic updates during active haul)
    async updateGpsTrack(id, location, ownerId) {
        const haul = await Haul.findOne({ _id: id, ownerId, status: 'ACTIVE' });
        if (!haul) {
            throw new Error('Active haul not found or access denied');
        }

        haul.gpsTrack.push({
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: new Date()
        });

        await haul.save();
        return haul;
    }

    // Stop a haul (only for ACTIVE hauls) - sets status to STOPPED, not COMPLETED
    // A haul is only COMPLETED after a catch has been added
    async stopHaul(id, ownerId) {
        const haul = await Haul.findOne({ _id: id, ownerId, status: 'ACTIVE' });
        if (!haul) {
            throw new Error('Active haul not found or access denied');
        }

        const endedAt = new Date();
        const durationMs = endedAt - haul.startedAt;
        const durationMinutes = Math.floor(durationMs / 60000);

        // Approximate distance calculation from start to end (in a real app, calculate from all GPS points)
        // This is a simple placeholder - we'll just set it to 0 or calculate straight line
        const distance = this._calculateStraightLineDistance(haul.startLocation, haul.gpsTrack[haul.gpsTrack.length - 1]);

        const averageSpeed = durationMinutes > 0 ? (distance / (durationMinutes / 60)) : 0;

        haul.endedAt = endedAt;
        haul.duration = durationMinutes;
        haul.distance = parseFloat(distance.toFixed(2));
        haul.averageSpeed = parseFloat(averageSpeed.toFixed(2));
        haul.status = 'STOPPED';

        await haul.save();
        return haul;
    }

    // Complete a haul (only for STOPPED hauls) - called after a catch is added
    async completeHaul(id, ownerId) {
        const haul = await Haul.findOne({ _id: id, ownerId, status: 'STOPPED' });
        if (!haul) {
            throw new Error('Stopped haul not found or access denied');
        }

        haul.status = 'COMPLETED';
        await haul.save();
        return haul;
    }

    // Helper method for distance (Haversine formula placeholder)
    _calculateStraightLineDistance(loc1, loc2) {
        if (!loc1 || !loc2) return 0;

        const R = 6371; // Radius of the earth in km
        const dLat = this._deg2rad(loc2.latitude - loc1.latitude);
        const dLon = this._deg2rad(loc2.longitude - loc1.longitude);
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this._deg2rad(loc1.latitude)) * Math.cos(this._deg2rad(loc2.latitude)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const distance = R * c; // Distance in km
        return distance;
    }

    _deg2rad(deg) {
        return deg * (Math.PI / 180);
    }

    // Get all hauls with filters (for Fishing screen)
    async getHauls(ownerId, filters = {}) {
        const query = { ownerId };

        if (filters.voyageId) query.voyageId = filters.voyageId;
        if (filters.status) query.status = filters.status;
        if (filters.fishingGround) query.fishingGround = { $regex: filters.fishingGround, $options: 'i' };

        if (filters.dateRange) {
            try {
                const { from, to } = JSON.parse(filters.dateRange);
                query.startedAt = {
                    $gte: new Date(from),
                    $lte: new Date(to)
                };
            } catch (e) {
                // Ignore parsing errors
            }
        }

        return await Haul.find(query)
            .populate('voyageId', 'boatId departureDate status')
            .populate('boatId', 'boatName registrationNumber')
            .sort({ startedAt: -1 })
            .lean();
    }

    // Get recent hauls (for dashboard)
    async getRecentHauls(ownerId, limit = 5) {
        return await Haul.find({ ownerId })
            .populate('voyageId', 'boatId status')
            .populate('boatId', 'boatName')
            .sort({ startedAt: -1 })
            .limit(parseInt(limit))
            .lean();
    }

    // Get haul statistics
    async getHaulStats(ownerId) {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        const haulsThisMonth = await Haul.countDocuments({
            ownerId,
            startedAt: { $gte: startOfMonth }
        });

        const activeHauls = await Haul.countDocuments({ ownerId, status: 'ACTIVE' });

        return {
            haulsThisMonth,
            activeHauls
        };
    }
}

module.exports = new HaulService();
