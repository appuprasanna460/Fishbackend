const fishingGroundService = require('../services/fishingGroundService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const getFishingGrounds = async (req, res) => {
    try {
        const grounds = await fishingGroundService.getFishingGrounds(req.user._id);
        successResponse(res, 200, 'Fishing grounds retrieved successfully', grounds);
    } catch (error) {
        logger.error('Get fishing grounds error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve fishing grounds');
    }
};

const getFavouriteGrounds = async (req, res) => {
    try {
        const grounds = await fishingGroundService.getFavouriteGrounds(req.user._id);
        successResponse(res, 200, 'Favourite fishing grounds retrieved successfully', grounds);
    } catch (error) {
        logger.error('Get favourite grounds error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve favourite grounds');
    }
};

const toggleFavourite = async (req, res) => {
    try {
        const ground = await fishingGroundService.toggleFavourite(req.params.id, req.user._id);
        successResponse(res, 200, 'Fishing ground favourite status toggled successfully', ground);
    } catch (error) {
        logger.error('Toggle favourite ground error:', error);
        errorResponse(res, 400, error.message || 'Failed to toggle favourite status');
    }
};

const getGroundHistory = async (req, res) => {
    try {
        const history = await fishingGroundService.getGroundHistory(req.user._id, req.query);
        successResponse(res, 200, 'Fishing ground history retrieved successfully', history);
    } catch (error) {
        logger.error('Get ground history error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve fishing ground history');
    }
};

module.exports = {
    getFishingGrounds,
    getFavouriteGrounds,
    toggleFavourite,
    getGroundHistory
};
