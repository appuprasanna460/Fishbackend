const crypto = require('crypto');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const env = require('../config/env');
const logger = require('../config/logger');

// Initialize the S3 client
const s3Client = new S3Client({
    region: env.aws.region,
    credentials: {
        accessKeyId: env.aws.accessKeyId,
        secretAccessKey: env.aws.secretAccessKey
    }
});

/**
 * Uploads a file buffer to the configured AWS S3 bucket.
 * 
 * @param {Buffer} fileBuffer - The binary file contents
 * @param {string} originalName - The original name of the file
 * @param {string} mimeType - The mime type of the file
 * @param {string} folderPath - Target virtual directory, e.g. "boats/101/registration"
 * @returns {Promise<{url: string, key: string}>} - CloudFront URL and S3 Object Key
 */
const uploadToS3 = async (fileBuffer, originalName, mimeType, folderPath) => {
    try {
        const ext = originalName.split('.').pop() || '';
        const uniqueName = `${crypto.randomUUID()}.${ext.toLowerCase()}`;
        
        // Clean folderPath and build S3 key
        // fishmarket/boats/{boatId}/registration/{uniqueName}
        const s3Key = `fishmarket/${folderPath}/${uniqueName}`.replace(/\/+/g, '/');

        logger.info(`Uploading file to S3 bucket ${env.aws.bucket} with key: ${s3Key}`);

        const command = new PutObjectCommand({
            Bucket: env.aws.bucket,
            Key: s3Key,
            Body: fileBuffer,
            ContentType: mimeType
        });

        await s3Client.send(command);

        // Construct CloudFront URL
        const cloudfrontBase = env.aws.cloudfrontDomain.endsWith('/')
            ? env.aws.cloudfrontDomain.slice(0, -1)
            : env.aws.cloudfrontDomain;
        const url = `${cloudfrontBase}/${s3Key}`;

        logger.info(`Successfully uploaded to S3. CloudFront URL: ${url}`);

        return {
            url,
            key: s3Key
        };
    } catch (error) {
        logger.error('Error uploading file to S3:', error);
        throw new Error('S3 file upload failed');
    }
};

module.exports = {
    uploadToS3
};
