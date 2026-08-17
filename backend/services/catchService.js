const Catch = require('../models/catchModel');
const Haul = require('../models/haulModel');
const haulService = require('./haulService');
const fishingGroundService = require('./fishingGroundService');

class CatchService {
    // Create a new catch for a haul
    async createCatch(data, ownerId) {
        const { haulId, species, weight, boxes, sharePercentage } = data;

        // Verify the haul exists and belongs to the owner
        const haul = await Haul.findOne({ _id: haulId, ownerId });
        if (!haul) {
            throw new Error('Haul not found or access denied');
        }

        // Allow adding catch to STOPPED hauls (not yet completed) or COMPLETED hauls
        if (haul.status === 'ACTIVE') {
            throw new Error('Cannot add catch to an active haul. Stop the haul first.');
        }

        const newCatch = new Catch({
            haulId,
            voyageId: haul.voyageId,
            ownerId,
            species,
            weight,
            boxes,
            sharePercentage
        });

        await newCatch.save();

        // If the haul is STOPPED, mark it as COMPLETED now that a catch has been added
        if (haul.status === 'STOPPED') {
            try {
                await haulService.completeHaul(haulId, ownerId);
            } catch (error) {
                console.error('Failed to complete haul after adding catch:', error);
            }
        }

        // Update fishing ground total catch
        try {
            await fishingGroundService.updateTotalCatch(ownerId, haul.fishingGround, weight);
        } catch (error) {
            console.error('Failed to update fishing ground total catch:', error);
        }

        return newCatch;
    }

    // Get all catches for a haul
    async getCatchesByHaul(haulId, ownerId) {
        return await Catch.find({ haulId, ownerId }).sort({ createdAt: -1 }).lean();
    }

    // Get a single catch by ID
    async getCatchById(id, ownerId) {
        const singleCatch = await Catch.findOne({ _id: id, ownerId });
        if (!singleCatch) {
            throw new Error('Catch not found or access denied');
        }
        return singleCatch;
    }

    // Update a catch
    async updateCatch(id, data, ownerId) {
        const singleCatch = await Catch.findOne({ _id: id, ownerId });
        if (!singleCatch) {
            throw new Error('Catch not found or access denied');
        }

        const { species, weight, boxes, sharePercentage } = data;

        // Calculate weight difference for fishing ground update
        const weightDiff = (weight !== undefined ? weight : singleCatch.weight) - singleCatch.weight;

        if (species !== undefined) singleCatch.species = species;
        if (weight !== undefined) singleCatch.weight = weight;
        if (boxes !== undefined) singleCatch.boxes = boxes;
        if (sharePercentage !== undefined) singleCatch.sharePercentage = sharePercentage;

        await singleCatch.save();

        // Update fishing ground total catch if weight changed
        if (weightDiff !== 0) {
            try {
                const haul = await Haul.findById(singleCatch.haulId);
                if (haul) {
                    await fishingGroundService.updateTotalCatch(ownerId, haul.fishingGround, weightDiff);
                }
            } catch (error) {
                console.error('Failed to update fishing ground total catch after edit:', error);
            }
        }

        return singleCatch;
    }

    // Delete a catch (hard delete for catches as they are transactional data entries)
    async deleteCatch(id, ownerId) {
        const singleCatch = await Catch.findOne({ _id: id, ownerId });
        if (!singleCatch) {
            throw new Error('Catch not found or access denied');
        }

        // Subtract weight from fishing ground
        try {
            const haul = await Haul.findById(singleCatch.haulId);
            if (haul) {
                await fishingGroundService.updateTotalCatch(ownerId, haul.fishingGround, -singleCatch.weight);
            }
        } catch (error) {
            console.error('Failed to update fishing ground total catch after delete:', error);
        }

        await Catch.deleteOne({ _id: id });
        return { message: 'Catch deleted successfully' };
    }

    // Get catch summary for a voyage
    async getCatchSummary(voyageId, ownerId) {
        const catches = await Catch.find({ voyageId, ownerId }).lean();

        const summary = catches.reduce((acc, curr) => {
            if (!acc[curr.species]) {
                acc[curr.species] = { weight: 0, boxes: 0 };
            }
            acc[curr.species].weight += curr.weight;
            acc[curr.species].boxes += curr.boxes;
            return acc;
        }, {});

        return Object.keys(summary).map(species => ({
            species,
            weight: summary[species].weight,
            boxes: summary[species].boxes
        }));
    }

    // Check if haul has pending catch (STOPPED or COMPLETED haul with 0 catches)
    async hasPendingCatch(haulId) {
        const haul = await Haul.findById(haulId);
        if (!haul) return false;

        // STOPPED hauls always have pending catch (need at least one catch to complete)
        // COMPLETED hauls with 0 catches also have pending catch
        if (haul.status === 'STOPPED') return true;
        if (haul.status !== 'COMPLETED') return false;

        const catchCount = await Catch.countDocuments({ haulId });
        return catchCount === 0;
    }
}

module.exports = new CatchService();
