const boatOwnerService = require('../services/boatOwnerService');
const User = require('../models/usermodel');
const { successResponse, paginatedResponse, errorResponse } = require('../utils/responseutils');
const { getPaginationParams, buildPaginationMeta } = require('../utils/paginationutils');
const logger = require('../config/logger');

// ─── Dashboard ──────────────────────────────────────────────

const getDashboard = async (req, res) => {
    try {
        const data = await boatOwnerService.getDashboard(req.user._id);
        successResponse(res, 200, 'Dashboard data retrieved successfully', data);
    } catch (error) {
        logger.error('Get dashboard error:', error);
        errorResponse(res, 500, error.message || 'Failed to get dashboard data');
    }
};

// ─── Bills ───────────────────────────────────────────────────

const getBills = async (req, res) => {
    try {
        const { page, limit, skip } = getPaginationParams(req.query);
        const result = await boatOwnerService.getBills(
            req.user._id,
            req.query,
            { page, limit, skip }
        );
        paginatedResponse(res, 200, 'Bills retrieved successfully', result.data, buildPaginationMeta(result.total, page, limit));
    } catch (error) {
        logger.error('Get bills error:', error);
        errorResponse(res, 500, error.message || 'Failed to get bills');
    }
};

const getBillById = async (req, res) => {
    try {
        const bill = await boatOwnerService.getBillById(req.params.id, req.user._id);
        successResponse(res, 200, 'Bill retrieved successfully', bill);
    } catch (error) {
        logger.error('Get bill by id error:', error);
        errorResponse(res, 404, error.message || 'Bill not found');
    }
};

// ─── Ledger ──────────────────────────────────────────────────

const getLedgerSummary = async (req, res) => {
    try {
        const summary = await boatOwnerService.getLedgerSummary(req.user._id, req.query);
        successResponse(res, 200, 'Ledger summary retrieved successfully', summary);
    } catch (error) {
        logger.error('Get ledger summary error:', error);
        errorResponse(res, 500, error.message || 'Failed to get ledger summary');
    }
};

const getLedger = async (req, res) => {
    try {
        const { page, limit, skip } = getPaginationParams(req.query);
        const result = await boatOwnerService.getLedgerEntries(
            req.user._id,
            req.query,
            { page, limit, skip }
        );
        paginatedResponse(res, 200, 'Ledger entries retrieved successfully', result.data, buildPaginationMeta(result.total, page, limit));
    } catch (error) {
        logger.error('Get ledger error:', error);
        errorResponse(res, 500, error.message || 'Failed to get ledger entries');
    }
};

const createLedgerEntry = async (req, res) => {
    try {
        const entry = await boatOwnerService.createLedgerEntry(req.user._id, req.body);
        successResponse(res, 201, 'Ledger entry created successfully', entry);
    } catch (error) {
        logger.error('Create ledger entry error:', error);
        errorResponse(res, 400, error.message || 'Failed to create ledger entry');
    }
};

const updateLedgerEntry = async (req, res) => {
    try {
        const entry = await boatOwnerService.updateLedgerEntry(req.params.id, req.user._id, req.body);
        successResponse(res, 200, 'Ledger entry updated successfully', entry);
    } catch (error) {
        logger.error('Update ledger entry error:', error);
        errorResponse(res, 400, error.message || 'Failed to update ledger entry');
    }
};

const deleteLedgerEntry = async (req, res) => {
    try {
        await boatOwnerService.deleteLedgerEntry(req.params.id, req.user._id);
        successResponse(res, 200, 'Ledger entry deleted successfully');
    } catch (error) {
        logger.error('Delete ledger entry error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete ledger entry');
    }
};

// ─── Fishing Locations ──────────────────────────────────────

const saveFishingLocation = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const { boatId, date, latitude, longitude } = req.body;

        // Validate input
        if (!boatId || !date || latitude == null || longitude == null) {
            return errorResponse(res, 400, 'Missing required fields: boatId, date, latitude, longitude');
        }

        // Validate coordinates
        if (latitude < -90 || latitude > 90) {
            return errorResponse(res, 400, 'Latitude must be between -90 and 90');
        }
        if (longitude < -180 || longitude > 180) {
            return errorResponse(res, 400, 'Longitude must be between -180 and 180');
        }

        const location = await boatOwnerService.saveFishingLocation(ownerId, req.body);
        
        successResponse(res, 200, 'Fishing location saved successfully', location);
    } catch (error) {
        logger.error('Save fishing location error:', error);
        errorResponse(res, 400, error.message || 'Failed to save fishing location');
    }
};

const getFishingLocations = async (req, res) => {
    try {
        const { page, limit, skip } = getPaginationParams(req.query);
        const result = await boatOwnerService.getFishingLocations(
            req.user._id,
            req.query,
            { page, limit, skip }
        );
        paginatedResponse(res, 200, 'Fishing locations retrieved successfully', result.data, buildPaginationMeta(result.total, page, limit));
    } catch (error) {
        logger.error('Get fishing locations error:', error);
        errorResponse(res, 500, error.message || 'Failed to get fishing locations');
    }
};

