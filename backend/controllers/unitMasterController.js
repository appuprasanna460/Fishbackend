const unitMasterService = require('../services/unitMasterService');

const getUnits = async (req, res, next) => {
    try {
        const units = await unitMasterService.listUnits(req.user.exporterId);
        return res.json({ success: true, data: units });
    } catch (error) {
        next(error);
    }
};

const createUnit = async (req, res, next) => {
    try {
        const unit = await unitMasterService.createUnit(req.user.exporterId, req.body);
        return res.status(201).json({ success: true, message: 'Unit created successfully', data: unit });
    } catch (error) {
        next(error);
    }
};

const updateUnit = async (req, res, next) => {
    try {
        const unit = await unitMasterService.updateUnit(req.user.exporterId, req.params.id, req.body);
        return res.json({ success: true, message: 'Unit updated successfully', data: unit });
    } catch (error) {
        next(error);
    }
};

const toggleUnitStatus = async (req, res, next) => {
    try {
        const unit = await unitMasterService.toggleUnitStatus(req.user.exporterId, req.params.id);
        return res.json({ success: true, message: 'Unit status updated', data: unit });
    } catch (error) {
        next(error);
    }
};

const deleteUnit = async (req, res, next) => {
    try {
        const result = await unitMasterService.deleteUnit(req.user.exporterId, req.params.id);
        return res.json(result);
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getUnits,
    createUnit,
    updateUnit,
    toggleUnitStatus,
    deleteUnit
};
