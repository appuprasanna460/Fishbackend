const express = require('express');
const router = express.Router();
const dispatchController = require('../controllers/dispatchController');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');
const checkIdempotency = require('../middleware/idempotencyMiddleware');

router.use(authenticateExporterUser);

router.get('/', dispatchController.getDispatches);
router.post('/', checkIdempotency, authorizeExporterRoles('SALES_STAFF', 'WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), dispatchController.createDispatch);
router.post('/:id/deliver', checkIdempotency, authorizeExporterRoles('SALES_STAFF', 'WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), dispatchController.deliverDispatch);
router.patch('/:id/status', authorizeExporterRoles('SALES_STAFF', 'WAREHOUSE_STAFF', 'DOMESTIC_EXPORTER'), dispatchController.updateDispatchStatus);

module.exports = router;
