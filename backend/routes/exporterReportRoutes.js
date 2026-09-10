const express = require('express');
const router = express.Router();
const exporterReportController = require('../controllers/exporterReportController');
const { authenticateExporterUser } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/purchase-register', exporterReportController.getPurchaseRegister);
router.get('/sales-register', exporterReportController.getSalesRegister);
router.get('/species-pl', exporterReportController.getSpeciesWisePL);
router.get('/staff-purchases', exporterReportController.getStaffWisePurchases);
router.get('/unit-analysis', exporterReportController.getUnitWiseAnalysis);
router.get('/lot-traceability/:lotId', exporterReportController.getLotTraceability);
router.get('/receivables-aging', exporterReportController.getReceivablesAging);
router.get('/payables-aging', exporterReportController.getPayablesAging);
router.get('/expenses', exporterReportController.getExpenseReport);

module.exports = router;
