const catchService = require('../services/catchService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const createCatch = async (req, res) => {
    try {
        const newCatch = await catchService.createCatch(req.body, req.user._id);
        successResponse(res, 201, 'Catch recorded successfully', newCatch);
    } catch (error) {
        logger.error('Create catch error:', error);
        errorResponse(res, 400, error.message || 'Failed to record catch');
    }
};

const getCatchesByHaul = async (req, res) => {
    try {
        const catches = await catchService.getCatchesByHaul(req.params.haulId, req.user._id);
        successResponse(res, 200, 'Catches retrieved successfully', catches);
    } catch (error) {
        logger.error('Get catches by haul error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve catches');
    }
};

const getCatchById = async (req, res) => {
    try {
        const singleCatch = await catchService.getCatchById(req.params.id, req.user._id);
        successResponse(res, 200, 'Catch retrieved successfully', singleCatch);
    } catch (error) {
        logger.error('Get catch by ID error:', error);
        errorResponse(res, 404, error.message || 'Catch not found');
    }
};

const updateCatch = async (req, res) => {
    try {
        const updatedCatch = await catchService.updateCatch(req.params.id, req.body, req.user._id);
        successResponse(res, 200, 'Catch updated successfully', updatedCatch);
    } catch (error) {
        logger.error('Update catch error:', error);
        errorResponse(res, 400, error.message || 'Failed to update catch');
    }
};

const deleteCatch = async (req, res) => {
    try {
        await catchService.deleteCatch(req.params.id, req.user._id);
        successResponse(res, 200, 'Catch deleted successfully');
    } catch (error) {
        logger.error('Delete catch error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete catch');
    }
};

// Voyage-level catch summary: species breakdown + per-haul breakdown
const getCatchSummaryByVoyage = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;
        const summary = await catchService.getCatchSummaryByVoyage(voyageId, ownerId);
        successResponse(res, 200, 'Catch summary retrieved successfully', summary);
    } catch (error) {
        logger.error('Get catch summary by voyage error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve catch summary');
    }
};

const hasPendingCatch = async (req, res) => {
    try {
        const isPending = await catchService.hasPendingCatch(req.params.haulId);
        successResponse(res, 200, 'Pending catch status retrieved', { hasPendingCatch: isPending });
    } catch (error) {
        logger.error('Has pending catch error:', error);
        errorResponse(res, 500, error.message || 'Failed to check pending catch');
    }
};

module.exports = {
    createCatch,
    getCatchesByHaul,
    getCatchById,
    updateCatch,
    deleteCatch,
    hasPendingCatch,
    getCatchSummaryByVoyage
};
