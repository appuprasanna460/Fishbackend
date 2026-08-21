const dotenv = require('dotenv');
dotenv.config();

const requiredEnvVars = [
    'PORT',
    'NODE_ENV',
    'MONGODB_URI',
    'ACCESS_TOKEN_SECRET',
    'REFRESH_TOKEN_SECRET'
];

// Validate required environment variables
requiredEnvVars.forEach((envVar) => {
    if (!process.env[envVar]) {
        throw new Error(`Missing required environment variable: ${envVar}`);
    }
});

module.exports = {
    port: process.env.PORT || 5000,
    nodeEnv: process.env.NODE_ENV || 'development',
    mongodbUri: process.env.MONGODB_URI,
    accessTokenSecret: process.env.ACCESS_TOKEN_SECRET,
    refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET,
    accessTokenExpiry: process.env.ACCESS_TOKEN_EXPIRY || '15m',
    refreshTokenExpiry: process.env.REFRESH_TOKEN_EXPIRY || '7d',
    clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',
    allowedOrigins: process.env.ALLOWED_ORIGINS
        ? process.env.ALLOWED_ORIGINS.split(',')
        : ['http://localhost:3000', 'http://localhost:3001'],
    bcryptSaltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12,
    rateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
        max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
    },
    authRateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
        max: parseInt(process.env.AUTH_RATE_LIMIT_MAX) || 5
    },
    aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        region: process.env.AWS_S3_REGION || 'ap-south-1',
        bucket: process.env.AWS_S3_BUCKET,
        cloudfrontDomain: process.env.AWS_CLOUDFRONT_DOMAIN || 'https://d196xvoij956a9.cloudfront.net'
    },
    isProduction: process.env.NODE_ENV === 'production',
    isDevelopment: process.env.NODE_ENV === 'development'
};