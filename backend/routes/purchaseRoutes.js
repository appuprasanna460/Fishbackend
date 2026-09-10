const express = require('express');
const router = express.Router();
const purchaseController = require('../controllers/purchaseController');
const { authenticateExporterUser, authorizeExporterRoles } = require('../middleware/exporterMiddleware');
const checkIdempotency = require('../middleware/idempotencyMiddleware');

// Public lookup for harbour sellers dropdown
router.get('/sellers', purchaseController.getSellersByHarbour);

router.use(authenticateExporterUser);

router.get('/summary', purchaseController.getPurchaseSummary);
router.get('/harbour/:id/staff', purchaseController.getHarbourStaff);

router.get('/', purchaseController.getPurchases);
router.get('/:id', purchaseController.getPurchaseById);

router.post('/draft', authorizeExporterRoles('PURCHASE_STAFF', 'DOMESTIC_EXPORTER'), purchaseController.saveDraft);
router.post('/:id/confirm', checkIdempotency, authorizeExporterRoles('PURCHASE_STAFF', 'DOMESTIC_EXPORTER'), purchaseController.confirmPurchase);
router.post('/:id/reverse', authorizeExporterRoles('PURCHASE_STAFF', 'DOMESTIC_EXPORTER'), purchaseController.reversePurchase);

router.post('/', authorizeExporterRoles('PURCHASE_STAFF', 'DOMESTIC_EXPORTER'), purchaseController.createPurchase);
router.patch('/:id/status', authorizeExporterRoles('PURCHASE_STAFF', 'DOMESTIC_EXPORTER'), purchaseController.updatePurchaseStatus);

module.exports = router;
