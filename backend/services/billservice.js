const Bill = require('../models/billmodel');
const Boat = require('../models/boatmodel');
const Fish = require('../models/fishmodel');
const Ledger = require('../models/ledgermodel');
const User = require('../models/usermodel');
const Location = require('../models/locationmodel');
const SubLocation = require('../models/subLocationmodel');
const VoyageIncome = require('../models/voyageIncomeModel');
const authService = require('./authservice');
const ledgerService = require('./ledgerservice');
const { getPaginationParams, buildPaginationMeta } = require('../utils/paginationutils');
const logger = require('../config/logger');
const invoiceTemplateService = require('./invoiceTemplateService');




class BillService {
    /**
     * Generate bill number in format B-{YYYY}-{MM}-{DD}-{sequence}
     */
    async generateBillNumber() {
        const date = new Date();
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const prefix = `B-${year}-${month}-${day}`;

        // Find the highest sequence number for today
        const latestBill = await Bill.findOne({
            billNumber: { $regex: `^B-${year}-${month}-${day}-` }
        }).sort({ createdAt: -1 }).lean();

        let sequence = 1;
        if (latestBill) {
            const parts = latestBill.billNumber.split('-');
            const lastSeq = parseInt(parts[parts.length - 1]);
            if (!isNaN(lastSeq)) {
                sequence = lastSeq + 1;
            }
        }

        // Ensure uniqueness
        let billNumber = `${prefix}-${sequence}`;
        let exists = await Bill.findOne({ billNumber, isDeleted: false });

        while (exists) {
            sequence++;
            billNumber = `${prefix}-${sequence}`;
            exists = await Bill.findOne({ billNumber, isDeleted: false });
        }

        console.log(`✅ Generated unique bill number: ${billNumber}`);
        return billNumber;
    }

