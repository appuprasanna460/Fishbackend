const exporterStaffService = require('../services/exporterStaffService');
const User = require('../models/usermodel');

const getStaffList = async (req, res, next) => {
    try {
        const staff = await exporterStaffService.listStaff(req.user.exporterId);
        return res.json({ success: true, data: staff });
    } catch (error) {
        next(error);
    }
};

const createStaff = async (req, res, next) => {
    try {
        const staff = await exporterStaffService.createStaff(req.user.exporterId, req.body);
        return res.status(201).json({ success: true, message: 'Staff created successfully', data: staff });
    } catch (error) {
        next(error);
    }
};

const updateStaff = async (req, res, next) => {
    try {
        const staff = await exporterStaffService.updateStaff(req.user.exporterId, req.params.id, req.body);
        return res.json({ success: true, message: 'Staff updated successfully', data: staff });
    } catch (error) {
        next(error);
    }
};

const toggleStaffStatus = async (req, res, next) => {
    try {
        const staff = await exporterStaffService.toggleStaffStatus(req.user.exporterId, req.params.id);
        return res.json({ success: true, message: 'Staff status updated', data: staff });
    } catch (error) {
        next(error);
    }
};

const deleteStaff = async (req, res, next) => {
    try {
        const result = await exporterStaffService.deleteStaff(req.user.exporterId, req.params.id);
        return res.json(result);
    } catch (error) {
        next(error);
    }
};

const getStaffProfile = async (req, res, next) => {
    try {
        const staff = await User.findOne({ _id: req.params.id, exporterId: req.user.exporterId, isDeleted: { $ne: true } }).select('-password');
        if (!staff) {
            return res.status(404).json({ success: false, message: 'Staff member not found' });
        }
        return res.json({ success: true, data: staff });
    } catch (error) {
        next(error);
    }
};

const uploadStaffDocument = async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No file uploaded' });
        }
        const staff = await exporterStaffService.uploadStaffDocument(req.user.exporterId, req.params.id, req.file, req.body.name);
        return res.json({ success: true, message: 'Document uploaded', data: staff });
    } catch (error) {
        next(error);
    }
};

const deleteStaffDocument = async (req, res, next) => {
    try {
        const staff = await exporterStaffService.deleteStaffDocument(req.user.exporterId, req.params.id, req.params.documentId);
        return res.json({ success: true, message: 'Document deleted', data: staff });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getStaffList,
    createStaff,
    updateStaff,
    toggleStaffStatus,
    deleteStaff,
    getStaffProfile,
    uploadStaffDocument,
    deleteStaffDocument
};
