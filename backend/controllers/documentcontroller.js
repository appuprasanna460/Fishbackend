const Document = require('../models/documentmodel');
const Boat = require('../models/boatmodel');
const Crew = require('../models/crewModel');
const s3Service = require('../services/s3Service');
const { successResponse, errorResponse } = require('../utils/responseutils');
const logger = require('../config/logger');

/**
 * Helper to determine S3 folder path based on document details
 */
const getS3FolderPath = (documentName, boatId, crewMemberId) => {
    const cleanBoatId = boatId || 'unassigned';
    if (crewMemberId) {
        const docNameLower = documentName.toLowerCase();
        let subFolder = 'documents';
        if (docNameLower.includes('id') || docNameLower.includes('passport') || docNameLower.includes('aadhaar')) {
            subFolder = 'id-proof';
        } else if (docNameLower.includes('proof')) {
            subFolder = 'other-proof';
        }
        return `boats/${cleanBoatId}/crew/${crewMemberId}/${subFolder}`;
    } else {
        return `boats/${cleanBoatId}/documents`;
    }
};

/**
 * Create a new Document (Boat or Crew)
 */
const createDocument = async (req, res) => {
    try {
        const {
            documentName,
            documentNumber,
            boatId,
            crewMemberId,
            issueDate,
            expiryDate,
            issuedBy
        } = req.body;

        const ownerId = req.user._id;

        // 1. Verify Boat ownership if boatId is provided
        if (boatId) {
            const boat = await Boat.findOne({ _id: boatId, ownerId });
            if (!boat) {
                return errorResponse(res, 403, 'Access denied. You do not own this boat.');
            }
        }

        // 2. Verify Crew ownership if crewMemberId is provided
        let resolvedBoatId = boatId;
        if (crewMemberId) {
            const crew = await Crew.findOne({ _id: crewMemberId, ownerId });
            if (!crew) {
                return errorResponse(res, 403, 'Access denied. You do not manage this crew member.');
            }
            // Automatically resolve boatId if crew is assigned to a boat and none was passed
            if (!resolvedBoatId && crew.assignedTo && crew.assignedTo.boatId) {
                resolvedBoatId = crew.assignedTo.boatId.toString();
            }
        }

        // 3. Validation: Must belong to either a boat or crew member
        if (!boatId && !crewMemberId) {
            return errorResponse(res, 400, 'Either Boat ID or Crew Member ID must be provided.');
        }

        // 4. File upload processing
        if (!req.files || req.files.length === 0) {
            return errorResponse(res, 400, 'Please upload at least one document file (PDF or Image).');
        }

        if (req.files.length > 2) {
            return errorResponse(res, 400, 'A maximum of 2 files/images is allowed per document.');
        }

        const uploadedFiles = [];
        const folderPath = getS3FolderPath(documentName, resolvedBoatId, crewMemberId);

        for (const file of req.files) {
            // Upload to S3 via s3Service
            const uploadResult = await s3Service.uploadToS3(
                file.buffer,
                file.originalname,
                file.mimetype,
                folderPath
            );

            uploadedFiles.push({
                url: uploadResult.url,
                key: uploadResult.key,
                originalName: file.originalname,
                mimeType: file.mimetype,
                sizeBytes: file.size
            });
        }

        // 5. Create document model
        const document = new Document({
            ownerId,
            documentName,
            documentNumber,
            boatId: resolvedBoatId || null,
            crewMemberId: crewMemberId || null,
            issueDate,
            expiryDate,
            issuedBy,
            files: uploadedFiles
        });

        await document.save();

        logger.info(`Document created successfully: ${document._id} for owner ${ownerId}`);
        return successResponse(res, 201, 'Document created successfully', document);
    } catch (error) {
        logger.error('Error creating document:', error);
        return errorResponse(res, 500, error.message || 'Failed to create document');
    }
};

/**
 * Get all documents for the authenticated Owner with filters
 */
