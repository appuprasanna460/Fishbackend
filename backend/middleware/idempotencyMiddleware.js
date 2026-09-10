const IdempotencyRecord = require('../models/idempotencyRecordModel');

/**
 * Idempotency Middleware to prevent duplicate non-idempotent operations
 */
const checkIdempotency = async (req, res, next) => {
    const key = req.headers['idempotency-key'] || req.headers['x-idempotency-key'];
    if (!key) {
        return next();
    }

    const userId = req.user?._id;
    if (!userId) {
        return next();
    }

    const endpoint = req.originalUrl || req.url;

    try {
        const existingRecord = await IdempotencyRecord.findOne({ key, userId, endpoint });
        if (existingRecord) {
            return res.status(existingRecord.statusCode).json(existingRecord.responseBody);
        }

        // Wrap res.json to capture response
        const originalJson = res.json.bind(res);
        res.json = (body) => {
            if (res.statusCode >= 200 && res.statusCode < 300) {
                IdempotencyRecord.create({
                    key,
                    userId,
                    endpoint,
                    responseBody: body,
                    statusCode: res.statusCode
                }).catch(err => {
                    console.error('Failed to save idempotency record:', err.message);
                });
            }
            return originalJson(body);
        };

        next();
    } catch (error) {
        next(error);
    }
};

module.exports = checkIdempotency;
