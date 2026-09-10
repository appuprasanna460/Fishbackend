const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/usermodel');

/**
 * Authentication & Context Middleware for Exporter Module
 */
const authenticateExporterUser = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'Authentication token required.' });
        }

        const token = authHeader.split(' ')[1];
        let decoded;
        try {
            decoded = jwt.verify(token, env.accessTokenSecret);
        } catch (jwtErr) {
            return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
        }

        const userId = decoded.userId || decoded.id;
        if (!userId) {
            return res.status(401).json({ success: false, message: 'Invalid token payload.' });
        }

        const user = await User.findById(userId).select('-password');
        if (!user) {
            return res.status(401).json({ success: false, message: 'User account not found.' });
        }

        // Check account flags
        if (!user.isActive || user.isDeleted || !user.isApproved) {
            return res.status(403).json({ success: false, message: 'Account is inactive, pending approval, or deleted.' });
        }

        // Role check
        const allowedRoles = ['DOMESTIC_EXPORTER', 'PURCHASE_STAFF', 'WAREHOUSE_STAFF', 'SALES_STAFF', 'ACCOUNTANT'];
        if (!allowedRoles.includes(user.role)) {
            return res.status(403).json({ success: false, message: `Role '${user.role}' is not authorized for Exporter module.` });
        }

        // Resolve exporterId
        let resolvedExporterId = null;
        if (user.role === 'DOMESTIC_EXPORTER') {
            resolvedExporterId = user._id;
        } else {
            resolvedExporterId = user.exporterId || user.ownerId || null;
        }

        if (!resolvedExporterId) {
            return res.status(403).json({ success: false, message: 'Orphan staff user without assigned exporter.' });
        }

        // Subscription check (unless subscription route)
        const isSubscriptionRoute = req.originalUrl && req.originalUrl.includes('/subscription');
        if (!isSubscriptionRoute) {
            if (user.role === 'DOMESTIC_EXPORTER' || resolvedExporterId) {
                // If checking domestic exporter subscription
                const exporterUser = user.role === 'DOMESTIC_EXPORTER' ? user : await User.findById(resolvedExporterId);
                if (exporterUser) {
                    const now = new Date();
                    if (exporterUser.subscriptionEndDate && new Date(exporterUser.subscriptionEndDate) < now && exporterUser.subscriptionStatus !== 'ACTIVE') {
                        return res.status(403).json({ success: false, message: 'Exporter subscription has expired.', code: 'SUBSCRIPTION_EXPIRED' });
                    }
                }
            }
        }

        user.exporterId = resolvedExporterId;
        req.user = user;
        req.user.exporterId = resolvedExporterId;

        next();
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * Authorization Middleware: Verify role permissions
 * @param {...String} allowedRoles 
 */
const authorizeExporterRoles = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, message: 'User unauthenticated.' });
        }

        if (req.user.role === 'DOMESTIC_EXPORTER') {
            return next();
        }

        if (allowedRoles.includes(req.user.role)) {
            return next();
        }

        return res.status(403).json({
            success: false,
            message: `Access denied. Role '${req.user.role}' is not authorized for this operation.`
        });
    };
};

module.exports = {
    authenticateExporterUser,
    authorizeExporterRoles
};
