const Crew = require('../models/crewModel');

class CrewService {
    // Create a new crew member
    async createCrew(data, ownerId) {
        const crew = new Crew({
            ...data,
            ownerId
        });
        await crew.save();
        return crew;
    }

    // Get all crew members for a Boat Owner with filters
    async getCrew(ownerId, filters = {}) {
        const query = { ownerId, isActive: true };

        if (filters.role) {
            query.role = filters.role;
        }

        if (filters.isAvailable !== undefined) {
            // String to boolean if passed from query
            query.isAvailable = filters.isAvailable === 'true' || filters.isAvailable === true;
        }

        if (filters.search) {
            query.name = { $regex: filters.search, $options: 'i' };
        }

        return await Crew.find(query)
            .populate('assignedTo.voyageId', 'departureDate')
            .populate('assignedTo.boatId', 'boatName')
            .sort({ name: 1 })
            .lean();
    }

    // Get a single crew member by ID
    async getCrewById(id, ownerId) {
        const crew = await Crew.findOne({ _id: id, ownerId, isActive: true })
            .populate('assignedTo.voyageId', 'departureDate')
            .populate('assignedTo.boatId', 'boatName');

        if (!crew) {
            throw new Error('Crew member not found or access denied');
        }
        return crew;
    }

    // Update a crew member
    async updateCrew(id, data, ownerId) {
        const crew = await Crew.findOne({ _id: id, ownerId, isActive: true });
        if (!crew) {
            throw new Error('Crew member not found or access denied');
        }

        // Prevent changing availability directly through regular update
        const { isAvailable, assignedTo, isActive, ...updateFields } = data;
        Object.assign(crew, updateFields);
        
        await crew.save();
        return crew;
    }

    // Toggle availability (for voyage assignment)
    async toggleAvailability(id, ownerId) {
        const crew = await Crew.findOne({ _id: id, ownerId, isActive: true });
        if (!crew) {
            throw new Error('Crew member not found or access denied');
        }

        if (crew.assignedTo && crew.assignedTo.voyageId) {
            throw new Error('Cannot toggle availability while assigned to a voyage');
        }

        crew.isAvailable = !crew.isAvailable;
        await crew.save();
        return crew;
    }

    // Soft delete a crew member
    async deleteCrew(id, ownerId) {
        const crew = await Crew.findOne({ _id: id, ownerId, isActive: true });
        if (!crew) {
            throw new Error('Crew member not found or access denied');
        }

        if (crew.assignedTo && crew.assignedTo.voyageId) {
            throw new Error('Cannot delete a crew member who is currently on a voyage');
        }

        crew.isActive = false;
        await crew.save();
        return crew;
    }

    // Get available captains (role: CAPTAIN, isAvailable: true)
    async getAvailableCaptains(ownerId) {
        return await Crew.find({ ownerId, role: 'CAPTAIN', isAvailable: true, isActive: true })
            .sort({ name: 1 })
            .lean();
    }

    // Get available crew members (role: CREW, isAvailable: true)
    async getAvailableCrew(ownerId) {
        return await Crew.find({ ownerId, role: 'CREW', isAvailable: true, isActive: true })
            .sort({ name: 1 })
            .lean();
    }
}

module.exports = new CrewService();
