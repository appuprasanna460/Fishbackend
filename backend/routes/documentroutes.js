const express = require('express');
const router = express.Router();
const multer = require('multer');
const { authenticate } = require('../middleware/authmiddleware');
const { authorize } = require('../middleware/rbacmiddleware');
const { validate } = require('../middleware/validatemiddleware');
const documentController = require('../controllers/documentcontroller');
const {
    createDocumentSchema,
    updateDocumentSchema,
    documentIdParamSchema,
    documentListQuerySchema
} = require('../validations/documentvalidation');

// Setup multer memory storage with 10MB limit and mime-type filters
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB limit per file
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPG, JPEG, PNG, and PDF are supported.'), false);
        }
    }
});

// Middleware to handle multer file type errors gracefully
const handleMulterUpload = (req, res, next) => {
    upload.array('files', 2)(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            return res.status(400).json({ status: 'ERROR', message: `Upload error: ${err.message}` });
        } else if (err) {
            return res.status(400).json({ status: 'ERROR', message: err.message });
        }
        next();
    });
};

// All document routes require authentication and Boat Owner role
router.use(authenticate);
router.use(authorize('BOAT_OWNER', 'SUPER_ADMIN'));

// Get dashboard statistics
router.get('/stats', documentController.getDocumentStats);

// Document CRUD endpoints
router.get('/', validate(documentListQuerySchema, 'query'), documentController.getDocuments);
router.get('/:id', validate(documentIdParamSchema, 'params'), documentController.getDocumentById);
router.post('/', handleMulterUpload, validate(createDocumentSchema), documentController.createDocument);
router.put('/:id', handleMulterUpload, validate(documentIdParamSchema, 'params'), validate(updateDocumentSchema), documentController.updateDocument);
router.delete('/:id', validate(documentIdParamSchema, 'params'), documentController.deleteDocument);

// File uploads for existing documents
router.post('/:id/files', handleMulterUpload, validate(documentIdParamSchema, 'params'), documentController.uploadDocumentFiles);

// Crew specific document endpoints
router.get('/crew/:crewMemberId/documents', documentController.getCrewDocuments);
router.post('/crew/:crewMemberId/documents', handleMulterUpload, documentController.createCrewDocument);

module.exports = router;
