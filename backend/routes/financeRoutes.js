const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/receivables', financeController.getReceivables);
router.get('/receivables/aging', financeController.getReceivablesAging);
router.post('/receivables/payment', authorizeExporterRoles('ACCOUNTANT', 'DOMESTIC_EXPORTER'), financeController.recordReceivablePayment);

router.get('/payables', financeController.getPayables);
router.get('/payables/aging', financeController.getPayablesAging);
router.post('/payables/payment', authorizeExporterRoles('ACCOUNTANT', 'DOMESTIC_EXPORTER'), financeController.recordPayablePayment);

router.get('/customers/:id/ledger', financeController.getCustomerLedger);
router.get('/suppliers/:id/ledger', financeController.getSupplierLedger);

router.get('/pl', authorizeExporterRoles('ACCOUNTANT', 'DOMESTIC_EXPORTER'), financeController.getPLReport);
router.post('/expenses', authorizeExporterRoles('ACCOUNTANT', 'WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), financeController.addExpense);

module.exports = router;
