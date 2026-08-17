const crewService = require('../services/crewService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const createCrew = async (req, res) => {
    try {
        const crew = await crewService.createCrew(req.body, req.user._id);
        successResponse(res, 201, 'Crew member created successfully', crew);
    } catch (error) {
        logger.error('Create crew error:', error);
        errorResponse(res, 400, error.message || 'Failed to create crew member');
    }
};

const getCrew = async (req, res) => {
    try {
        const crew = await crewService.getCrew(req.user._id, req.query);
        successResponse(res, 200, 'Crew members retrieved successfully', crew);
    } catch (error) {
        logger.error('Get crew error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve crew members');
    }
};

const getCrewById = async (req, res) => {
    try {
        const crew = await crewService.getCrewById(req.params.id, req.user._id);
        successResponse(res, 200, 'Crew member retrieved successfully', crew);
    } catch (error) {
        logger.error('Get crew by ID error:', error);
        errorResponse(res, 404, error.message || 'Crew member not found');
    }
};

const updateCrew = async (req, res) => {
    try {
        const crew = await crewService.updateCrew(req.params.id, req.body, req.user._id);
        successResponse(res, 200, 'Crew member updated successfully', crew);
    } catch (error) {
        logger.error('Update crew error:', error);
        errorResponse(res, 400, error.message || 'Failed to update crew member');
    }
};

const toggleAvailability = async (req, res) => {
    try {
        const crew = await crewService.toggleAvailability(req.params.id, req.user._id);
        successResponse(res, 200, 'Crew availability toggled successfully', crew);
    } catch (error) {
        logger.error('Toggle availability error:', error);
        errorResponse(res, 400, error.message || 'Failed to toggle availability');
    }
};

const deleteCrew = async (req, res) => {
    try {
        await crewService.deleteCrew(req.params.id, req.user._id);
        successResponse(res, 200, 'Crew member deleted successfully');
    } catch (error) {
        logger.error('Delete crew error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete crew member');
    }
};

const getAvailableCaptains = async (req, res) => {
    try {
        const captains = await crewService.getAvailableCaptains(req.user._id);
        successResponse(res, 200, 'Available captains retrieved successfully', captains);
    } catch (error) {
        logger.error('Get available captains error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve available captains');
    }
};

const getAvailableCrew = async (req, res) => {
    try {
        const crew = await crewService.getAvailableCrew(req.user._id);
        successResponse(res, 200, 'Available crew retrieved successfully', crew);
    } catch (error) {
        logger.error('Get available crew error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve available crew');
    }
};

module.exports = {
    createCrew,
    getCrew,
    getCrewById,
    updateCrew,
    toggleAvailability,
    deleteCrew,
    getAvailableCaptains,
    getAvailableCrew
};
