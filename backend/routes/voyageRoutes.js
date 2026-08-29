const express = require('express');
const router = express.Router();
const voyageController = require('../controllers/voyageController');
const { authenticate } = require('../middleware/authmiddleware');

router.use(authenticate);

// 1. Get active voyages for agent
router.get('/active', voyageController.getActiveVoyages);

// 2. Get voyages by boat
router.get('/boat/:boatId', voyageController.getVoyagesByBoat);

module.exports = router;
