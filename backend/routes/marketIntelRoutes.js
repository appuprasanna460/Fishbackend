const express = require('express');
const router = express.Router();
const marketIntelController = require('../controllers/marketIntelligenceController');
const { authenticateExporterUser } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

router.get('/buy', marketIntelController.getBuyMarketRates);
router.get('/sell', marketIntelController.getSellMarketRates);
router.get('/trends', marketIntelController.getPriceTrends);
router.get('/opportunity', marketIntelController.getBestOpportunity);

module.exports = router;
