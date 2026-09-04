const Voyage = require('../models/voyageModel');
const Catch = require('../models/catchModel');
const VoyageIncome = require('../models/voyageIncomeModel');
const VoyageOtherIncome = require('../models/voyageOtherIncomeModel');
const VoyageFinancialExpense = require('../models/voyageFinancialExpenseModel');
const VoyageCrewSettlement = require('../models/voyageCrewSettlementModel');
const Boat = require('../models/boatmodel');
const Crew = require('../models/crewModel');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const safeFormatDate = (date) => {
    if (!date) return 'Draft Date';
    const d = new Date(date);
    if (isNaN(d.getTime())) return 'Draft Date';
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
};

const safeFormatVoyageNo = (voyage) => {
    if (!voyage) return 'VOY-DRAFT';
    if (voyage.voyageNo) {
        const v = voyage.voyageNo.toString();
        return v.startsWith('VOY-') ? v : `VOY-${v.replace(/^#/, '')}`;
    }
    const shortId = voyage._id ? voyage._id.toString().substring(18).toUpperCase() : 'DRAFT';
    return `VOY-${shortId}`;
};

/**
 * Helper to compute P&L statistics for a list of voyages
 */
const computeVoyagesPL = async (voyages) => {
    const voyageIds = voyages.map(v => v._id);

    // Fetch related records in batch
    const incomes = await VoyageIncome.find({ voyageId: { $in: voyageIds } });
    const otherIncomes = await VoyageOtherIncome.find({ voyageId: { $in: voyageIds } });
    const expenses = await VoyageFinancialExpense.find({ voyageId: { $in: voyageIds } });
    const crewSettlements = await VoyageCrewSettlement.find({ voyageId: { $in: voyageIds } });

    // Group items by voyage ID
    const incomesMap = {};
    const otherIncomesMap = {};
    const expensesMap = {};
    const crewSettlementsMap = {};

    voyageIds.forEach(id => {
        incomesMap[id] = [];
        otherIncomesMap[id] = [];
        expensesMap[id] = [];
        crewSettlementsMap[id] = [];
    });

    incomes.forEach(inc => incomesMap[inc.voyageId]?.push(inc));
    otherIncomes.forEach(oth => otherIncomesMap[oth.voyageId]?.push(oth));
    expenses.forEach(exp => expensesMap[exp.voyageId]?.push(exp));
    crewSettlements.forEach(sett => crewSettlementsMap[sett.voyageId]?.push(sett));

    // Map each voyage to its P&L details
    return voyages.map(voyage => {
        const vId = voyage._id;
        
        // 1. Calculate Income
        const catchIncTotal = incomesMap[vId].reduce((sum, item) => sum + (item.amount || 0), 0);
        const otherIncTotal = otherIncomesMap[vId].reduce((sum, item) => sum + (item.amount || 0), 0);
        const totalIncome = catchIncTotal + otherIncTotal;

        // 2. Calculate Expenses
        const voyageExpTotal = expensesMap[vId].reduce((sum, item) => sum + (item.amount || 0), 0);
        const crewSettTotal = crewSettlementsMap[vId]
            .reduce((sum, item) => sum + (item.paidAmount !== undefined && item.paidAmount > 0 ? item.paidAmount : (item.paid ? (item.advance || 0) : 0)), 0);
        const totalExpenses = voyageExpTotal + crewSettTotal;

        // 3. Profit calculations
        const netProfit = totalIncome - totalExpenses;
        const profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

        return {
            voyage,
            totalIncome,
            totalExpenses,
            netProfit,
            profitMargin
        };
    });
};

/**
 * Financial Dashboard
 */
