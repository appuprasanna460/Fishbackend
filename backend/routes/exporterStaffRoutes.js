const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });
const staffController = require('../controllers/staffcontroller');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/', staffController.getStaffList);
router.post('/', authorizeExporterRoles('DOMESTIC_EXPORTER'), staffController.createStaff);
router.get('/:id/profile', staffController.getStaffProfile);
router.patch('/:id', authorizeExporterRoles('DOMESTIC_EXPORTER'), staffController.updateStaff);
router.put('/:id', authorizeExporterRoles('DOMESTIC_EXPORTER'), staffController.updateStaff);
router.patch('/:id/status', authorizeExporterRoles('DOMESTIC_EXPORTER'), staffController.toggleStaffStatus);
router.delete('/:id', authorizeExporterRoles('DOMESTIC_EXPORTER'), staffController.deleteStaff);

router.post('/:id/documents', upload.single('document'), staffController.uploadStaffDocument);
router.delete('/:id/documents/:documentId', staffController.deleteStaffDocument);

module.exports = router;
