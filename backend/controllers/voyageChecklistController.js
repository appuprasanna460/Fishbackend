const VoyageChecklist = require('../models/voyageChecklistModel');
const Voyage = require('../models/voyageModel');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

const getChecklist = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false }).lean();
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        let checklist = await VoyageChecklist.findOne({ voyageId, ownerId }).lean();
        if (!checklist) {
            // Fallback to checklist map on voyage model if it exists
            checklist = { checklist: voyage.checklist || {} };
        }
        successResponse(res, 200, 'Voyage checklist retrieved successfully', checklist);
    } catch (error) {
        logger.error('Get checklist error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve checklist');
    }
};

const saveChecklist = async (req, res) => {
    try {
        const { voyageId } = req.params;
        const ownerId = req.user._id;
        const { boatId, checklist } = req.body;

        const voyage = await Voyage.findOne({ _id: voyageId, ownerId, isDeleted: false });
        if (!voyage) {
            return errorResponse(res, 404, 'Voyage not found or access denied');
        }

        const voyageChecklist = await VoyageChecklist.findOneAndUpdate(
            { voyageId, ownerId },
            {
                $set: {
                    boatId,
                    checklist: checklist || {}
                }
            },
            { upsert: true, new: true, runValidators: true }
        );

        // Sync back to voyage model for backward compatibility
        voyage.checklist = checklist || {};
        await voyage.save();

        successResponse(res, 200, 'Voyage checklist saved successfully', voyageChecklist);
    } catch (error) {
        logger.error('Save checklist error:', error);
        errorResponse(res, 400, error.message || 'Failed to save checklist');
    }
};

module.exports = {
    getChecklist,
    saveChecklist
};
