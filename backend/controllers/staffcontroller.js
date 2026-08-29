const staffService = require('../services/staffservice');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

/**
 * Get all staff under agent
 */
const getStaffList = async (req, res) => {
    try {
        const agentId = req.query.agentId || (req.user.role === 'COMMISSION_AGENT' ? req.user._id : null);
        if (!agentId) {
            return errorResponse(res, 400, 'agentId is required');
        }

        // Commission agents can only view their own staff
        if (req.user.role === 'COMMISSION_AGENT' && req.user._id.toString() !== agentId.toString()) {
            return errorResponse(res, 403, 'Access denied. You can only view your own staff.');
        }

        const search = req.query.search || '';
        const data = await staffService.getStaffByAgent(agentId, search);
        successResponse(res, 200, 'Staff list retrieved successfully', data);
    } catch (error) {
        logger.error('Get staff list error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve staff list');
    }
};

/**
 * Create staff
 */
const createStaff = async (req, res) => {
    try {
        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : req.body.agentId;
        if (!agentId) {
            return errorResponse(res, 400, 'agentId is required');
        }

        const data = await staffService.createStaff(req.body, agentId);
        successResponse(res, 201, 'Staff member created successfully', data);
    } catch (error) {
        logger.error('Create staff error:', error);
        errorResponse(res, 400, error.message || 'Failed to create staff member');
    }
};

/**
 * Get staff profile preview
 */
const getStaffProfile = async (req, res) => {
    try {
        const { staffId } = req.params;
        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;
        
        const data = await staffService.getStaffProfile(staffId, agentId);
        successResponse(res, 200, 'Staff profile retrieved successfully', data);
    } catch (error) {
        logger.error('Get staff profile error:', error);
        errorResponse(res, 404, error.message || 'Staff profile not found');
    }
};

/**
 * Update staff
 */
const updateStaff = async (req, res) => {
    try {
        const { staffId } = req.params;
        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;

        const data = await staffService.updateStaff(staffId, req.body, agentId);
        successResponse(res, 200, 'Staff member updated successfully', data);
    } catch (error) {
        logger.error('Update staff error:', error);
        errorResponse(res, 400, error.message || 'Failed to update staff member');
    }
};

/**
 * Toggle staff status
 */
const toggleStaffStatus = async (req, res) => {
    try {
        const { staffId } = req.params;
        const { isActive } = req.body;
        if (isActive === undefined) {
            return errorResponse(res, 400, 'isActive parameter is required');
        }

        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;
        const data = await staffService.toggleStaffStatus(staffId, isActive, agentId);
        successResponse(res, 200, 'Staff status toggled successfully', data);
    } catch (error) {
        logger.error('Toggle staff status error:', error);
        errorResponse(res, 400, error.message || 'Failed to toggle staff status');
    }
};

/**
 * Delete staff (soft delete)
 */
const deleteStaff = async (req, res) => {
    try {
        const { staffId } = req.params;
        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;

        await staffService.deleteStaff(staffId, agentId);
        successResponse(res, 200, 'Staff deleted successfully');
    } catch (error) {
        logger.error('Delete staff error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete staff member');
    }
};

/**
 * Upload staff document
 */
const uploadStaffDocument = async (req, res) => {
    try {
        const { staffId } = req.params;
        const { documentName } = req.body;
        const file = req.file;

        if (!file) {
            return errorResponse(res, 400, 'No document file uploaded');
        }

        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;
        const data = await staffService.uploadDocument(staffId, file, documentName, agentId);
        successResponse(res, 201, 'Document uploaded successfully', data);
    } catch (error) {
        logger.error('Upload staff document error:', error);
        errorResponse(res, 400, error.message || 'Failed to upload staff document');
    }
};

/**
 * Delete staff document
 */
const deleteStaffDocument = async (req, res) => {
    try {
        const { staffId, documentId } = req.params;
        const agentId = req.user.role === 'COMMISSION_AGENT' ? req.user._id : null;

        await staffService.deleteDocument(staffId, documentId, agentId);
        successResponse(res, 200, 'Document deleted successfully');
    } catch (error) {
        logger.error('Delete staff document error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete staff document');
    }
};

module.exports = {
    getStaffList,
    createStaff,
    getStaffProfile,
    updateStaff,
    toggleStaffStatus,
    deleteStaff,
    uploadStaffDocument,
    deleteStaffDocument
};
