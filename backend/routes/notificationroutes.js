const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationcontroller');
const { authenticate, authorize } = require('../middleware/authmiddleware');

// All notification routes require Super Admin authentication
router.use(authenticate);
router.use(authorize(['SUPER_ADMIN']));

// GET all pending registrations
router.get('/', notificationController.getNotifications);

// POST approve registration
router.post('/:id/approve', notificationController.approveRegistration);

// POST reject registration
router.post('/:id/reject', notificationController.rejectRegistration);

module.exports = router;
