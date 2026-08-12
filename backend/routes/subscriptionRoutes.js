// routes/subscriptionRoutes.js
const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const { authenticate, authorize } = require('../middleware/authmiddleware');

// All subscription routes require authentication
router.use(authenticate);

// ── Any authenticated user ────────────────────────────────────────────────────

// GET my current subscription details
router.get('/my', subscriptionController.getMySubscription);

// GET active plans (for renewal plan selection)
router.get('/plans', subscriptionController.getActivePlans);

// GET my renewal request status
router.get('/renewal/status', subscriptionController.getMyRenewalStatus);

// POST create a renewal request
router.post('/renewal', subscriptionController.createRenewalRequest);

// ── Super Admin only ──────────────────────────────────────────────────────────
const adminOnly = authorize(['SUPER_ADMIN']);

// GET all pending renewal requests
router.get('/renewals', adminOnly, subscriptionController.getRenewalRequests);

// POST approve a renewal request
router.post('/renewals/:id/approve', adminOnly, subscriptionController.approveRenewal);

// POST reject a renewal request
router.post('/renewals/:id/reject', adminOnly, subscriptionController.rejectRenewal);

module.exports = router;
