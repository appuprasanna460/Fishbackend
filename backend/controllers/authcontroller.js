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
        const { name, email, password, phone, companyName, referenceBy, role, harbourId, subscriptionPlan } = req.body;

        // Check if email already exists
        const existing = await User.findByEmail(email);
        if (existing) {
            return errorResponse(res, 400, 'An account with this email already exists');
        }

        // Create user with isApproved=false, isActive=false
        const user = new User({
            name: name.trim(),
            email: email.trim().toLowerCase(),
            password,
            phone,
            companyName: companyName.trim(),
            referenceBy: referenceBy ? referenceBy.trim() : undefined,
            role,
            harbourId,
            subscriptionPlan,
            isApproved: false,
            isActive: false
        });
        await user.save();

        // Create notification for Super Admin
        await Notification.create({
            userId: user._id,
            type: 'NEW_USER_REGISTRATION',
            message: `New registration request from ${name} (${role.replace('_', ' ')}) - ${email}`
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

module.exports = {
    login,
    register,
    refresh,
    logout,
    changePassword,
    getProfile
};