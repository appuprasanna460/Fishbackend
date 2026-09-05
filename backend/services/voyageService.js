const Voyage = require('../models/voyageModel');
const VoyageDraft = require('../models/voyageDraftModel');
const Crew = require('../models/crewModel');
const Boat = require('../models/boatmodel');
const Bill = require('../models/billmodel');
const VoyageFinancialExpense = require('../models/voyageFinancialExpenseModel');

class VoyageService {
    // ---- DRAFT LOGIC ----
    async saveDraft(data, ownerId) {
        let draft = await VoyageDraft.findOne({ ownerId });
        if (draft) {
            draft.draftData = data;
        } else {
            draft = new VoyageDraft({ ownerId, draftData: data });
        }
        await draft.save();
        return draft;
    }

    async getDraft(ownerId) {
        return await VoyageDraft.findOne({ ownerId });
    }

    async deleteDraft(ownerId) {
        return await VoyageDraft.findOneAndDelete({ ownerId });
    }
    // ---------------------

    // Create a new voyage (auto-assigns ownerId from logged-in user)
    async createVoyage(data, ownerId) {
        if (!data.endDate && data.departureDate && data.expectedDuration) {
            const endDate = new Date(data.departureDate);
            if (data.expectedDuration === '5-7_DAYS') {
                endDate.setDate(endDate.getDate() + 7);
            } else if (data.expectedDuration === '8-9_DAYS') {
                endDate.setDate(endDate.getDate() + 9);
            } else {
                endDate.setDate(endDate.getDate() + 7);
            }
            data.endDate = endDate;
        }

        const targetStatus = data.status || 'PLANNED';
        delete data.status;

        const voyage = new Voyage({
            status: targetStatus,
            ...data,
            ownerId
        });
        voyage.status = targetStatus;

        await voyage.save();
        console.log('=== VOYAGE CREATED === id:', voyage._id, 'status:', voyage.status);
        await this._syncFuelExpenses(voyage);

        // Lock crew members availability ONLY if not in DRAFT status
        if (voyage.status !== 'DRAFT') {
            const allAssignedCrew = [voyage.captainId, ...voyage.crewMembers].filter(Boolean);
            if (allAssignedCrew.length > 0) {
                await Crew.updateMany(
                    { _id: { $in: allAssignedCrew } },
                    { 
                        $set: { 
                            isAvailable: false, 
                            assignedTo: { 
                                voyageId: voyage._id, 
                                boatId: voyage.boatId, 
                                assignedAt: new Date() 
                            } 
                        } 
                    }
                );
            }
        }

        return voyage;
    }

    // Get all voyages for a Boat Owner with filters
    async getVoyages(ownerId, filters = {}) {
        const query = { ownerId, isDeleted: false };

        if (filters.status) {
            query.status = filters.status;
        }

        if (filters.boatId) {
            query.boatId = filters.boatId;
        }

        if (filters.dateRange) {
            const { from, to } = JSON.parse(filters.dateRange);
            query.departureDate = {
                $gte: new Date(from),
                $lte: new Date(to)
            };
        }

        if (filters.search) {
            // Find boats matching search to filter by boat names
            const matchingBoats = await Boat.find({
                ownerId,
                boatName: { $regex: filters.search, $options: 'i' },
                isDeleted: false
            }).select('_id');
            const boatIds = matchingBoats.map(b => b._id);

            query.$or = [
                { boatId: { $in: boatIds } },
                { notes: { $regex: filters.search, $options: 'i' } }
            ];
        }

        return await Voyage.find(query)
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('captainId', 'name phone location')
            .populate('crewMembers', 'name phone role')
            .populate('departureHarbour', 'name')
            .populate('targetSpecies', 'name pricePerKg')
            .sort({ departureDate: -1 })
            .lean();
    }

