const AuditLog = require('../models/auditLogmodel');
const logger = require('../config/logger');

/**
 * Audit log middleware - logs all mutating requests
 */
const auditLog = async (req, res, next) => {
    // Skip logging for GET and OPTIONS requests
    if (req.method === 'GET' || req.method === 'OPTIONS') {
        return next();
    }

    // Store original send function to capture response
    const originalSend = res.send;
    let responseBody;

    res.send = function (body) {
        responseBody = body;
        return originalSend.call(this, body);
    };

    // Wait for response to be sent
    res.on('finish', async () => {
        try {
            // Only log if user is authenticated
            if (!req.user) {
                return;
            }

            // Skip logging for certain paths
            const skipPaths = ['/api/auth/login', '/api/auth/refresh'];
            if (skipPaths.includes(req.path)) {
                return;
            }

            // Parse response body
            let parsedBody = null;
            try {
                if (responseBody && typeof responseBody === 'string') {
                    parsedBody = JSON.parse(responseBody);
                } else if (responseBody) {
                    parsedBody = responseBody;
                }
            } catch (e) {
                // Not JSON
            }

            // Determine if request was successful (2xx status)
            const isSuccess = res.statusCode >= 200 && res.statusCode < 300;
            if (!isSuccess) {
                return;
            }

            // Extract resource name from path skipping 'api' and 'exporter' prefix segments
            const pathParts = req.path.split('/').filter(p => p && p !== 'api' && p !== 'exporter');
            const resource = pathParts.length > 0 ? pathParts[0] : 'unknown';
            const resourceId = pathParts.length > 1 ? pathParts[1] : null;

            // Map HTTP methods to actions
            const actionMap = {
                'POST': 'CREATE',
                'PUT': 'UPDATE',
                'PATCH': 'UPDATE',
                'DELETE': 'DELETE'
            };
            const action = actionMap[req.method] || req.method;

            // Prepare changes.after and redact sensitive fields
            let afterState = parsedBody?.data ? JSON.parse(JSON.stringify(parsedBody.data)) : (parsedBody ? JSON.parse(JSON.stringify(parsedBody)) : null);
            if (afterState && typeof afterState === 'object') {
                delete afterState.password;
                delete afterState.refreshTokens;
                delete afterState.token;
            }

            // Create audit log entry
            await AuditLog.create({
                userId: req.user._id,
                exporterId: req.user?.exporterId || null,
                action,
                resource: resource.charAt(0).toUpperCase() + resource.slice(1),
                resourceId: resourceId || parsedBody?.data?.id || parsedBody?._id || null,
                changes: {
                    before: null,
                    after: afterState
                },
                ipAddress: req.ip || req.connection.remoteAddress,
                userAgent: req.headers['user-agent'],
                timestamp: new Date()
            });

            logger.debug(`Audit log created: ${action} ${resource}`);

        } catch (error) {
            logger.error('Failed to create audit log:', error);
        }
    });

    next();
};

module.exports = {
    auditLog
};