const authService = require('../services/authservice');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');
const User = require('../models/usermodel');
const Notification = require('../models/notificationmodel');

/**
 * Login user
 */
const login = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        const result = await authService.login(email, password);
        successResponse(res, 200, 'Login successful', result);
    } catch (error) {
        logger.error('Login error:', error);
        errorResponse(res, 401, error.message || 'Login failed');
    }
};

/**
 * Self-registration (public route)
 */
const register = async (req, res) => {
    try {
        const { 
            name, email, password, phone, companyName, referenceBy, role, harbourId, 
            subscriptionPlanId, subscriptionPlan,
            aboutYou, dateOfBirth, address, 
            emergencyContactName, emergencyContactRelationship, emergencyContactPhone 
        } = req.body;

        // Check if email already exists
        const existing = await User.findByEmail(email);
        if (existing) {
            return errorResponse(res, 400, 'An account with this email already exists');
        }

        const isBoatOwner = role === 'BOAT_OWNER';

        // Create user with isApproved=false, isActive=false
        const user = new User({
            name: name.trim(),
            email: email.trim().toLowerCase(),
            password,
            phone,
            companyName: companyName ? companyName.trim() : '',
            referenceBy: referenceBy ? referenceBy.trim() : undefined,
            role,
            harbourId,
            // Store dynamic plan reference (new) and legacy plan string (backward compat)
            subscriptionPlanId: subscriptionPlanId || undefined,
            subscriptionPlan: subscriptionPlan || 'NONE',
            subscriptionStatus: 'PENDING_APPROVAL',
            isApproved: false,
            isActive: false,
            // Profile fields
            aboutYou: aboutYou || '',
            dateOfBirth: dateOfBirth || null,
            address: address || '',
            emergencyContactName: emergencyContactName || '',
            emergencyContactRelationship: emergencyContactRelationship || '',
            emergencyContactPhone: emergencyContactPhone || '',
            // Initialize default company values if BOAT_OWNER
            companyId: isBoatOwner ? `RF-${new Date().getFullYear()}-${Math.floor(100 + Math.random() * 900)}` : '',
            companyEstablishedDate: isBoatOwner ? `Since ${new Date().getFullYear()}` : '',
            companyType: isBoatOwner ? 'Sole Proprietorship' : '',
            companyPhone: isBoatOwner ? phone : '',
            companyEmail: isBoatOwner ? email.trim().toLowerCase() : '',
            companyRegisteredAddress: isBoatOwner ? (address || '') : '',
            companyIsVerified: false
        });
        await user.save();

        // Create notification for Super Admin
        await Notification.create({
            userId: user._id,
            type: 'NEW_USER_REGISTRATION',
            title: 'New Registration Request',
            message: `New registration request from ${name} (${role.replace(/_/g, ' ')}) - ${email}`
        });

        logger.info(`New self-registration: ${email} (${role})`);

        return successResponse(res, 201, 'Registration submitted. Admin will approve within 24-48 hours.', {
            email: user.email,
            name: user.name
        });
    } catch (error) {
        logger.error('Registration error:', error);
        return errorResponse(res, 500, error.message || 'Registration failed');
    }
};

/**
 * Refresh access token
 */
const refresh = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        const result = await authService.refreshToken(refreshToken);
        successResponse(res, 200, 'Token refreshed successfully', result);
    } catch (error) {
        logger.error('Refresh token error:', error);
        errorResponse(res, 401, error.message || 'Refresh token failed');
    }
};

/**
 * Logout user
 */
const logout = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        await authService.logout(req.user._id, refreshToken);
        successResponse(res, 200, 'Logout successful');
    } catch (error) {
        logger.error('Logout error:', error);
        errorResponse(res, 500, error.message || 'Logout failed');
    }
};

/**
 * Change password
 */
const changePassword = async (req, res, next) => {
    try {
        const { currentPassword, newPassword } = req.body;
        await authService.changePassword(req.user._id, currentPassword, newPassword);
        successResponse(res, 200, 'Password changed successfully');
    } catch (error) {
        logger.error('Change password error:', error);
        errorResponse(res, 400, error.message || 'Password change failed');
    }
};

/**
 * Get current user profile
 */
const getProfile = async (req, res, next) => {
    try {
        const user = await authService.getUserById(req.user._id);
        successResponse(res, 200, 'Profile retrieved successfully', user);
    } catch (error) {
        logger.error('Get profile error:', error);
        errorResponse(res, 404, error.message || 'Profile not found');
    }
};

/**
 * Update current user profile
 */
const updateProfile = async (req, res, next) => {
    try {
        const userId = req.user._id;
        const updateData = { ...req.body };

        // Prevent updating sensitive system properties directly from profile
        delete updateData.password;
        delete updateData.role;
        delete updateData.isApproved;
        delete updateData.isActive;
        delete updateData.isDeleted;
        delete updateData.subscriptionPlan;
        delete updateData.subscriptionPlanId;
        delete updateData.subscriptionPlanName;
        delete updateData.subscriptionStatus;
        delete updateData.subscriptionStartDate;
        delete updateData.subscriptionEndDate;

        const user = await User.findByIdAndUpdate(
            userId,
            { $set: updateData },
            { new: true, runValidators: true }
        ).select('-password');

        if (!user) {
            return errorResponse(res, 404, 'User not found');
        }

        successResponse(res, 200, 'Profile updated successfully', user);
    } catch (error) {
        logger.error('Update profile error:', error);
        errorResponse(res, 400, error.message || 'Failed to update profile');
    }
};

module.exports = {
    login,
    register,
    refresh,
    logout,
    changePassword,
    getProfile,
    updateProfile
};