const getFinancialDashboard = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const { period, startDate, endDate } = req.query;

        // Determine date range
        let start = new Date();
        let end = new Date();
        const now = new Date();

        if (period === 'This Year') {
            start = new Date(now.getFullYear(), 0, 1);
            end = new Date(now.getFullYear(), 11, 31, 23, 59, 59);
        } else if (period === 'Custom' && startDate && endDate) {
            start = new Date(startDate);
            end = new Date(endDate);
            end.setHours(23, 59, 59, 999);
        } else {
            // Default to 'This Month'
            start = new Date(now.getFullYear(), now.getMonth(), 1);
            end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
        }

        // Fetch matching voyages
        const voyages = await Voyage.find({
            ownerId,
            departureDate: { $gte: start, $lte: end },
            isDeleted: false
        }).populate('boatId', 'boatName boatNumber');

        if (voyages.length === 0) {
            return successResponse(res, 200, 'No financial records in selected date range', {
                summary: { totalIncome: 0, totalExpenses: 0, netProfit: 0, profitMargin: 0 },
                voyageStats: { total: 0, completed: 0, active: 0, cancelled: 0 },
                chartData: [],
                topProfitVoyage: null,
                topExpenseCategory: null,
                recentVoyages: []
            });
        }

        const voyagesPL = await computeVoyagesPL(voyages);

        // 1. Core Summary Cards Calculations
        let totalIncome = 0;
        let totalExpenses = 0;

        voyagesPL.forEach(item => {
            totalIncome += item.totalIncome;
            totalExpenses += item.totalExpenses;
        });

        const netProfit = totalIncome - totalExpenses;
        const profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

        // 2. Voyage Stats
        let completed = 0;
        let active = 0;
        let cancelled = 0;
        let planned = 0;

        voyages.forEach(v => {
            if (v.status === 'COMPLETED') completed++;
            else if (v.status === 'ACTIVE') active++;
            else if (v.status === 'CANCELLED') cancelled++;
            else planned++;
        });

        // 3. Chart Data (Dynamic Aggregation by Date)
        // Sort voyages by date to keep chart chronologically ordered
        const sortedPL = [...voyagesPL].sort((a, b) => a.voyage.departureDate - b.voyage.departureDate);
        const chartData = sortedPL.map(item => {
            const dateStr = item.voyage.departureDate.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
            return {
                date: dateStr,
                income: item.totalIncome,
                expenses: item.totalExpenses,
                profit: item.netProfit
            };
        });

        // 4. Top Profit Voyage
        let topProfitItem = null;
        voyagesPL.forEach(item => {
            if (item.voyage.status === 'COMPLETED' && (!topProfitItem || item.netProfit > topProfitItem.netProfit)) {
                topProfitItem = item;
            }
        });
        const topProfitVoyage = topProfitItem ? {
            id: topProfitItem.voyage._id,
            voyageNo: safeFormatVoyageNo(topProfitItem.voyage),
            profit: topProfitItem.netProfit
        } : null;

        // 5. Top Expense Category
        const voyageIds = voyages.map(v => v._id);
        const expenses = await VoyageFinancialExpense.find({ voyageId: { $in: voyageIds } });
        const crewSettlements = await VoyageCrewSettlement.find({ voyageId: { $in: voyageIds }, paid: true });

        const expenseCategories = {};
        expenses.forEach(exp => {
            const name = exp.expenseName;
            expenseCategories[name] = (expenseCategories[name] || 0) + (exp.amount || 0);
        });

        // Add crew settlements as a category
        const crewSettTotal = crewSettlements.reduce((sum, item) => sum + (item.advance || 0), 0);
        if (crewSettTotal > 0) {
            expenseCategories['Crew Settlement'] = crewSettTotal;
        }

        let topExpenseName = null;
        let topExpenseAmount = 0;
        Object.entries(expenseCategories).forEach(([name, amt]) => {
            if (amt > topExpenseAmount) {
                topExpenseName = name;
                topExpenseAmount = amt;
            }
        });
        const topExpenseCategory = topExpenseName ? {
            category: topExpenseName,
            amount: topExpenseAmount
        } : null;

        // 6. Recent Voyages (max 5)
        const recentPL = [...voyagesPL]
            .sort((a, b) => {
                const dA = a.voyage.departureDate ? new Date(a.voyage.departureDate).getTime() : 0;
                const dB = b.voyage.departureDate ? new Date(b.voyage.departureDate).getTime() : 0;
                return dB - dA;
            })
            .slice(0, 5)
            .map(item => {
                const dateStr = safeFormatDate(item.voyage.departureDate);
                return {
                    id: item.voyage._id,
                    voyageNo: safeFormatVoyageNo(item.voyage),
                    date: dateStr,
                    income: item.totalIncome,
                    expenses: item.totalExpenses,
                    profit: item.netProfit,
                    status: item.voyage.status
                };
            });

        return successResponse(res, 200, 'Financial dashboard data retrieved successfully', {
            summary: {
                totalIncome,
                totalExpenses,
                netProfit,
                profitMargin
            },
            voyageStats: {
                total: voyages.length,
                completed,
                active,
                cancelled,
                planned
            },
            chartData,
            topProfitVoyage,
            topExpenseCategory,
            recentVoyages: recentPL
        });
    } catch (error) {
        logger.error('Error fetching financial dashboard:', error);
        return errorResponse(res, 500, 'Failed to fetch financial dashboard data');
    }
};

