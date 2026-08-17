const haulService = require('../services/haulService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const startHaul = async (req, res) => {
    try {
        const haul = await haulService.startHaul(req.body, req.user._id);
        successResponse(res, 201, 'Haul started successfully', haul);
    } catch (error) {
        logger.error('Start haul error:', error);
        errorResponse(res, 400, error.message || 'Failed to start haul');
    }
};

const getHauls = async (req, res) => {
    try {
        const hauls = await haulService.getHauls(req.user._id, req.query);
        successResponse(res, 200, 'Hauls retrieved successfully', hauls);
    } catch (error) {
        logger.error('Get hauls error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve hauls');
    }
};

const getActiveHaul = async (req, res) => {
    try {
        const { voyageId } = req.query; // typically passed as a query param or param
        if (!voyageId) {
            return errorResponse(res, 400, 'Voyage ID is required');
        }
        const haul = await haulService.getActiveHaul(voyageId);
        successResponse(res, 200, 'Active haul retrieved successfully', haul);
    } catch (error) {
        logger.error('Get active haul error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve active haul');
    }
};

const getHaulById = async (req, res) => {
    try {
        const haul = await haulService.getHaulById(req.params.id, req.user._id);
        successResponse(res, 200, 'Haul retrieved successfully', haul);
    } catch (error) {
        logger.error('Get haul by ID error:', error);
        errorResponse(res, 404, error.message || 'Haul not found');
    }
};

const updateGpsTrack = async (req, res) => {
    try {
        const haul = await haulService.updateGpsTrack(req.params.id, req.body, req.user._id);
        successResponse(res, 200, 'GPS track updated successfully', haul);
    } catch (error) {
        logger.error('Update GPS track error:', error);
        errorResponse(res, 400, error.message || 'Failed to update GPS track');
    }
};

const stopHaul = async (req, res) => {
    try {
        const haul = await haulService.stopHaul(req.params.id, req.user._id);
        successResponse(res, 200, 'Haul stopped successfully', haul);
    } catch (error) {
        logger.error('Stop haul error:', error);
        errorResponse(res, 400, error.message || 'Failed to stop haul');
    }
};

const getRecentHauls = async (req, res) => {
    try {
        const { limit } = req.query;
        const hauls = await haulService.getRecentHauls(req.user._id, limit);
        successResponse(res, 200, 'Recent hauls retrieved successfully', hauls);
    } catch (error) {
        logger.error('Get recent hauls error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve recent hauls');
    }
};

module.exports = {
    startHaul,
    getHauls,
    getActiveHaul,
    getHaulById,
    updateGpsTrack,
    stopHaul,
    getRecentHauls
};