const deleteFishingLocation = async (req, res) => {
    try {
        await boatOwnerService.deleteFishingLocation(req.params.id, req.user._id);
        successResponse(res, 200, 'Fishing location deleted successfully');
    } catch (error) {
        logger.error('Delete fishing location error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete fishing location');
    }
};

// ─── Profile ─────────────────────────────────────────────────

const getProfile = async (req, res) => {
    try {
        const profile = await boatOwnerService.getProfile(req.user._id);
        successResponse(res, 200, 'Profile retrieved successfully', profile);
    } catch (error) {
        logger.error('Get profile error:', error);
        errorResponse(res, 500, error.message || 'Failed to get profile');
    }
};

/**
 * Get all team members for a boat owner
 */
const getTeamMembers = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const members = await User.find({ ownerId, isDeleted: false })
            .populate('assignedBoatId', 'name registrationNumber')
            .sort({ createdAt: -1 })
            .lean();
        successResponse(res, 200, 'Team members retrieved successfully', members);
    } catch (error) {
        logger.error('Get team members error:', error);
        errorResponse(res, 500, error.message || 'Failed to get team members');
    }
};

/**
 * Create a team member (company user) under boat owner
 */
const createTeamMember = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const { 
            name, email, password, phone, role, assignedBoatId, employeeId, joinedDate, 
            dob, address, emergencyContactName, emergencyContactRelationship, emergencyContactPhone 
        } = req.body;

        const existing = await User.findByEmail(email);
        if (existing) {
            return errorResponse(res, 400, 'A user with this email already exists');
        }

        const member = new User({
            name,
            email: email.toLowerCase().trim(),
            password: password || 'Password123!',
            phone,
            role, // CAPTAIN, CREW, MECHANIC, ACCOUNTANT
            ownerId,
            assignedBoatId: assignedBoatId || null,
            employeeId: employeeId || `EMP-${Date.now().toString().slice(-4)}`,
            joinedDate: joinedDate || new Date(),
            dateOfBirth: dob || null,
            address: address || '',
            emergencyContactName: emergencyContactName || '',
            emergencyContactRelationship: emergencyContactRelationship || '',
            emergencyContactPhone: emergencyContactPhone || '',
            isActive: true,
            isApproved: true,
        });

        await member.save();
        successResponse(res, 201, 'Team member created successfully', member);
    } catch (error) {
        logger.error('Create team member error:', error);
        errorResponse(res, 400, error.message || 'Failed to create team member');
    }
};

/**
 * Update team member details
 */
const updateTeamMember = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const memberId = req.params.id;
        const updateData = { ...req.body };

        // Verify ownership
        const member = await User.findOne({ _id: memberId, ownerId, isDeleted: false });
        if (!member) {
            return errorResponse(res, 404, 'Team member not found');
        }

        if (updateData.email) {
            const existing = await User.findOne({
                email: updateData.email.toLowerCase().trim(),
                _id: { $ne: memberId },
                isDeleted: false
            });
            if (existing) return errorResponse(res, 400, 'Email already in use');
        }

        // Prevent updating sensitive fields
        delete updateData.password;
        delete updateData.ownerId;
        delete updateData.isApproved;

        const updated = await User.findByIdAndUpdate(
            memberId,
            { $set: updateData },
            { new: true, runValidators: true }
        );

        successResponse(res, 200, 'Team member updated successfully', updated);
    } catch (error) {
        logger.error('Update team member error:', error);
        errorResponse(res, 400, error.message || 'Failed to update team member');
    }
};

/**
 * Toggle team member active/inactive status
 */
const toggleTeamMemberStatus = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const memberId = req.params.id;

        const member = await User.findOne({ _id: memberId, ownerId, isDeleted: false });
        if (!member) {
            return errorResponse(res, 404, 'Team member not found');
        }

        member.isActive = !member.isActive;
        await member.save();

        successResponse(res, 200, `Team member ${member.isActive ? 'activated' : 'deactivated'} successfully`, member);
    } catch (error) {
        logger.error('Toggle status error:', error);
        errorResponse(res, 400, error.message || 'Failed to toggle status');
    }
};

/**
 * Delete team member (soft delete)
 */
const deleteTeamMember = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const memberId = req.params.id;

        const member = await User.findOne({ _id: memberId, ownerId, isDeleted: false });
        if (!member) {
            return errorResponse(res, 404, 'Team member not found');
        }

        member.isDeleted = true;
        await member.save();

        successResponse(res, 200, 'Team member removed successfully');
    } catch (error) {
        logger.error('Delete team member error:', error);
        errorResponse(res, 400, error.message || 'Failed to delete team member');
    }
};

// ─── Exports ─────────────────────────────────────────────────

module.exports = {
    getDashboard,
    getBills,
    getBillById,
    getLedgerSummary,
    getLedger,
    createLedgerEntry,
    updateLedgerEntry,
    deleteLedgerEntry,
    saveFishingLocation,
    getFishingLocations,
    deleteFishingLocation,
    getProfile,
    getTeamMembers,
    createTeamMember,
    updateTeamMember,
    deleteTeamMember,
    toggleTeamMemberStatus
};