    /**
     * Create bill with updated schema and calculations
     */
    async createBill(data, user) {
        const {
            boatId,
            voyageId,
            buyerDetails,
            catchEntries,
            commissionPercent,
            notes,
            billDate
        } = data;

        // Validate boat
        const boat = await Boat.findOne({ _id: boatId, isDeleted: false });
        if (!boat) {
            throw new Error('Boat not found');
        }

        // Generate bill number
        const billNumber = await this.generateBillNumber();

        // Calculate totals
        let totalQuantity = 0;
        let totalAmount = 0;
        const processedCatchEntries = [];
        const processedFishEntries = [];

        if (catchEntries && Array.isArray(catchEntries)) {
            for (const entry of catchEntries) {
                const quantity = Number(entry.quantity || entry.weight || 0);
                const rate = Number(entry.rate || 0);
                const amount = quantity * rate;
                totalQuantity += quantity;
                totalAmount += amount;

                processedCatchEntries.push({
                    speciesName: entry.speciesName || entry.species || '',
                    quantity,
                    rate,
                    amount
                });

                processedFishEntries.push({
                    fishName: entry.speciesName || entry.species || '',
                    weightKg: quantity,
                    pricePerKg: rate,
                    totalAmount: amount
                });
            }
        }

        // Commission Percentage (default 2.0%, editable 0-10%)
        const commPercent = commissionPercent !== undefined ? Number(commissionPercent) : 2.0;
        if (commPercent < 0 || commPercent > 10) {
            throw new Error('Commission percentage must be between 0% and 10%');
        }

        const commissionAmount = totalAmount * (commPercent / 100);
        const netAmount = totalAmount - commissionAmount;

        // Determine agentId based on role
        let agentId;
        if (user.role === 'COMMISSION_AGENT') {
            agentId = user._id;
        } else if (user.role === 'STAFF') {
            agentId = user.agentId;
        } else {
            agentId = data.agentId || user._id;
        }

        // Handle billDate
        let billDateObj = new Date();
        if (billDate) {
            billDateObj = new Date(billDate);
            if (isNaN(billDateObj.getTime())) {
                throw new Error('Invalid bill date format');
            }
        }

        // Create bill
        const bill = new Bill({
            billNumber,
            boatId,
            voyageId,
            agentId,
            staffId: user.role === 'STAFF' ? user._id : undefined,
            createdBy: user._id,
            createdByRole: user.role === 'STAFF' ? 'STAFF' : 'COMMISSION_AGENT',
            buyerDetails: {
                name: buyerDetails?.name || '',
                contact: buyerDetails?.contact || '',
                lotNumber: buyerDetails?.lotNumber || ''
            },
            catchEntries: processedCatchEntries,
            fishEntries: processedFishEntries,
            subtotal: totalAmount,
            grandTotal: totalAmount,
            commissionPercent: commPercent,
            commissionAmount,
            netAmount,
            status: 'SAVED',
            notes: notes || '',
            billDate: billDateObj
        });

        await bill.save();

        // Create ledger entry using Net Amount
        const ledger = new Ledger({
            boatId,
            agentId,
            ownerId: boat.ownerId,
            billId: bill._id,
            type: 'DEBIT',
            amount: netAmount,
            balance: 0,
            description: `Bill ${billNumber} created`,
            date: billDateObj
        });

        await ledger.save();

        // Update or insert rates into VoyageIncome for this voyage
        if (voyageId && processedCatchEntries.length > 0) {
            for (const entry of processedCatchEntries) {
                let speciesId = null;
                try {
                    const fish = await Fish.findOne({ name: entry.speciesName, isDeleted: false });
                    if (fish) {
                        speciesId = fish._id;
                    }
                } catch (err) {
                    logger.error(`Error resolving fish model for species ${entry.speciesName}:`, err);
                }

                try {
                    await VoyageIncome.findOneAndUpdate(
                        { voyageId, speciesName: entry.speciesName },
                        {
                            $set: {
                                speciesId,
                                quantity: entry.quantity,
                                rate: entry.rate,
                                amount: entry.amount,
                                unit: 'kg'
                            }
                        },
                        { upsert: true, new: true }
                    );
                } catch (err) {
                    logger.error(`Failed to upsert VoyageIncome for voyage ${voyageId} and species ${entry.speciesName}:`, err);
                }
            }
        }

        // Populate references
        const populatedBill = await Bill.findById(bill._id)
            .populate('boatId', 'boatNumber boatName')
            .populate('agentId', 'name email')
            .populate('staffId', 'name email')
            .populate('createdBy', 'name email')
            .populate('voyageId', 'departureDate');

        logger.info(`Bill created: ${billNumber} for boat ${boat.boatNumber} by ${user.role}`);
        return populatedBill;
    }

    /**
     * Get bill by ID
     */
    async getBillById(billId, user) {
        const bill = await Bill.findById(billId)
            .populate({
                path: 'boatId',
                select: 'boatNumber boatName ownerId',
                populate: {
                    path: 'ownerId',
                    select: 'name email'
                }
            })
            .populate('voyageId', 'departureDate')
            .populate('agentId', 'name email')
            .populate('staffId', 'name email')
            .populate('createdBy', 'name email')
            .populate('buyerId', 'name email')
            .populate('locationId', 'name')
            .populate('subLocationId', 'name')
            .lean();

        if (!bill) {
            throw new Error('Bill not found');
        }

        if (bill.voyageId) {
            bill.voyageId.voyageNo = bill.voyageId._id.toString().substring(18).toUpperCase();
        }

        await this.checkBillAccess(bill, user);
        return bill;
    }