const getDocuments = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const {
            boatId,
            crewMemberId,
            status,
            search
        } = req.query;

        // Build base Mongo Query
        const query = { ownerId, isDeleted: false, isActive: true };

        if (boatId) query.boatId = boatId;
        if (crewMemberId) query.crewMemberId = crewMemberId;

        // If search is supplied, match documentName, documentNumber or issuedBy (regex)
        if (search) {
            query.$or = [
                { documentName: { $regex: search, $options: 'i' } },
                { documentNumber: { $regex: search, $options: 'i' } },
                { issuedBy: { $regex: search, $options: 'i' } }
            ];
        }

        // Fetch documents
        let documents = await Document.find(query)
            .populate('boatId', 'boatName boatNumber')
            .populate('crewMemberId', 'name role')
            .sort({ expiryDate: 1 });

        // Apply dynamic status filtering in-memory
        if (status && status !== 'All') {
            documents = documents.filter(doc => {
                const docStatus = doc.status; // Valid, Expiring Soon, Expired
                if (status === 'Expiring' || status === 'Expiring Soon') {
                    return docStatus === 'Expiring Soon';
                }
                return docStatus.toLowerCase() === status.toLowerCase();
            });
        }

        return successResponse(res, 200, 'Documents retrieved successfully', documents);
    } catch (error) {
        logger.error('Error fetching documents:', error);
        return errorResponse(res, 500, 'Failed to retrieve documents');
    }
};

/**
 * Get document details by ID
 */
const getDocumentById = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const document = await Document.findOne({ _id: req.params.id, ownerId, isDeleted: false })
            .populate('boatId', 'boatName boatNumber')
            .populate('crewMemberId', 'name role');

        if (!document) {
            return errorResponse(res, 404, 'Document not found or access denied.');
        }

        return successResponse(res, 200, 'Document retrieved successfully', document);
    } catch (error) {
        logger.error('Error fetching document details:', error);
        return errorResponse(res, 500, 'Failed to retrieve document details');
    }
};

/**
 * Update Document metadata or Renew dates/files
 */
const updateDocument = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const docId = req.params.id;

        const document = await Document.findOne({ _id: docId, ownerId, isDeleted: false });
        if (!document) {
            return errorResponse(res, 404, 'Document not found or access denied.');
        }

        const {
            documentName,
            documentNumber,
            boatId,
            crewMemberId,
            issueDate,
            expiryDate,
            issuedBy
        } = req.body;

        // Apply metadata updates
        if (documentName !== undefined) document.documentName = documentName;
        if (documentNumber !== undefined) document.documentNumber = documentNumber;
        if (issueDate !== undefined) document.issueDate = issueDate;
        if (expiryDate !== undefined) document.expiryDate = expiryDate;
        if (issuedBy !== undefined) document.issuedBy = issuedBy;

        if (boatId !== undefined) {
            if (boatId) {
                const boat = await Boat.findOne({ _id: boatId, ownerId });
                if (!boat) return errorResponse(res, 403, 'Access denied. You do not own this boat.');
            }
            document.boatId = boatId || null;
        }

        if (crewMemberId !== undefined) {
            if (crewMemberId) {
                const crew = await Crew.findOne({ _id: crewMemberId, ownerId });
                if (!crew) return errorResponse(res, 403, 'Access denied. You do not manage this crew member.');
            }
            document.crewMemberId = crewMemberId || null;
        }

        // Upload and replace files if provided
        if (req.files && req.files.length > 0) {
            if (req.files.length > 2) {
                return errorResponse(res, 400, 'A maximum of 2 files/images is allowed.');
            }

            const resolvedBoatId = boatId || document.boatId;
            const resolvedCrewMemberId = crewMemberId || document.crewMemberId;
            const folderPath = getS3FolderPath(
                documentName || document.documentName,
                resolvedBoatId,
                resolvedCrewMemberId
            );

            const uploadedFiles = [];
            for (const file of req.files) {
                const uploadResult = await s3Service.uploadToS3(
                    file.buffer,
                    file.originalname,
                    file.mimetype,
                    folderPath
                );

                uploadedFiles.push({
                    url: uploadResult.url,
                    key: uploadResult.key,
                    originalName: file.originalname,
                    mimeType: file.mimetype,
                    sizeBytes: file.size
                });
            }

            document.files = uploadedFiles;
        }

        await document.save();

        logger.info(`Document updated successfully: ${docId}`);
        return successResponse(res, 200, 'Document updated successfully', document);
    } catch (error) {
        logger.error('Error updating document:', error);
        return errorResponse(res, 500, 'Failed to update document');
    }
};

