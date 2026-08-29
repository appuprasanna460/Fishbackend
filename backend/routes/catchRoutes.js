const express = require('express');
const router = express.Router();
const catchController = require('../controllers/catchController');
const { authenticate } = require('../middleware/authmiddleware');

router.use(authenticate);

// 2. Get catches for voyage
router.get('/voyage/:voyageId', catchController.getCatchesByVoyage);

// 3. Add new catch
router.post('/', catchController.createCatch);

// 4. Update catch rate
router.put('/:catchId/rate', catchController.updateCatchRate);

module.exports = router;
