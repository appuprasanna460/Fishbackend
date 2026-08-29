const express = require('express');
const router = express.Router();
const Booking = require('../models/bookingmodel');
const { authenticate } = require('../middleware/authmiddleware');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

router.use(authenticate);

// 1. Get agent dashboard stats
router.get('/dashboard', async (req, res) => {
    try {
        const agentId = req.query.agentId || (req.user.role === 'COMMISSION_AGENT' ? req.user._id : null);
        if (!agentId) {
            return errorResponse(res, 400, 'agentId is required');
        }

        const totalBookedBoats = await Booking.countDocuments({
            agentId,
            status: { $in: ['PENDING_APPROVAL', 'BOOKED', 'CONFIRMED'] },
            isDeleted: false
        });

        successResponse(res, 200, 'Agent dashboard stats retrieved successfully', { totalBookedBoats });
    } catch (error) {
        logger.error('Get agent dashboard stats error:', error);
        errorResponse(res, 500, error.message || 'Failed to retrieve dashboard statistics');
    }
});

module.exports = router;
