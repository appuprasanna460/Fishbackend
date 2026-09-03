const jwt = require('jsonwebtoken');
const env = require('../config/env');
const logger = require('../config/logger');
const User = require('../models/usermodel');
const { errorResponse } = require('../utils/responseutils');

const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return errorResponse(res, 401, 'No token provided or invalid format');
        }

        const token = authHeader.split(' ')[1];

        try {
            const decoded = jwt.verify(token, env.accessTokenSecret);

            // Check if user still exists and is active
            const user = await User.findById(decoded.userId)
                .select('-password')
                .lean();

            if (!user) {
                return errorResponse(res, 401, 'User no longer exists');
            }

            // Check for concurrent login
            if (decoded.tokenVersion !== user.tokenVersion) {
                return errorResponse(res, 401, 'Session superseded. Logged in from another device.', { code: 'SESSION_SUPERSEDED' });
            }

            // Allow expired users to still hit subscription endpoints (for renewal flow)
            const isSubscriptionRoute = req.path.startsWith('/api/subscription') ||
                req.originalUrl.includes('/subscription');

            if (!user.isActive || user.isDeleted) {
                // Check if this is an expired subscription (not a banned account)
                const hasExpiredSubscription = user.subscriptionEndDate &&
                    new Date(user.subscriptionEndDate) < new Date() &&
                    user.subscriptionStatus === 'EXPIRED';

                if (hasExpiredSubscription && isSubscriptionRoute) {
                    // Allow expired users through to subscription/renewal routes only
                    req.user = user;
                    req.userId = decoded.userId;
                    req.token = token;
                    return next();
                }

                if (hasExpiredSubscription) {
                    return errorResponse(res, 403, 'Your subscription has expired. Please contact admin or request a renewal.', { code: 'SUBSCRIPTION_EXPIRED' });
                }

                return errorResponse(res, 401, 'User account is disabled');
            }

            // Check if subscription has expired on-the-fly (may not have been caught by scheduler yet)
            if (user.role !== 'SUPER_ADMIN' && user.subscriptionEndDate) {
                const now = new Date();
                if (new Date(user.subscriptionEndDate) < now) {
                    // Mark as expired in DB (non-blocking)
                    User.findByIdAndUpdate(user._id, {
                        subscriptionStatus: 'EXPIRED',
                        isActive: false
                    }).catch(err => logger.error('Failed to mark user expired:', err));

                    if (isSubscriptionRoute) {
                        // Allow through to renewal flow
                        req.user = { ...user, subscriptionStatus: 'EXPIRED' };
                        req.userId = decoded.userId;
                        req.token = token;
                        return next();
                    }

                    return errorResponse(res, 403,
                        'Your subscription has expired. Please contact admin or request a renewal.',
                        { code: 'SUBSCRIPTION_EXPIRED' }
                    );
                }
            }

            // Attach user to request
            req.user = user;
            req.userId = decoded.userId;
            req.token = token;

            next();
        } catch (jwtError) {
            if (jwtError.name === 'TokenExpiredError') {
                return errorResponse(res, 401, 'Token expired');
            }
            if (jwtError.name === 'JsonWebTokenError') {
                return errorResponse(res, 401, 'Invalid token');
            }
            throw jwtError;
        }
    } catch (error) {
        logger.error('Authentication error:', error);
        return errorResponse(res, 500, 'Authentication failed');
    }
};
const authorize = (roles = []) => {
    return (req, res, next) => {
        if (!req.user) {
            return errorResponse(res, 401, 'Authentication required');
        }

        if (!roles.includes(req.user.role)) {
            return errorResponse(res, 403, 'Insufficient permissions');
        }

        next();
    };
};
// Optional authentication (doesn't block if no token)
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            try {
                const decoded = jwt.verify(token, env.accessTokenSecret);
                const user = await User.findById(decoded.userId)
                    .select('-password')
                    .lean();

                if (user && user.isActive && !user.isDeleted) {
                    req.user = user;
                    req.userId = decoded.userId;
                }
            } catch (error) {
                // Invalid token, continue as unauthenticated
                logger.debug('Optional auth token invalid:', error.message);
            }
        }

        // In Express 5, async handlers don't use next - they return promises
        // Fall through to next middleware
        if (typeof next === 'function') {
            next();
        }
    } catch (error) {
        if (typeof next === 'function') {
            next();
        }
    }
};

module.exports = {
    authenticate,
    optionalAuth,
    authorize
};