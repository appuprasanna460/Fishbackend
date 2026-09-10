const exporterReportService = require('../services/exporterReportService');

const getPurchaseRegister = async (req, res, next) => {
    try {
        const data = await exporterReportService.getPurchaseRegister(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getSalesRegister = async (req, res, next) => {
    try {
        const data = await exporterReportService.getSalesRegister(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getSpeciesWisePL = async (req, res, next) => {
    try {
        const data = await exporterReportService.getSpeciesWisePL(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getStaffWisePurchases = async (req, res, next) => {
    try {
        const data = await exporterReportService.getStaffWisePurchases(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getUnitWiseAnalysis = async (req, res, next) => {
    try {
        const data = await exporterReportService.getUnitWiseAnalysis(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getLotTraceability = async (req, res, next) => {
    try {
        const data = await exporterReportService.getLotTraceability(req.user.exporterId, req.params.lotId);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getReceivablesAging = async (req, res, next) => {
    try {
        const data = await exporterReportService.getReceivablesAging(req.user.exporterId);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getPayablesAging = async (req, res, next) => {
    try {
        const data = await exporterReportService.getPayablesAging(req.user.exporterId);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

const getExpenseReport = async (req, res, next) => {
    try {
        const data = await exporterReportService.getExpenseReport(req.user.exporterId, req.query);
        return res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getPurchaseRegister,
    getSalesRegister,
    getSpeciesWisePL,
    getStaffWisePurchases,
    getUnitWiseAnalysis,
    getLotTraceability,
    getReceivablesAging,
    getPayablesAging,
    getExpenseReport
};
