const voyageService = require('../services/voyageService');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const createVoyage = async (req, res) => {
    try {
        console.log('=== CREATE VOYAGE REQ BODY STATUS ===', req.body.status);
        const voyage = await voyageService.createVoyage(req.body, req.user._id);
        
        // Also delete draft since voyage is created
        await voyageService.deleteDraft(req.user._id);
        
        successResponse(res, 201, 'Voyage created successfully', voyage);
    } catch (error) {
        logger.error('Create voyage error:', error);
        errorResponse(res, 400, error.message || 'Failed to create voyage');
    }
};

// ---- DRAFT LOGIC ----
const saveDraft = async (req, res) => {
    try {
        const draft = await voyageService.saveDraft(req.body, req.user._id);
        successResponse(res, 200, 'Draft saved successfully', draft);
    } catch (error) {
        logger.error('Save draft error:', error);
        errorResponse(res, 400, error.message || 'Failed to save draft');
    }
};

const getDraft = async (req, res) => {
    try {
        const draft = await voyageService.getDraft(req.user._id);
        successResponse(res, 200, 'Draft retrieved successfully', draft ? draft.draftData : null);
    } catch (error) {
        logger.error('Get draft error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve draft');
    }
};

const deleteDraft = async (req, res) => {
    try {
        await voyageService.deleteDraft(req.user._id);
        successResponse(res, 200, 'Draft deleted successfully');
    } catch (error) {
        logger.error('Delete draft error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete draft');
    }
};
// ---------------------

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

const getActiveVoyages = async (req, res) => {
    try {
        const agentId = req.query.agentId || (['COMMISSION_AGENT', 'STAFF'].includes(req.user.role) ? (req.user.agentId || req.user._id) : null);
        if (!agentId) {
            return errorResponse(res, 400, 'agentId is required');
        }
        const voyages = await voyageService.getActiveVoyagesForAgent(agentId);
        successResponse(res, 200, 'Active voyages retrieved successfully', voyages);
    } catch (error) {
        logger.error('Get active voyages error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve active voyages');
    }
};

const getVoyagesByBoat = async (req, res) => {
    try {
        const { boatId } = req.params;
        const { status } = req.query; // e.g. ACTIVE,PLANNED
        
        let filter = { boatId, isDeleted: false };
        if (status) {
            filter.status = { $in: status.split(',') };
        }
        
        const voyages = await voyageService.getVoyagesByFilter(filter);
        successResponse(res, 200, 'Voyages retrieved successfully', voyages.map(voyage => ({
            id: voyage._id,
            voyageNo: voyage.voyageNo || voyage._id.toString().substring(18).toUpperCase(),
            boatId: voyage.boatId?._id || voyage.boatId,
            boatName: voyage.boatId?.boatName || '',
            boatNumber: voyage.boatId?.boatNumber || '',
            status: voyage.status,
            departureDate: voyage.departureDate,
            captainName: voyage.captainId?.name || '',
            crewCount: voyage.crewMembers ? voyage.crewMembers.length : 0
        })));
    } catch (error) {
        logger.error('Get voyages by boat error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve voyages');
    }
};

module.exports = {
    createVoyage,
    getVoyages,
    getVoyageById,
    updateVoyage,
    updateVoyageStatus,
    deleteVoyage,
    getVoyageStats,
    getActiveVoyages,
    getVoyagesByBoat,
    saveDraft,
    getDraft,
    deleteDraft
};
