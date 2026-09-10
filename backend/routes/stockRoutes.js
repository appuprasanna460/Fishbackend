const express = require('express');
const router = express.Router();
const stockController = require('../controllers/stockController');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/summary', stockController.getStockSummary);
router.get('/locations', stockController.getStockByLocation);
router.get('/lots', stockController.getPurchaseLots);

router.get('/', stockController.getStock);
router.post('/lots/:id/report-issue', authorizeExporterRoles('WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), stockController.reportLotIssue);
router.patch('/lots/:id/weigh', authorizeExporterRoles('WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), stockController.weighAndGradeLot);
router.post('/allocate', authorizeExporterRoles('WAREHOUSE_STAFF', 'SALES_STAFF', 'DOMESTIC_EXPORTER'), stockController.allocateStock);

module.exports = router;
