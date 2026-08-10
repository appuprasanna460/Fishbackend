// routes/subscriptionPlanRoutes.js
const express = require('express');
const router = express.Router();
const subscriptionPlanController = require('../controllers/subscriptionPlanController');
const { authenticate, authorize } = require('../middleware/authmiddleware');

// Public route to fetch active plans (for registration)
router.get('/active', subscriptionPlanController.getActivePlans);

// All routes below require authentication
router.use(authenticate);

// Super Admin only routes
router.get('/all',
    authorize(['SUPER_ADMIN']),
    subscriptionPlanController.getAllPlans
);

router.post('/',
    authorize(['SUPER_ADMIN']),
    subscriptionPlanController.createPlan
);

router.put('/:id',
    authorize(['SUPER_ADMIN']),
    subscriptionPlanController.updatePlan
);

router.patch('/:id/toggle',
    authorize(['SUPER_ADMIN']),
    subscriptionPlanController.togglePlanStatus
);

router.delete('/:id',
    authorize(['SUPER_ADMIN']),
    subscriptionPlanController.deletePlan
);

module.exports = router;