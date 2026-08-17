const Haul = require('../models/haulModel');

class GpsTrackService {
    // Get GPS tracks for a voyage
    async getTracksByVoyage(voyageId, ownerId) {
        const hauls = await Haul.find({ voyageId, ownerId })
            .select('haulNumber fishingGround gpsTrack startedAt endedAt duration distance')
            .sort({ haulNumber: 1 })
            .lean();
            
        return hauls.map(haul => ({
            haulId: haul._id,
            haulNumber: haul.haulNumber,
            fishingGround: haul.fishingGround,
            startedAt: haul.startedAt,
            endedAt: haul.endedAt,
            duration: haul.duration,
            distance: haul.distance,
            gpsTrack: haul.gpsTrack
        }));
    }

    // Get GPS tracks for a haul
    async getTracksByHaul(haulId, ownerId) {
        const haul = await Haul.findOne({ _id: haulId, ownerId })
            .select('gpsTrack')
            .lean();
            
        if (!haul) {
            throw new Error('Haul not found or access denied');
        }
        
        return haul.gpsTrack;
    }

    // Get GPS tracks with date filters
    async getTracks(ownerId, filters = {}) {
        const query = { ownerId };
        
        if (filters.voyageId) {
            query.voyageId = filters.voyageId;
        }

        if (filters.dateRange) {
            try {
                const { from, to } = JSON.parse(filters.dateRange);
                query.startedAt = {
                    $gte: new Date(from),
                    $lte: new Date(to)
                };
            } catch (e) {
                // Ignore parse error
            }
        }

        return await Haul.find(query)
            .populate('voyageId', 'boatId departureDate status')
            .populate('boatId', 'boatName registrationNumber')
            .select('voyageId boatId haulNumber fishingGround startedAt endedAt distance duration gpsTrack')
            .sort({ startedAt: -1 })
            .lean();
    }

    // Get track summary (distance, duration, etc.) for a voyage
    async getTrackSummary(voyageId, ownerId) {
        const hauls = await Haul.find({ voyageId, ownerId })
            .select('distance duration')
            .lean();
            
        let totalDistance = 0;
        let totalDuration = 0; // in minutes
        
        hauls.forEach(haul => {
            totalDistance += (haul.distance || 0);
            totalDuration += (haul.duration || 0);
        });
        
        return {
            totalDistance: parseFloat(totalDistance.toFixed(2)),
            totalDuration,
            numberOfHauls: hauls.length
        };
    }
}

module.exports = new GpsTrackService();
