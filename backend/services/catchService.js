const Catch = require('../models/catchModel');
const Haul = require('../models/haulModel');
const haulService = require('./haulService');
const fishingGroundService = require('./fishingGroundService');
const VoyageIncome = require('../models/voyageIncomeModel');

class CatchService {
    // Create a new catch
    async createCatch(data, userId) {
        const { haulId, voyageId, species, weight, boxes, rate, sharePercentage } = data;

        if (haulId) {
            // Verify the haul exists
            const haul = await Haul.findOne({ _id: haulId });
            if (!haul) {
                throw new Error('Haul not found');
            }

            const newCatch = new Catch({
                haulId,
                voyageId: haul.voyageId,
                ownerId: haul.ownerId,
                species,
                weight,
                boxes,
                sharePercentage,
                rate: rate || 0,
                amount: (weight || 0) * (rate || 0)
            });

            await newCatch.save();

            // If the haul is STOPPED, mark it as COMPLETED now that a catch has been added
            if (haul.status === 'STOPPED') {
                try {
                    await haulService.completeHaul(haulId, haul.ownerId);
                } catch (error) {
                    console.error('Failed to complete haul after adding catch:', error);
                }
            }

            // Update fishing ground total catch
            try {
                await fishingGroundService.updateTotalCatch(haul.ownerId, haul.fishingGround, weight);
            } catch (error) {
                console.error('Failed to update fishing ground total catch:', error);
            }

            return newCatch;
        } else {
            // Voyage level catch
            const Voyage = require('../models/voyageModel');
            const voyage = await Voyage.findById(voyageId);
            if (!voyage) {
                throw new Error('Voyage not found');
            }

            const newCatch = new Catch({
                voyageId,
                ownerId: voyage.ownerId,
                species,
                weight,
                boxes,
                rate: rate || 0,
                amount: (weight || 0) * (rate || 0)
            });

            await newCatch.save();
            return newCatch;
        }
    }

    // Get all catches for a haul
    async getCatchesByHaul(haulId, ownerId) {
        return await Catch.find({ haulId, ownerId }).sort({ createdAt: -1 }).lean();
    }

    // Get catches by voyage
    async getCatchesByVoyage(voyageId) {
        const catches = await Catch.find({ voyageId }).sort({ createdAt: -1 }).lean();
        const voyageIncomes = await VoyageIncome.find({ voyageId });
        const incomesMap = {};
        voyageIncomes.forEach(inc => {
            incomesMap[inc.speciesName] = inc;
        });

        return catches.map(c => {
            const savedInc = incomesMap[c.species];
            if (savedInc && savedInc.rate > 0) {
                return {
                    ...c,
                    rate: savedInc.rate,
                    amount: (c.weight || 0) * savedInc.rate
                };
            }
            return c;
        });
    }

    // Update catch rate
    async updateCatchRate(catchId, rate) {
        const singleCatch = await Catch.findById(catchId);
        if (!singleCatch) {
            throw new Error('Catch not found');
        }

        singleCatch.rate = rate;
        singleCatch.amount = (singleCatch.weight || 0) * rate;
        await singleCatch.save();

        return singleCatch;
    }

    // Get a single catch by ID
    async getCatchById(id, ownerId) {
        const query = { _id: id };
        if (ownerId) query.ownerId = ownerId;
        const singleCatch = await Catch.findOne(query);
        if (!singleCatch) {
            throw new Error('Catch not found');
        }
        return singleCatch;
    }

    // Update a catch
    async updateCatch(id, data, ownerId) {
        const query = { _id: id };
        if (ownerId) query.ownerId = ownerId;
        const singleCatch = await Catch.findOne(query);
        if (!singleCatch) {
            throw new Error('Catch not found');
        }

        const { species, weight, boxes, sharePercentage, rate } = data;

        // Calculate weight difference for fishing ground update
        const weightDiff = (weight !== undefined ? weight : singleCatch.weight) - singleCatch.weight;

        if (species !== undefined) singleCatch.species = species;
        if (weight !== undefined) singleCatch.weight = weight;
        if (boxes !== undefined) singleCatch.boxes = boxes;
        if (sharePercentage !== undefined) singleCatch.sharePercentage = sharePercentage;
        if (rate !== undefined) {
            singleCatch.rate = rate;
            singleCatch.amount = (weight !== undefined ? weight : singleCatch.weight) * rate;
        } else if (weight !== undefined) {
            singleCatch.amount = weight * (singleCatch.rate || 0);
        }

        await singleCatch.save();

        // Update fishing ground total catch if weight changed and haulId exists
        if (weightDiff !== 0 && singleCatch.haulId) {
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
        const query = { _id: id };
        if (ownerId) query.ownerId = ownerId;
        const singleCatch = await Catch.findOne(query);
        if (!singleCatch) {
            throw new Error('Catch not found');
        }

        // Subtract weight from fishing ground if haulId exists
        if (singleCatch.haulId) {
            try {
                const haul = await Haul.findById(singleCatch.haulId);
                if (haul) {
                    await fishingGroundService.updateTotalCatch(ownerId, haul.fishingGround, -singleCatch.weight);
                }
            } catch (error) {
                console.error('Failed to update fishing ground total catch after delete:', error);
            }
        }

        await Catch.deleteOne({ _id: id });
        return { message: 'Catch deleted successfully' };
    }

    // Get catch summary for a voyage
    async getCatchSummary(voyageId, ownerId) {
        const query = { voyageId };
        if (ownerId) query.ownerId = ownerId;
        const catches = await Catch.find(query).lean();

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

    // Full voyage catch summary: species breakdown (with share%) + per-haul breakdown
    async getCatchSummaryByVoyage(voyageId, ownerId) {
        const query = { voyageId };
        if (ownerId) query.ownerId = ownerId;
        const catches = await Catch.find(query).populate('haulId', 'haulNumber').lean();

        const totalWeight = catches.reduce((sum, c) => sum + c.weight, 0);

        // --- By species ---
        const speciesMap = {};
        for (const c of catches) {
            if (!speciesMap[c.species]) {
                speciesMap[c.species] = { weight: 0, boxes: 0 };
            }
            speciesMap[c.species].weight += c.weight;
            speciesMap[c.species].boxes += c.boxes;
        }
        const bySpecies = Object.keys(speciesMap).map(species => ({
            species,
            weight: speciesMap[species].weight,
            boxes: speciesMap[species].boxes,
            sharePercent: totalWeight > 0
                ? Math.round((speciesMap[species].weight / totalWeight) * 100)
                : 0,
        }));

        // --- By haul ---
        const haulMap = {};
        for (const c of catches) {
            const haulNum = c.haulId?.haulNumber ?? '?';
            const haulKey = `${c.haulId?._id ?? 'unknown'}`;
            if (!haulMap[haulKey]) {
                haulMap[haulKey] = { haulNumber: haulNum, weight: 0, boxes: 0 };
            }
            haulMap[haulKey].weight += c.weight;
            haulMap[haulKey].boxes += c.boxes;
        }
        const byHaul = Object.values(haulMap).map(h => ({
            haulNumber: h.haulNumber,
            weight: h.weight,
            boxes: h.boxes,
            sharePercent: totalWeight > 0 ? Math.round((h.weight / totalWeight) * 100) : 0,
        })).sort((a, b) => a.haulNumber - b.haulNumber);

        return { totalWeight, bySpecies, byHaul };
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
