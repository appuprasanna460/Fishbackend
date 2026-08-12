const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationcontroller');
const { authenticate, authorize } = require('../middleware/authmiddleware');

// All notification routes require authentication
router.use(authenticate);

// ── User notifications (any authenticated user) ───────────────────────────────
// GET my own notifications (subscription expiry warnings, renewal results)
router.get('/my', notificationController.getMyNotifications);

// PATCH mark a notification as read
router.patch('/:id/read', notificationController.markAsRead);

// ── Super Admin only routes ───────────────────────────────────────────────────
router.use(authorize(['SUPER_ADMIN']));

// GET all pending registrations and renewal requests
router.get('/', notificationController.getNotifications);

// POST approve registration
router.post('/:id/approve', notificationController.approveRegistration);

// POST reject registration
router.post('/:id/reject', notificationController.rejectRegistration);

module.exports = router;