    /**
     * Get bills with filters and pagination (role filtered)
     */
    async getBills(filters, pagination, user) {
        const { page, limit, skip } = pagination;

        const query = { isDeleted: false };

        // Apply role filter & optional staffId query param
        if (user.role === 'STAFF') {
            query.$or = [
                { createdBy: user._id },
                { createdBy: user.agentId }
            ];
        } else if (user.role === 'COMMISSION_AGENT') {
            const User = require('../models/usermodel');
            const staff = await User.find({ agentId: user._id, role: 'STAFF', isDeleted: false }).select('_id').lean();
            const staffIds = staff.map(s => s._id);

            if (filters.filterType === 'MY_BILLS') {
                query.createdBy = user._id;
            } else if (filters.filterType === 'STAFF_BILLS') {
                query.createdByRole = 'STAFF';
                query.agentId = user._id;
                if (filters.staffId) {
                    query.staffId = filters.staffId;
                }
            } else {
                // "All Bills"
                query.$or = [
                    { agentId: user._id },
                    { staffId: { $in: staffIds } }
                ];
                if (filters.staffId) {
                    query.staffId = filters.staffId;
                }
            }
        } else if (user.role === 'BOAT_OWNER') {
            const Boat = require('../models/boatmodel');
            const ownerBoats = await Boat.find({ ownerId: user._id, isDeleted: false }).select('_id').lean();
            const boatIds = ownerBoats.map(b => b._id);
            query.boatId = { $in: boatIds };
        } else if (user.role !== 'SUPER_ADMIN') {
            query._id = null; // No access
        }

        // Apply additional filters
        if (filters.boatId) query.boatId = filters.boatId;
        if (filters.status) query.status = filters.status;
        if (filters.agentId && user.role === 'SUPER_ADMIN') query.agentId = filters.agentId;

        // Handle date filtering - Single Date OR Date Range
        if (filters.date) {
            const singleDate = new Date(filters.date);
            singleDate.setHours(0, 0, 0, 0);
            const endOfDay = new Date(singleDate);
            endOfDay.setHours(23, 59, 59, 999);
            query.billDate = { $gte: singleDate, $lte: endOfDay };
        } else {
            if (filters.fromDate) {
                query.billDate = { $gte: new Date(filters.fromDate) };
            }
            if (filters.toDate) {
                const toDate = new Date(filters.toDate);
                toDate.setHours(23, 59, 59, 999);
                query.billDate = { ...query.billDate, $lte: toDate };
            }
        }

        if (filters.search) {
            const searchQuery = [
                { billNumber: { $regex: filters.search, $options: 'i' } },
                { 'boatId.boatNumber': { $regex: filters.search, $options: 'i' } }
            ];
            if (query.$or) {
                const roleFilter = { $or: query.$or };
                delete query.$or;
                query.$and = [
                    roleFilter,
                    { $or: searchQuery }
                ];
            } else {
                query.$or = searchQuery;
            }
        }

        const [bills, total] = await Promise.all([
            Bill.find(query)
                .populate('boatId', 'boatNumber boatName')
                .populate('agentId', 'name email')
                .populate('staffId', 'name email')
                .populate('createdBy', 'name email')
                .populate('buyerId', 'name')
                .sort({ [filters.sortBy || 'billDate']: filters.sortOrder === 'asc' ? 1 : -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Bill.countDocuments(query)
        ]);

        return {
            data: bills,
            pagination: buildPaginationMeta(total, page, limit)
        };
    }

    /**
     * Update bill status
     * @param {string} billId - Bill ID
     * @param {Object} updateData - Update data
     * @param {Object} user - Current user
     * @returns {Promise<Object>} Updated bill
     */
    async updateBill(billId, updateData, user) {
        const bill = await Bill.findById(billId);
        if (!bill) {
            throw new Error('Bill not found');
        }

        // Check access
        await this.checkBillAccess(bill, user);

        // Prevent modifications to cancelled bills
        if (bill.status === 'CANCELLED') {
            throw new Error('Cannot modify cancelled bill');
        }

        // Handle status changes
        const oldStatus = bill.status;
        const newStatus = updateData.status;

        // Update fields
        Object.keys(updateData).forEach(key => {
            if (key !== 'status') {
                bill[key] = updateData[key];
            }
        });

        // Recalculate totals if fish entries changed
        if (updateData.fishEntries) {
            let subtotal = 0;
            const fishEntries = updateData.fishEntries.map(entry => {
                const totalAmount = entry.weightKg * entry.pricePerKg;
                subtotal += totalAmount;
                return {
                    ...entry,
                    totalAmount
                };
            });
            bill.fishEntries = fishEntries;
            bill.subtotal = subtotal;
            bill.commissionAmount = (subtotal * bill.commissionRate) / 100;
            bill.grandTotal = subtotal + bill.commissionAmount;
        }

        // Update status if provided
        if (newStatus) {
            bill.status = newStatus;
        }

        await bill.save();

        // Update or insert rates into VoyageIncome for this voyage
        if (bill.voyageId && updateData.fishEntries) {
            for (const entry of bill.fishEntries) {
                let speciesId = null;
                try {
                    const fish = await Fish.findOne({ name: entry.fishName, isDeleted: false });
                    if (fish) {
                        speciesId = fish._id;
                    }
                } catch (err) {
                    logger.error(`Error resolving fish model for species ${entry.fishName}:`, err);
                }

                try {
                    await VoyageIncome.findOneAndUpdate(
                        { voyageId: bill.voyageId, speciesName: entry.fishName },
                        {
                            $set: {
                                speciesId,
                                quantity: entry.weightKg,
                                rate: entry.pricePerKg,
                                amount: entry.totalAmount,
                                unit: 'kg'
                            }
                        },
                        { upsert: true, new: true }
                    );
                } catch (err) {
                    logger.error(`Failed to upsert VoyageIncome for voyage ${bill.voyageId} and species ${entry.fishName}:`, err);
                }
            }
        }

        // Handle ledger entries on status change
        if (newStatus === 'CONFIRMED' && oldStatus !== 'CONFIRMED') {
            await this.createLedgerEntries(bill);
        } else if (newStatus === 'CANCELLED' && oldStatus === 'CONFIRMED') {
            await this.reverseLedgerEntries(bill);
        }

        logger.info(`Bill updated: ${bill.billNumber} by user ${user._id}`);
        return bill;
    }

    /**
     * Delete bill (soft delete)
     * @param {string} billId - Bill ID
     * @param {Object} user - Current user
     * @returns {Promise<void>}
     */
    async deleteBill(billId, user) {
        const bill = await Bill.findById(billId);
        if (!bill) {
            throw new Error('Bill not found');
        }

        // ✅ Allow deletion of CONFIRMED bills (not just DRAFT)
        if (bill.status === 'CANCELLED') {
            throw new Error('Cannot delete cancelled bill');
        }

        bill.isDeleted = true;
        await bill.save();

        // ✅ Reverse ledger entries if bill was confirmed
        if (bill.status === 'CONFIRMED') {
            await this.reverseLedgerEntries(bill);
        }

        logger.info(`Bill deleted: ${bill.billNumber} by user ${user._id}`);
    }
    /**
     * Get bill summary by boat
     * @param {string} boatId - Boat ID
     * @param {Object} user - Current user
     * @returns {Promise<Object>} Bill summary
     */
    async getBillSummaryByBoat(boatId, user) {
        const boat = await Boat.findById(boatId);
        if (!boat) {
            throw new Error('Boat not found');
        }

        // Check access
        if (user.role !== 'SUPER_ADMIN' &&
            boat.agentId.toString() !== user._id.toString() &&
            boat.ownerId.toString() !== user._id.toString()) {
            throw new Error('Access denied');
        }

        const bills = await Bill.find({
            boatId,
            isDeleted: false,
            status: { $in: ['CONFIRMED', 'PAID'] }
        });

        const summary = {
            totalBills: bills.length,
            totalRevenue: bills.reduce((sum, b) => sum + b.grandTotal, 0),
            totalWeight: bills.reduce((sum, b) => {
                return sum + b.fishEntries.reduce((s, e) => s + e.weightKg, 0);
            }, 0),
            averageBillValue: bills.length > 0 ?
                bills.reduce((sum, b) => sum + b.grandTotal, 0) / bills.length : 0
        };

        return summary;
    }

    /**
     * Check if user has access to bill
     * @param {Object} bill - Bill document
     * @param {Object} user - Current user
     * @throws {Error} If access denied
     */
    async checkBillAccess(bill, user) {
        if (user.role === 'SUPER_ADMIN') return true;

        const getObjectIdStr = (val) => {
            if (!val) return '';
            if (typeof val === 'object' && val._id) return val._id.toString();
            return val.toString();
        };

        const userIdStr = user._id.toString();

        let hasAccess = (
            getObjectIdStr(bill.agentId) === userIdStr ||
            getObjectIdStr(bill.staffId) === userIdStr ||
            getObjectIdStr(bill.buyerId) === userIdStr
        );

        if (!hasAccess && user.role === 'BOAT_OWNER') {
            const boatOwnerId = (bill.boatId && typeof bill.boatId === 'object' && bill.boatId.ownerId)
                ? getObjectIdStr(bill.boatId.ownerId)
                : null;

            if (boatOwnerId === userIdStr) {
                hasAccess = true;
            } else {
                const Boat = require('../models/boatmodel');
                const boat = await Boat.findById(getObjectIdStr(bill.boatId)).lean();
                if (boat && boat.ownerId.toString() === userIdStr) {
                    hasAccess = true;
                }
            }
        }

        if (!hasAccess) {
            throw new Error('Access denied');
        }
    }

    /**
     * Apply role-based filter to query
     * @param {Object} query - MongoDB query object
     * @param {Object} user - Current user
     */
    async applyRoleFilter(query, user) {
        switch (user.role) {
            case 'SUPER_ADMIN':
                // No filter
                break;
            case 'COMMISSION_AGENT':
                // Commission agent sees their own bills AND bills created by their staff
                const User = require('../models/usermodel');
                const staff = await User.find({ agentId: user._id, role: 'STAFF', isActive: true, isDeleted: false }).select('_id').lean();
                const staffIds = staff.map(s => s._id);
                query.$or = [
                    { agentId: user._id },
                    { staffId: { $in: staffIds } }
                ];
                break;
            case 'STAFF':
                query.staffId = user._id;
                break;
            case 'FISH_BUYER':
                query.buyerId = user._id;
                break;
            case 'BOAT_OWNER':
                const Boat = require('../models/boatmodel');
                const ownerBoats = await Boat.find({ ownerId: user._id, isDeleted: false }).select('_id').lean();
                const boatIds = ownerBoats.map(b => b._id);
                query.boatId = { $in: boatIds };
                break;
            default:
                query._id = null; // No access
        }
    }

    /**
     * Create ledger entries for bill
     * @param {Object} bill - Bill document
     * @returns {Promise<void>}
     */
    async createLedgerEntries(bill) {
        // Get boat owner
        const boat = await Boat.findById(bill.boatId);
        if (!boat) {
            throw new Error('Boat not found');
        }

        // Create credit entry for boat owner (revenue)
        await ledgerService.createLedgerEntry({
            boatId: bill.boatId,
            agentId: bill.agentId,
            ownerId: boat.ownerId,
            billId: bill._id,
            type: 'CREDIT',
            amount: bill.grandTotal,
            description: `Bill ${bill.billNumber} - Fish sale`
        });
    }

    /**
     * Reverse ledger entries for cancelled bill
     * @param {Object} bill - Bill document
     * @returns {Promise<void>}
     */
    async reverseLedgerEntries(bill) {
        // Delete associated ledger entries
        await Ledger.deleteMany({ billId: bill._id });
        logger.info(`Ledger entries reversed for bill: ${bill.billNumber}`);
    }

    /**
     * Cancel a bill
     */
    async cancelBill(billId, user) {
        const bill = await Bill.findById(billId);
        if (!bill) {
            throw new Error('Bill not found');
        }
        await this.checkBillAccess(bill, user);

        bill.status = 'CANCELLED';
        await bill.save();

        // Reverse ledger entries
        await this.reverseLedgerEntries(bill);

        return bill;
    }

    /**
     * Get bill with invoice template
     * @param {string} billId - Bill ID
     * @param {Object} user - Current user
     * @returns {Promise<Object>} Bill with template data
     */
    async getBillWithTemplate(billId, user) {
        const bill = await this.getBillById(billId, user);

        // Get active invoice template
        const template = await invoiceTemplateService.getActiveTemplate();

        // Create a combined response
        return {
            bill: bill,
            invoiceTemplate: template
        };
    }

}


module.exports = new BillService();