    // Get a single voyage by ID (with ownership check)
    async getVoyageById(id, ownerId) {
        const voyage = await Voyage.findOne({ _id: id, ownerId, isDeleted: false })
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('captainId', 'name phone location experience notes')
            .populate('crewMembers', 'name phone role location age experience notes')
            .populate('departureHarbour', 'name')
            .populate('targetSpecies', 'name localName category pricePerKg');

        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }
        return voyage;
    }

    // Update a voyage (with ownership check and crew availability handling)
    async updateVoyage(id, data, ownerId) {
        const voyage = await Voyage.findOne({ _id: id, ownerId, isDeleted: false });
        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }

        if (voyage.status === 'COMPLETED' || voyage.status === 'CANCELLED') {
            throw new Error('Completed or cancelled voyages cannot be edited');
        }

        const oldCrew = [
            voyage.captainId ? voyage.captainId.toString() : null, 
            ...(voyage.crewMembers || []).map(c => c ? c.toString() : null)
        ].filter(Boolean);
        
        let updateFields = {};
        
        if (voyage.status === 'ACTIVE') {
            // Limited edit for ACTIVE: notes, supplies and checklist
            const { notes, supplies, checklist } = data;
            if (notes !== undefined) updateFields.notes = notes;
            if (supplies !== undefined) updateFields.supplies = supplies;
            if (checklist !== undefined) updateFields.checklist = checklist;
        } else {
            // Full edit for DRAFT or PLANNED
            const { startedAt, completedAt, cancelledAt, ...allUpdateFields } = data;
            updateFields = allUpdateFields;
        }

        Object.assign(voyage, updateFields);

        if (data.status && ['DRAFT', 'PLANNED'].includes(data.status)) {
            voyage.status = data.status;
        }

        await voyage.save();
        console.log('=== VOYAGE UPDATED === id:', voyage._id, 'status:', voyage.status);

        if (updateFields.checklist !== undefined) {
            const VoyageChecklist = require('../models/voyageChecklistModel');
            await VoyageChecklist.findOneAndUpdate(
                { voyageId: id },
                {
                    $set: {
                        boatId: voyage.boatId,
                        ownerId,
                        checklist: updateFields.checklist
                    }
                },
                { upsert: true }
            );
        }

        // Lock/release crew members availability only if not DRAFT status
        if (voyage.status !== 'DRAFT') {
            const newCrew = [
                voyage.captainId ? voyage.captainId.toString() : null,
                ...(voyage.crewMembers || []).map(c => c ? c.toString() : null)
            ].filter(Boolean);

            // Release crew members that are no longer part of this voyage
            const releasedCrew = oldCrew.filter(c => !newCrew.includes(c));
            if (releasedCrew.length > 0) {
                await Crew.updateMany(
                    { _id: { $in: releasedCrew } },
                    { $set: { isAvailable: true, assignedTo: null } }
                );
            }

            // Lock newly assigned crew members
            const reservedCrew = newCrew.filter(c => !oldCrew.includes(c));
            if (reservedCrew.length > 0) {
                await Crew.updateMany(
                    { _id: { $in: reservedCrew } },
                    { 
                        $set: { 
                            isAvailable: false, 
                            assignedTo: { 
                                voyageId: voyage._id, 
                                boatId: voyage.boatId, 
                                assignedAt: new Date() 
                            } 
                        } 
                    }
                );
            }
        }

        await voyage.save();
        await this._syncFuelExpenses(voyage);

        return voyage;
    }

    async _syncFuelExpenses(voyage) {
        if (voyage && voyage.supplies) {
            let totalFuelAmount = voyage.supplies.totalAmount || 0;
            let totalFuelQty = voyage.supplies.fuelToCarry || 0;

            if (Array.isArray(voyage.supplies.fuelItems) && voyage.supplies.fuelItems.length > 0) {
                let calcTotalAmt = 0;
                let calcTotalQty = 0;
                for (const item of voyage.supplies.fuelItems) {
                    const itemQty = item.fuelToCarry || 0;
                    const itemAmt = item.amount || (itemQty * (item.rate || 0));
                    calcTotalAmt += itemAmt;
                    calcTotalQty += itemQty;

                    if (itemQty > 0 || itemAmt > 0) {
                        await VoyageFinancialExpense.findOneAndUpdate(
                            { voyageId: voyage._id, expenseName: `Fuel (${item.fuelType})` },
                            {
                                voyageId: voyage._id,
                                expenseName: `Fuel (${item.fuelType})`,
                                quantity: itemQty,
                                unit: 'L',
                                rate: item.rate || 0,
                                amount: itemAmt,
                                isCustom: false
                            },
                            { upsert: true, new: true }
                        );
                    }
                }
                if (calcTotalAmt > 0) totalFuelAmount = calcTotalAmt;
                if (calcTotalQty > 0) totalFuelQty = calcTotalQty;
            }

            if (totalFuelAmount > 0 || totalFuelQty > 0) {
                const avgRate = totalFuelQty > 0 ? (totalFuelAmount / totalFuelQty) : 0;
                await VoyageFinancialExpense.findOneAndUpdate(
                    { voyageId: voyage._id, expenseName: 'Fuel' },
                    {
                        voyageId: voyage._id,
                        expenseName: 'Fuel',
                        quantity: totalFuelQty,
                        unit: 'L',
                        rate: avgRate,
                        amount: totalFuelAmount,
                        isCustom: false
                    },
                    { upsert: true, new: true }
                );
            }

            // Sync Ice expense
            const iceQty = voyage.supplies.iceToCarry || 0;
            const iceRate = voyage.supplies.iceRate || 0;
            const iceAmt = voyage.supplies.iceAmount || (iceQty * iceRate);
            if (iceQty > 0 || iceAmt > 0) {
                await VoyageFinancialExpense.findOneAndUpdate(
                    { voyageId: voyage._id, expenseName: 'Ice' },
                    {
                        voyageId: voyage._id,
                        expenseName: 'Ice',
                        quantity: iceQty,
                        unit: 'Kgs',
                        rate: iceRate,
                        amount: iceAmt,
                        isCustom: false
                    },
                    { upsert: true, new: true }
                );
            }

            // Sync Water expense
            const waterQty = voyage.supplies.water || 0;
            const waterRate = voyage.supplies.waterRate || 0;
            const waterAmt = voyage.supplies.waterAmount || (waterQty * waterRate);
            if (waterQty > 0 || waterAmt > 0) {
                await VoyageFinancialExpense.findOneAndUpdate(
                    { voyageId: voyage._id, expenseName: 'Water' },
                    {
                        voyageId: voyage._id,
                        expenseName: 'Water',
                        quantity: waterQty,
                        unit: 'Ltrs',
                        rate: waterRate,
                        amount: waterAmt,
                        isCustom: false
                    },
                    { upsert: true, new: true }
                );
            }
        }
    }

    // Update voyage status (Start/Cancel/Complete)
    async updateVoyageStatus(id, status, ownerId) {
        const voyage = await Voyage.findOne({ _id: id, ownerId, isDeleted: false });
        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }

        const validTransitions = {
            'PLANNED': ['ACTIVE', 'CANCELLED'],
            'ACTIVE': ['COMPLETED', 'CANCELLED'],
            'COMPLETED': [],
            'CANCELLED': []
        };

        if (!validTransitions[voyage.status].includes(status)) {
            throw new Error(`Cannot transition voyage status from ${voyage.status} to ${status}`);
        }

        voyage.status = status;
        const allCrew = [voyage.captainId, ...voyage.crewMembers];

        if (status === 'ACTIVE') {
            if (voyage.tokenStatus && voyage.tokenStatus !== 'APPROVED') {
                throw new Error('Cannot start voyage. Harbor token approval is in progress or not requested.');
            }
            if (voyage.tokenStatus === 'APPROVED' && !voyage.tokenViewed) {
                throw new Error('Cannot start voyage. Please view the generated harbor token image first.');
            }
            voyage.startedAt = new Date();
            // Lock crew
            await Crew.updateMany(
                { _id: { $in: allCrew } },
                { 
                    $set: { 
                        isAvailable: false, 
                        assignedTo: { 
                            voyageId: voyage._id, 
                            boatId: voyage.boatId, 
                            assignedAt: new Date() 
                        } 
                    } 
                }
            );
        } else if (status === 'COMPLETED') {
            voyage.completedAt = new Date();
            // Release crew
            await Crew.updateMany(
                { _id: { $in: allCrew } },
                { $set: { isAvailable: true, assignedTo: null } }
            );
        } else if (status === 'CANCELLED') {
            voyage.cancelledAt = new Date();
            // Release crew
            await Crew.updateMany(
                { _id: { $in: allCrew } },
                { $set: { isAvailable: true, assignedTo: null } }
            );
        }

        await voyage.save();
        return voyage;
    }

    // Delete a voyage (soft delete - with ownership check)
    async deleteVoyage(id, ownerId) {
        const voyage = await Voyage.findOneAndUpdate(
            { _id: id, ownerId, isDeleted: false },
            { $set: { isDeleted: true } },
            { new: true }
        );

        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }

        // Release crew if they were locked onto this deleted voyage
        const allCrew = [voyage.captainId, ...voyage.crewMembers];
        await Crew.updateMany(
            { _id: { $in: allCrew }, 'assignedTo.voyageId': voyage._id },
            { $set: { isAvailable: true, assignedTo: null } }
        );

        return voyage;
    }

    // Get voyage statistics for dashboard
    async getVoyageStats(ownerId) {
        const activeVoyages = await Voyage.countDocuments({ ownerId, status: 'ACTIVE', isDeleted: false });
        
        // Boats at sea: count unique boats of active voyages
        const activeVoyageBoats = await Voyage.distinct('boatId', { ownerId, status: 'ACTIVE', isDeleted: false });
        const boatsAtSea = activeVoyageBoats.length;

        // Today's Sales calculation (sum confirm bills matching owner boats)
        const boats = await Boat.find({ ownerId, isDeleted: false }).select('_id').lean();
        const boatIds = boats.map(b => b._id);

        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const todayEnd = new Date();
        todayEnd.setHours(23, 59, 59, 999);

        const todayBills = await Bill.find({
            boatId: { $in: boatIds },
            billDate: { $gte: todayStart, $lte: todayEnd },
            status: 'CONFIRMED',
            isDeleted: false
        }).lean();

        const todaySales = todayBills.reduce((acc, bill) => acc + (bill.grandTotal || 0), 0);

        return {
            activeVoyages,
            boatsAtSea,
            todaySales
        };
    }

    // Get active voyages for agent
    async getActiveVoyagesForAgent(agentId) {
        const boats = await Boat.find({ agentId, isDeleted: false }).select('_id').lean();
        const boatIds = boats.map(b => b._id);

        const voyages = await Voyage.find({
            boatId: { $in: boatIds },
            status: { $in: ['ACTIVE', 'PLANNED'] },
            isDeleted: false
        })
        .populate('boatId', 'boatName boatNumber registrationNumber capacity')
        .populate('captainId', 'name phone')
        .sort({ departureDate: -1 })
        .lean();

        return voyages.map(voyage => ({
            id: voyage._id,
            voyageNo: voyage._id.toString().substring(18).toUpperCase(),
            boatId: voyage.boatId?._id,
            boatName: voyage.boatId?.boatName || '',
            boatNumber: voyage.boatId?.boatNumber || '',
            status: voyage.status,
            departureDate: voyage.departureDate,
            captainName: voyage.captainId?.name || '',
            crewCount: voyage.crewMembers ? voyage.crewMembers.length : 0
        }));
    }

    /**
     * Get voyages by generic filter query
     */
    async getVoyagesByFilter(filter) {
        return Voyage.find(filter)
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('captainId', 'name phone')
            .sort({ departureDate: -1 })
            .lean();
    }

    // ── Token Management Methods ─────────────────────────────────────────────

    async requestVoyageToken(id, ownerId) {
        const voyage = await Voyage.findOne({ _id: id, ownerId, isDeleted: false });
        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }
        voyage.tokenStatus = 'IN_PROGRESS';
        voyage.tokenRequestedAt = new Date();
        await voyage.save();
        return voyage;
    }

    async markVoyageTokenViewed(id, ownerId) {
        const voyage = await Voyage.findOne({ _id: id, ownerId, isDeleted: false });
        if (!voyage) {
            throw new Error('Voyage not found or access denied');
        }
        voyage.tokenViewed = true;
        await voyage.save();
        return voyage;
    }

    async getAdminVoyageTokens(statusFilter) {
        const query = { isDeleted: false };
        if (statusFilter) {
            query.tokenStatus = statusFilter;
        } else {
            query.tokenStatus = { $in: ['IN_PROGRESS', 'APPROVED'] };
        }

        return await Voyage.find(query)
            .populate({
                path: 'boatId',
                select: 'boatName boatNumber registrationNumber boatType imageUrl length breadth draft capacity engineType yearBuilt harbourId'
            })
            .populate('ownerId', 'name email phone companyName')
            .populate('captainId', 'name phone role experienceYears')
            .populate('crewMembers', 'name phone role')
            .populate('departureHarbour', 'name code state district')
            .sort({ tokenRequestedAt: -1, createdAt: -1 })
            .lean();
    }

    async approveVoyageToken(id, tokenImage, tokenNotes) {
        const voyage = await Voyage.findById(id);
        if (!voyage) {
            throw new Error('Voyage not found');
        }
        voyage.tokenStatus = 'APPROVED';
        voyage.tokenImage = tokenImage;
        voyage.tokenNotes = tokenNotes || '';
        voyage.tokenApprovedAt = new Date();
        voyage.tokenViewed = false; // Owner must tap to view after approval
        await voyage.save();
        return voyage;
    }
}

module.exports = new VoyageService();
