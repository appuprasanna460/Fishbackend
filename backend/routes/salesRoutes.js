const express = require('express');
const router = express.Router();
const salesController = require('../controllers/salesController');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');
const checkIdempotency = require('../middleware/idempotencyMiddleware');

router.use(authenticateExporterUser);

router.get('/summary', salesController.getSalesSummary);
router.get('/', salesController.getSales);
router.get('/:id', salesController.getSaleById);

router.post('/', checkIdempotency, authorizeExporterRoles('SALES_STAFF', 'DOMESTIC_EXPORTER'), salesController.createSale);
router.post('/:id/cancel', authorizeExporterRoles('SALES_STAFF', 'DOMESTIC_EXPORTER'), salesController.cancelSale);
router.patch('/:id/status', authorizeExporterRoles('SALES_STAFF', 'DOMESTIC_EXPORTER'), salesController.updateSaleStatus);

module.exports = router;
