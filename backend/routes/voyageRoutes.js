const express = require('express');
const router = express.Router();
const voyageController = require('../controllers/voyageController');
const { authenticate } = require('../middleware/authmiddleware');

const multer = require('multer');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 }
});

router.use(authenticate);

// 1. Get active voyages for agent
router.get('/active', voyageController.getActiveVoyages);

// 2. Get voyages by boat
router.get('/boat/:boatId', voyageController.getVoyagesByBoat);

// 3. Admin Voyage Token endpoints
router.get('/tokens', voyageController.getAdminVoyageTokens);
router.post('/tokens/:id/approve', upload.single('tokenImage'), voyageController.approveVoyageToken);

module.exports = router;