/**
 * Voyage P&L List
 */
const getVoyagesPLList = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const voyages = await Voyage.find({ ownerId, isDeleted: false })
            .populate('boatId', 'boatName boatNumber')
            .sort({ departureDate: -1 });

        const voyagesPL = await computeVoyagesPL(voyages);

        const list = voyagesPL.map(item => {
            const dateStr = safeFormatDate(item.voyage.departureDate);
            const endStr = item.voyage.endDate ? safeFormatDate(item.voyage.endDate) : 'Open';
            return {
                id: item.voyage._id,
                voyageNo: safeFormatVoyageNo(item.voyage),
                boatName: item.voyage.boatId?.boatName || 'Unassigned Boat',
                dateRange: `${dateStr} – ${endStr}`,
                income: item.totalIncome,
                expenses: item.totalExpenses,
                profit: item.netProfit,
                profitMargin: item.profitMargin,
                status: item.voyage.status
            };
        });

        return successResponse(res, 200, 'Voyage P&L list retrieved successfully', list);
    } catch (error) {
        logger.error('Error fetching Voyage P&L list:', error);
        return errorResponse(res, 500, 'Failed to fetch Voyage P&L list');
    }
};

/**
 * Voyage P&L Summary (Tab details)
 */
const getVoyagePLSummary = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const { voyageId } = req.params;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false })
            .populate('boatId')
            .populate('captainId', 'name role')
            .populate('crewMembers', 'name role');

        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        // 1. INCOME TAB: Aggregated catch weights + user rates
        const catches = await Catch.find({ voyageId });
        const catchAggregation = {};
        catches.forEach(c => {
            catchAggregation[c.species] = (catchAggregation[c.species] || 0) + c.weight;
        });

        const voyageIncomes = await VoyageIncome.find({ voyageId });
        const incomesMap = {};
        voyageIncomes.forEach(inc => {
            incomesMap[inc.speciesName] = inc;
        });

        const catchIncomeList = Object.entries(catchAggregation).map(([speciesName, qty]) => {
            const savedInc = incomesMap[speciesName];
            const rate = savedInc ? savedInc.rate : 0;
            const amount = qty * rate;
            return {
                speciesName,
                quantity: qty,
                unit: 'kg',
                rate,
                amount
            };
        });

        const otherIncomeList = await VoyageOtherIncome.find({ voyageId });

        // 2. EXPENSES TAB: Standard supplies + custom expenses
        const dbExpenses = await VoyageFinancialExpense.find({ voyageId });
        const expensesMap = {};
        dbExpenses.forEach(exp => {
            expensesMap[exp.expenseName] = exp;
        });

        // Pre-populate standard items if they do not exist
        const savedFuelExp = expensesMap['Fuel'];
        const fuelQty = voyage.supplies?.fuelToCarry || 0;
        const fuelTotalAmt = (voyage.supplies?.totalAmount > 0) 
            ? voyage.supplies.totalAmount 
            : (savedFuelExp ? savedFuelExp.amount : 0);
        const fuelRate = savedFuelExp ? savedFuelExp.rate : (fuelQty > 0 ? (fuelTotalAmt / fuelQty) : 0);

        const savedIceExp = expensesMap['Ice'];
        const iceQty = voyage.supplies?.iceToCarry || 0;
        const iceTotalAmt = (voyage.supplies?.iceAmount > 0)
            ? voyage.supplies.iceAmount
            : (savedIceExp ? savedIceExp.amount : 0);
        const iceRate = (voyage.supplies?.iceRate > 0)
            ? voyage.supplies.iceRate
            : (savedIceExp ? savedIceExp.rate : (iceQty > 0 ? (iceTotalAmt / iceQty) : 0));

        const savedWaterExp = expensesMap['Water'];
        const waterQty = voyage.supplies?.water || 0;
        const waterTotalAmt = (voyage.supplies?.waterAmount > 0)
            ? voyage.supplies.waterAmount
            : (savedWaterExp ? savedWaterExp.amount : 0);
        const waterRate = (voyage.supplies?.waterRate > 0)
            ? voyage.supplies.waterRate
            : (savedWaterExp ? savedWaterExp.rate : (waterQty > 0 ? (waterTotalAmt / waterQty) : 0));

        const standardExpenses = [
            { name: 'Fuel', qty: fuelQty, unit: 'Ltrs', rate: fuelRate, amount: fuelTotalAmt },
            { name: 'Ice', qty: iceQty, unit: 'Kgs', rate: iceRate, amount: iceTotalAmt },
            { name: 'Water', qty: waterQty, unit: 'Ltrs', rate: waterRate, amount: waterTotalAmt }
        ];

        const expenseList = [];
        standardExpenses.forEach(item => {
            const savedExp = expensesMap[item.name];
            const rate = item.rate !== undefined ? item.rate : (savedExp ? savedExp.rate : 0);
            const amount = item.amount !== undefined ? item.amount : (item.qty * rate);
            expenseList.push({
                _id: savedExp ? savedExp._id : null,
                expenseName: item.name,
                quantity: item.qty,
                unit: item.unit,
                rate,
                amount,
                isCustom: false
            });
        });

        // Add custom items
        dbExpenses.forEach(exp => {
            if (exp.isCustom) {
                expenseList.push(exp);
            }
        });

        // 3. CREW TAB: settlements
        const dbSettlements = await VoyageCrewSettlement.find({ voyageId });
        const settlementsMap = {};
        dbSettlements.forEach(sett => {
            settlementsMap[sett.crewMemberId.toString()] = sett;
        });

        const crewList = [];
        
        // Add Captain
        if (voyage.captainId) {
            const capId = voyage.captainId._id.toString();
            const savedSett = settlementsMap[capId];
            crewList.push({
                crewMemberId: voyage.captainId._id,
                crewMemberName: voyage.captainId.name,
                role: 'Captain',
                advance: savedSett ? savedSett.advance : 0,
                paidAmount: savedSett ? (savedSett.paidAmount !== undefined ? savedSett.paidAmount : (savedSett.paid ? savedSett.advance : 0)) : 0,
                paid: savedSett ? savedSett.paid : false
            });
        }

        // Add Crew members
        if (voyage.crewMembers && voyage.crewMembers.length > 0) {
            voyage.crewMembers.forEach(member => {
                const memberId = member._id.toString();
                const savedSett = settlementsMap[memberId];
                crewList.push({
                    crewMemberId: member._id,
                    crewMemberName: member.name,
                    role: member.role || 'Crew',
                    advance: savedSett ? savedSett.advance : 0,
                    paidAmount: savedSett ? (savedSett.paidAmount !== undefined ? savedSett.paidAmount : (savedSett.paid ? savedSett.advance : 0)) : 0,
                    paid: savedSett ? savedSett.paid : false
                });
            });
        }

        // 4. SUMMARY Calculations
        const catchIncomeTotal = catchIncomeList.reduce((sum, item) => sum + item.amount, 0);
        const otherIncomeTotal = otherIncomeList.reduce((sum, item) => sum + (item.amount || 0), 0);
        const totalIncome = catchIncomeTotal + otherIncomeTotal;

        const voyageExpensesTotal = expenseList.reduce((sum, item) => sum + item.amount, 0);
        const crewSettlementTotal = crewList
            .filter(c => c.paid)
            .reduce((sum, item) => sum + item.advance, 0);
        const totalExpenses = voyageExpensesTotal + crewSettlementTotal;

        const netProfit = totalIncome - totalExpenses;
        const profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

        const voyageNo = `VOY-${voyage.departureDate.getFullYear()}-${(voyage.departureDate.getMonth() + 1).toString().padStart(2, '0')}-${voyage.departureDate.getDate().toString().padStart(2, '0')}`;

        return successResponse(res, 200, 'Voyage P&L summary fetched successfully', {
            voyage: {
                id: voyage._id,
                voyageNo,
                vesselName: voyage.boatId?.boatName || 'Unassigned',
                vesselNumber: voyage.boatId?.boatNumber || '',
                captainName: voyage.captainId?.name || 'Unassigned',
                departureDate: voyage.departureDate,
                departureTime: voyage.departureTime,
                arrivalDate: voyage.endDate,
                status: voyage.status,
                durationDays: voyage.endDate ? Math.ceil((new Date(voyage.endDate) - new Date(voyage.departureDate)) / (1000 * 60 * 60 * 24)) : 0
            },
            summary: {
                totalIncome,
                totalExpenses,
                netProfit,
                profitMargin,
                voyageExpensesTotal,
                crewSettlementTotal
            },
            income: {
                catchIncome: catchIncomeList,
                otherIncome: otherIncomeList
            },
            expenses: expenseList,
            crew: crewList
        });
    } catch (error) {
        logger.error('Error fetching Voyage P&L summary:', error);
        return errorResponse(res, 500, 'Failed to fetch Voyage P&L details');
    }
};

