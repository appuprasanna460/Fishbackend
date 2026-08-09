// routes/invoiceTemplateRoutes.js
const express = require('express');
const router = express.Router();
const invoiceTemplateController = require('../controllers/invoiceTemplateController');
const { authenticate, authorize } = require('../middleware/authmiddleware');

// All routes require authentication
router.use(authenticate);

// Super Admin only routes
router.post('/',
    authorize(['SUPER_ADMIN']),
    invoiceTemplateController.createOrUpdateTemplate
);

router.get('/all',
    invoiceTemplateController.getAllTemplates
);

router.delete('/:id',
    authorize(['SUPER_ADMIN']),
    invoiceTemplateController.deleteTemplate
);

router.patch('/:id/toggle',
    authorize(['SUPER_ADMIN']),
    invoiceTemplateController.toggleTemplateStatus
);

// Public route (any authenticated user)
router.get('/active',
    invoiceTemplateController.getActiveTemplate
);

module.exports = router;