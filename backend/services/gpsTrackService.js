const Haul = require('../models/haulModel');
const Voyage = require('../models/voyageModel');

class GpsTrackService {
    // Get GPS track history for all completed voyages with summary data
    async getTrackHistory(ownerId, filters = {}) {
        const query = { ownerId, status: { $in: ['STOPPED', 'COMPLETED'] } };

        // Date filtering
        if (filters.period) {
            const now = new Date();
            let fromDate;

            switch (filters.period) {
                case 'today':
                    fromDate = new Date(now);
                    fromDate.setHours(0, 0, 0, 0);
                    break;
                case 'week':
                    fromDate = new Date(now);
                    fromDate.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
                    fromDate.setHours(0, 0, 0, 0);
                    break;
                case 'month':
                    fromDate = new Date(now.getFullYear(), now.getMonth(), 1);
                    break;
                default:
                    fromDate = null;
            }

            if (fromDate) {
                query.startedAt = { $gte: fromDate };
            }
        }

        if (filters.voyageId) {
            query.voyageId = filters.voyageId;
        }

        if (filters.boatId) {
            query.boatId = filters.boatId;
        }

        // Get hauls with GPS tracks, grouped by voyage
        const hauls = await Haul.find(query)
            .populate('voyageId', 'boatId departureDate status')
            .populate('boatId', 'boatName registrationNumber')
            .select('voyageId boatId haulNumber fishingGround startLocation gpsTrack startedAt endedAt duration distance averageSpeed status')
            .sort({ startedAt: -1 })
            .lean();

        // Group hauls by voyage for a cleaner history view
        const voyageMap = new Map();

        for (const haul of hauls) {
            const voyageId = haul.voyageId?._id?.toString() || haul.voyageId?.toString();
            if (!voyageId) continue;

            if (!voyageMap.has(voyageId)) {
                const voyage = haul.voyageId;
                voyageMap.set(voyageId, {
                    voyageId,
                    boatId: haul.boatId?._id?.toString() || haul.boatId?.toString(),
                    boatName: haul.boatId?.boatName || 'Unknown Boat',
                    boatNumber: haul.boatId?.registrationNumber || haul.boatId?.boatNumber || '',
                    date: haul.startedAt,
                    startTime: haul.startedAt,
                    endTime: haul.endedAt,
                    duration: haul.duration || 0,
                    distanceNm: haul.distance || 0,
                    status: haul.status,
                    startLocation: haul.startLocation || null,
                    endLocation: haul.gpsTrack && haul.gpsTrack.length > 0
                        ? haul.gpsTrack[haul.gpsTrack.length - 1]
                        : null,
                    hauls: [],
                    track: haul.gpsTrack || []
                });
            }

            const entry = voyageMap.get(voyageId);
            entry.hauls.push({
                haulId: haul._id,
                haulNumber: haul.haulNumber,
                fishingGround: haul.fishingGround,
                startedAt: haul.startedAt,
                endedAt: haul.endedAt,
                duration: haul.duration,
                distance: haul.distance,
                averageSpeed: haul.averageSpeed,
                status: haul.status
            });

            // Merge track points from all hauls in this voyage
            if (haul.gpsTrack && haul.gpsTrack.length > 0) {
                entry.track = [...entry.track, ...haul.gpsTrack];
            }
        }

        // Convert to array and sort by date descending
        const result = Array.from(voyageMap.values());
        result.sort((a, b) => new Date(b.date) - new Date(a.date));

        // For the list view, limit track points to a reasonable preview size
        return result.map(v => ({
            ...v,
            // Only include a subset of track points for the list preview (max 50 points)
            trackPreview: v.track.length > 50 ? v.track.filter((_, i) => i % Math.ceil(v.track.length / 50) === 0) : v.track,
            // Full track only when explicitly requested
            track: undefined
        }));
    }

    // Get full GPS track details for a specific voyage
    async getVoyageTrackDetail(voyageId, ownerId) {
        const hauls = await Haul.find({ voyageId, ownerId })
            .populate('voyageId', 'boatId departureDate status')
            .populate('boatId', 'boatName registrationNumber')
            .select('voyageId boatId haulNumber fishingGround startLocation gpsTrack startedAt endedAt duration distance averageSpeed status')
            .sort({ startedAt: 1 })
            .lean();

        if (hauls.length === 0) {
            throw new Error('No GPS tracks found for this voyage');
        }

        const voyage = hauls[0].voyageId;
        const allTracks = [];
        let totalDistance = 0;
        let totalDuration = 0;
        let startTime = null;
        let endTime = null;
        let startLocation = null;
        let endLocation = null;

        for (const haul of hauls) {
            if (haul.gpsTrack && haul.gpsTrack.length > 0) {
                allTracks.push(...haul.gpsTrack);
            }
            totalDistance += (haul.distance || 0);
            totalDuration += (haul.duration || 0);

            if (!startTime || (haul.startedAt && haul.startedAt < startTime)) {
                startTime = haul.startedAt;
            }
            if (!endTime || (haul.endedAt && haul.endedAt > endTime)) {
                endTime = haul.endedAt;
            }
            if (!startLocation && haul.startLocation) {
                startLocation = haul.startLocation;
            }
            if (haul.gpsTrack && haul.gpsTrack.length > 0) {
                endLocation = haul.gpsTrack[haul.gpsTrack.length - 1];
            }
        }

        return {
            voyageId,
            boatId: hauls[0].boatId?._id?.toString() || hauls[0].boatId?.toString(),
            boatName: hauls[0].boatId?.boatName || 'Unknown Boat',
            boatNumber: hauls[0].boatId?.registrationNumber || hauls[0].boatId?.boatNumber || '',
            date: startTime,
            startTime,
            endTime,
            duration: totalDuration,
            distanceNm: totalDistance,
            status: hauls[0].status,
            startLocation,
            endLocation,
            hauls: hauls.map(h => ({
                haulId: h._id,
                haulNumber: h.haulNumber,
                fishingGround: h.fishingGround,
                startedAt: h.startedAt,
                endedAt: h.endedAt,
                duration: h.duration,
                distance: h.distance,
                averageSpeed: h.averageSpeed,
                status: h.status
            })),
            track: allTracks
        };
    }

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
