const express = require('express');
const router = express.Router();
const harbourController = require('../controllers/harbourcontroller');
const { authenticate } = require('../middleware/authmiddleware');
const { authorize } = require('../middleware/rbacmiddleware');

// Public route to fetch active harbours (for registration dropdown)
router.get('/', harbourController.getPublicHarbours);

// Super Admin CRUD
router.post('/', authenticate, authorize('SUPER_ADMIN'), harbourController.createHarbour);
router.get('/all', authenticate, authorize('SUPER_ADMIN'), harbourController.getHarbours);
router.put('/:id', authenticate, authorize('SUPER_ADMIN'), harbourController.updateHarbour);
router.delete('/:id', authenticate, authorize('SUPER_ADMIN'), harbourController.deleteHarbour);

module.exports = router;
