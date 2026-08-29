const express = require('express');
const router = express.Router();
const multer = require('multer');
const staffController = require('../controllers/staffcontroller');
const { authenticate } = require('../middleware/authmiddleware');
const { authorize } = require('../middleware/rbacmiddleware');

// Setup multer memory storage with 5MB limit and mime-type filters for staff documents
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit per file
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only PDF, JPG, PNG, and JPEG are supported.'), false);
        }
    }
});

// Middleware to handle multer file type errors gracefully
const handleMulterUpload = (req, res, next) => {
    upload.single('document')(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            return res.status(400).json({ status: 'ERROR', message: `Upload error: ${err.message}` });
        } else if (err) {
            return res.status(400).json({ status: 'ERROR', message: err.message });
        }
        next();
    });
};

// All staff routes require authentication
router.use(authenticate);

// 1. Get all staff under agent
router.get('/', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.getStaffList);

// 2. Create staff
router.post('/', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.createStaff);

// 3. Get staff profile preview
router.get('/:staffId/profile', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.getStaffProfile);

// 4. Update staff
router.put('/:staffId', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.updateStaff);

// 5. Toggle staff status
router.patch('/:staffId/status', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.toggleStaffStatus);

// 6. Delete staff (soft delete)
router.delete('/:staffId', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.deleteStaff);

// 7. Upload staff document
router.post('/:staffId/documents', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), handleMulterUpload, staffController.uploadStaffDocument);

// 8. Delete staff document
router.delete('/:staffId/documents/:documentId', authorize('COMMISSION_AGENT', 'SUPER_ADMIN'), staffController.deleteStaffDocument);

module.exports = router;