/**
 * Upsert Catch Rates
 */
const upsertCatchRates = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const { rates } = req.body; // Array: [{ speciesName, quantity, rate }]

        if (!rates || !Array.isArray(rates)) {
            return errorResponse(res, 400, 'Rates array is required');
        }

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        for (const item of rates) {
            const { speciesName, quantity, rate } = item;
            const amount = (quantity || 0) * (rate || 0);

            await VoyageIncome.findOneAndUpdate(
                { voyageId, speciesName },
                {
                    voyageId,
                    speciesName,
                    quantity: quantity || 0,
                    rate: rate || 0,
                    amount
                },
                { upsert: true, new: true }
            );
        }

        return successResponse(res, 200, 'Catch rates updated successfully');
    } catch (error) {
        logger.error('Error updating catch rates:', error);
        return errorResponse(res, 500, 'Failed to update catch rates');
    }
};

/**
 * Add Other Income
 */
const addOtherIncome = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const { incomeName, amount } = req.body;

        if (!incomeName || amount === undefined) {
            return errorResponse(res, 400, 'Income name and amount are required');
        }

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const otherInc = new VoyageOtherIncome({
            voyageId,
            incomeName,
            amount: parseFloat(amount)
        });

        await otherInc.save();

        return successResponse(res, 201, 'Other income added successfully', otherInc);
    } catch (error) {
        logger.error('Error adding other income:', error);
        return errorResponse(res, 500, 'Failed to add other income');
    }
};

