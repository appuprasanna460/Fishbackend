const gpsTrackService = require('../services/gpsTrackService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const getTracksByVoyage = async (req, res) => {
    try {
        const tracks = await gpsTrackService.getTracksByVoyage(req.params.voyageId, req.user._id);
        successResponse(res, 200, 'GPS tracks retrieved successfully', tracks);
    } catch (error) {
        logger.error('Get tracks by voyage error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve GPS tracks');
    }
};

const getTracksByHaul = async (req, res) => {
    try {
        const tracks = await gpsTrackService.getTracksByHaul(req.params.haulId, req.user._id);
        successResponse(res, 200, 'GPS tracks retrieved successfully', tracks);
    } catch (error) {
        logger.error('Get tracks by haul error:', error);
        errorResponse(res, 404, error.message || 'Failed to retrieve GPS tracks or haul not found');
    }
};

const getTracks = async (req, res) => {
    try {
        const tracks = await gpsTrackService.getTracks(req.user._id, req.query);
        successResponse(res, 200, 'GPS tracks retrieved successfully', tracks);
    } catch (error) {
        logger.error('Get tracks error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve GPS tracks');
    }
};

const getTrackSummary = async (req, res) => {
    try {
        const summary = await gpsTrackService.getTrackSummary(req.params.voyageId, req.user._id);
        successResponse(res, 200, 'Track summary retrieved successfully', summary);
    } catch (error) {
        logger.error('Get track summary error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve track summary');
    }
};

const getTrackHistory = async (req, res) => {
    try {
        const history = await gpsTrackService.getTrackHistory(req.user._id, req.query);
        successResponse(res, 200, 'GPS track history retrieved successfully', history);
    } catch (error) {
        logger.error('Get track history error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve GPS track history');
    }
};

const getVoyageTrackDetail = async (req, res) => {
    try {
        const detail = await gpsTrackService.getVoyageTrackDetail(req.params.voyageId, req.user._id);
        successResponse(res, 200, 'Voyage GPS track detail retrieved successfully', detail);
    } catch (error) {
        logger.error('Get voyage track detail error:', error);
        errorResponse(res, 404, error.message || 'Failed to retrieve voyage GPS track details');
    }
};

module.exports = {
    getTracksByVoyage,
    getTracksByHaul,
    getTracks,
    getTrackSummary,
    getTrackHistory,
    getVoyageTrackDetail
};