/**
 * Add / upload files for a document (Appends to files array)
 */
const uploadDocumentFiles = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const docId = req.params.id;

        const document = await Document.findOne({ _id: docId, ownerId, isDeleted: false });
        if (!document) {
            return errorResponse(res, 404, 'Document not found or access denied.');
        }

        if (!req.files || req.files.length === 0) {
            return errorResponse(res, 400, 'No files provided for upload.');
        }

        if (document.files.length + req.files.length > 2) {
            return errorResponse(res, 400, `A document can have a maximum of 2 files. Current files count: ${document.files.length}`);
        }

        const folderPath = getS3FolderPath(
            document.documentName,
            document.boatId,
            document.crewMemberId
        );

        for (const file of req.files) {
            const uploadResult = await s3Service.uploadToS3(
                file.buffer,
                file.originalname,
                file.mimetype,
                folderPath
            );

            document.files.push({
                url: uploadResult.url,
                key: uploadResult.key,
                originalName: file.originalname,
                mimeType: file.mimetype,
                sizeBytes: file.size
            });
        }

        await document.save();

        logger.info(`Additional files uploaded for document: ${docId}`);
        return successResponse(res, 200, 'Files uploaded successfully', document);
    } catch (error) {
        logger.error('Error uploading additional document files:', error);
        return errorResponse(res, 500, 'Failed to upload additional files');
    }
};

/**
 * Soft delete a document
 */
const deleteDocument = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const document = await Document.findOne({ _id: req.params.id, ownerId, isDeleted: false });

        if (!document) {
            return errorResponse(res, 404, 'Document not found or access denied.');
        }

        document.isDeleted = true;
        await document.save();

        logger.info(`Document soft deleted: ${document._id}`);
        return successResponse(res, 200, 'Document deleted successfully');
    } catch (error) {
        logger.error('Error deleting document:', error);
        return errorResponse(res, 500, 'Failed to delete document');
    }
};

/**
 * Get dashboard statistics
 */
const getDocumentStats = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const documents = await Document.find({ ownerId, isDeleted: false, isActive: true });

        let total = documents.length;
        let valid = 0;
        let expiringSoon = 0;
        let expired = 0;

        const expiringList = [];

        for (const doc of documents) {
            const status = doc.status;
            if (status === 'Valid') {
                valid++;
            } else if (status === 'Expiring Soon') {
                expiringSoon++;
                expiringList.push(doc);
            } else {
                expired++;
            }
        }

        return successResponse(res, 200, 'Document statistics retrieved successfully', {
            summary: {
                total,
                valid,
                expiringSoon,
                expired
            },
            expiringSoonList: expiringList
        });
    } catch (error) {
        logger.error('Error fetching document statistics:', error);
        return errorResponse(res, 500, 'Failed to retrieve document statistics');
    }
};

/**
 * Retrieve documents for a specific crew member
 */
const getCrewDocuments = async (req, res) => {
    try {
        const ownerId = req.user._id;
        const crewMemberId = req.params.crewMemberId;

        // Verify crew member exists and belongs to the owner
        const crew = await Crew.findOne({ _id: crewMemberId, ownerId });
        if (!crew) {
            return errorResponse(res, 404, 'Crew member not found or access denied.');
        }

        const documents = await Document.find({
            ownerId,
            crewMemberId,
            isDeleted: false,
            isActive: true
        }).sort({ expiryDate: 1 });

        return successResponse(res, 200, 'Crew documents retrieved successfully', documents);
    } catch (error) {
        logger.error('Error fetching crew documents:', error);
        return errorResponse(res, 500, 'Failed to retrieve crew documents');
    }
};

/**
 * Upload and associate document specifically with a crew member
 */
const createCrewDocument = async (req, res) => {
    // Forward to createDocument but force crewMemberId
    req.body.crewMemberId = req.params.crewMemberId;
    return createDocument(req, res);
};

module.exports = {
    createDocument,
    getDocuments,
    getDocumentById,
    updateDocument,
    uploadDocumentFiles,
    deleteDocument,
    getDocumentStats,
    getCrewDocuments,
    createCrewDocument
};