/**
 * Delete Other Income
 */
const deleteOtherIncome = async (req, res) => {
    try {
        const { voyageId, id } = req.params;

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        await VoyageOtherIncome.findOneAndDelete({ _id: id, voyageId });

        return successResponse(res, 200, 'Other income deleted successfully');
    } catch (error) {
        logger.error('Error deleting other income:', error);
        return errorResponse(res, 500, 'Failed to delete other income');
    }
};

/**
 * Upsert Voyage Expenses (Standard supply rates)
 */
const upsertVoyageExpenses = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const { expenses } = req.body; // Array: [{ expenseName, quantity, unit, rate }]

        if (!expenses || !Array.isArray(expenses)) {
            return errorResponse(res, 400, 'Expenses array is required');
        }

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        for (const item of expenses) {
            const { expenseName, quantity, unit, rate } = item;
            const amount = (quantity || 0) * (rate || 0);

            await VoyageFinancialExpense.findOneAndUpdate(
                { voyageId, expenseName },
                {
                    voyageId,
                    expenseName,
                    quantity: quantity || 0,
                    unit: unit || '',
                    rate: rate || 0,
                    amount,
                    isCustom: false
                },
                { upsert: true, new: true }
            );
        }

        return successResponse(res, 200, 'Voyage expenses updated successfully');
    } catch (error) {
        logger.error('Error updating voyage expenses:', error);
        return errorResponse(res, 500, 'Failed to update voyage expenses');
    }
};

