const voyageService = require('../services/voyageService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const createVoyage = async (req, res) => {
    try {
        const voyage = await voyageService.createVoyage(req.body, req.user._id);
        successResponse(res, 201, 'Voyage created successfully', voyage);
    } catch (error) {
        logger.error('Create voyage error:', error);
        errorResponse(res, 400, error.message || 'Failed to create voyage');
    }
};

const getVoyages = async (req, res) => {
    try {
        const voyages = await voyageService.getVoyages(req.user._id, req.query);
        successResponse(res, 200, 'Voyages retrieved successfully', voyages);
    } catch (error) {
        logger.error('Get voyages error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve voyages');
    }
};

const getVoyageById = async (req, res) => {
    try {
        const voyage = await voyageService.getVoyageById(req.params.id, req.user._id);
        successResponse(res, 200, 'Voyage details retrieved successfully', voyage);
    } catch (error) {
        logger.error('Get voyage by ID error:', error);
        errorResponse(res, 404, error.message || 'Voyage not found');
    }
};

const updateVoyage = async (req, res) => {
    try {
        const voyage = await voyageService.updateVoyage(req.params.id, req.body, req.user._id);
        successResponse(res, 200, 'Voyage updated successfully', voyage);
    } catch (error) {
        logger.error('Update voyage error:', error);
        errorResponse(res, 400, error.message || 'Failed to update voyage');
    }
};

const updateVoyageStatus = async (req, res) => {
    try {
        const { status } = req.body;
        if (!status) {
            return errorResponse(res, 400, 'Status is required');
        }
        const voyage = await voyageService.updateVoyageStatus(req.params.id, status, req.user._id);
        successResponse(res, 200, `Voyage status updated to ${status} successfully`, voyage);
    } catch (error) {
        logger.error('Update voyage status error:', error);
        errorResponse(res, 400, error.message || 'Failed to update voyage status');
    }
};

const deleteVoyage = async (req, res) => {
    try {
        await voyageService.deleteVoyage(req.params.id, req.user._id);
        successResponse(res, 200, 'Voyage deleted successfully');
    } catch (error) {
        logger.error('Delete voyage error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete voyage');
    }
};

const getVoyageStats = async (req, res) => {
    try {
        const stats = await voyageService.getVoyageStats(req.user._id);
        successResponse(res, 200, 'Voyage stats retrieved successfully', stats);
    } catch (error) {
        logger.error('Get voyage stats error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve voyage statistics');
    }
};

module.exports = {
    createVoyage,
    getVoyages,
    getVoyageById,
    updateVoyage,
    updateVoyageStatus,
    deleteVoyage,
    getVoyageStats
};
