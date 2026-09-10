const express = require('express');
const router = express.Router();
const exporterDashboardController = require('../controllers/exporterDashboardController');
const { authenticateExporterUser } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/', exporterDashboardController.getDashboard);

module.exports = router;