/**
 * Add Custom Expense
 */
const addCustomExpense = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const { expenseName, quantity, unit, rate } = req.body;

        if (!expenseName || quantity === undefined || !unit || rate === undefined) {
            return errorResponse(res, 400, 'Expense name, quantity, unit and rate are required');
        }

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const amount = parseFloat(quantity) * parseFloat(rate);

        const customExp = new VoyageFinancialExpense({
            voyageId,
            expenseName,
            quantity: parseFloat(quantity),
            unit,
            rate: parseFloat(rate),
            amount,
            isCustom: true
        });

        await customExp.save();

        return successResponse(res, 201, 'Custom expense added successfully', customExp);
    } catch (error) {
        logger.error('Error adding custom expense:', error);
        return errorResponse(res, 500, 'Failed to add custom expense');
    }
};

/**
 * Delete Custom Expense
 */
const deleteCustomExpense = async (req, res) => {
    try {
        const { voyageId, id } = req.params;

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        await VoyageFinancialExpense.findOneAndDelete({ _id: id, voyageId, isCustom: true });

        return successResponse(res, 200, 'Custom expense deleted successfully');
    } catch (error) {
        logger.error('Error deleting custom expense:', error);
        return errorResponse(res, 500, 'Failed to delete custom expense');
    }
};

/**
 * Upsert Crew Settlement
 */
const upsertCrewSettlement = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const { settlements } = req.body; // Array: [{ crewMemberId, crewMemberName, role, advance, paid }]

        if (!settlements || !Array.isArray(settlements)) {
            return errorResponse(res, 400, 'Settlements array is required');
        }

        const ownerId = req.user._id;
        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        for (const item of settlements) {
            const { crewMemberId, crewMemberName, role, advance, paidAmount, paid } = item;
            const parsedPaidAmt = paidAmount !== undefined ? parseFloat(paidAmount || 0) : (paid ? parseFloat(advance || 0) : 0);

            await VoyageCrewSettlement.findOneAndUpdate(
                { voyageId, crewMemberId },
                {
                    voyageId,
                    crewMemberId,
                    crewMemberName,
                    role,
                    advance: parseFloat(advance || 0),
                    paidAmount: parsedPaidAmt,
                    paid: !!paid
                },
                { upsert: true, new: true }
            );
        }

        return successResponse(res, 200, 'Crew settlements updated successfully');
    } catch (error) {
        logger.error('Error updating crew settlements:', error);
        return errorResponse(res, 500, 'Failed to update crew settlements');
    }
};

module.exports = {
    getFinancialDashboard,
    getVoyagesPLList,
    getVoyagePLSummary,
    upsertCatchRates,
    addOtherIncome,
    deleteOtherIncome,
    upsertVoyageExpenses,
    addCustomExpense,
    deleteCustomExpense,
    upsertCrewSettlement
};
