// routes/boatroutes.js
const express = require('express');
const router = express.Router();
const boatController = require('../controllers/boatcontroller');
const { authenticate } = require('../middleware/authmiddleware');
const { authorize } = require('../middleware/rbacmiddleware');
const { validate } = require('../middleware/validatemiddleware');
const { auditLog } = require('../middleware/auditLogmiddleware');
const {
    createBoatSchema,
    updateBoatSchema,
    boatIdSchema,
    boatListQuerySchema
} = require('../validations/boatvalidation');

const multer = require('multer');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'), false);
        }
    }
});

// All boat routes require authentication
router.use(authenticate);

// ✅ Upload boat profile image to AWS S3
router.post('/upload-image',
    authorize('COMMISSION_AGENT', 'SUPER_ADMIN', 'BOAT_OWNER'),
    upload.single('image'),
    boatController.uploadBoatImage
);

// Get boats (filtered by role)
router.get('/',
    authorize('SUPER_ADMIN', 'COMMISSION_AGENT', 'BOAT_OWNER', 'FISH_BUYER', 'CAPTAIN', 'CREW', 'MECHANIC', 'ACCOUNTANT'),
    validate(boatListQuerySchema, 'query'),
    boatController.getBoats
);

// ✅ Allow BOAT_OWNER to create their own boats
router.post('/',
    authorize('COMMISSION_AGENT', 'SUPER_ADMIN', 'BOAT_OWNER'), // ✅ Added BOAT_OWNER
    validate(createBoatSchema),
    auditLog,
    boatController.createBoat
);

// Get boats by owner
router.get('/owner/:ownerId',
    authorize('BOAT_OWNER', 'COMMISSION_AGENT', 'SUPER_ADMIN'),
    boatController.getBoatsByOwner
);

// Get boats by agent
router.get('/agent/:agentId',
    authorize('COMMISSION_AGENT', 'SUPER_ADMIN', 'STAFF'),
    boatController.getBoatsByAgent
);

// Get boat by ID (with ownership check)
router.get('/:id',
    validate(boatIdSchema, 'params'),
    boatController.getBoatById
);

// ✅ Allow BOAT_OWNER to update their own boats
router.put('/:id',
    authorize('COMMISSION_AGENT', 'SUPER_ADMIN', 'BOAT_OWNER'), // ✅ Added BOAT_OWNER
    validate(boatIdSchema, 'params'),
    validate(updateBoatSchema),
    auditLog,
    boatController.updateBoat
);

// ✅ Allow BOAT_OWNER to delete their own boats
router.delete('/:id',
    authorize('COMMISSION_AGENT', 'SUPER_ADMIN', 'BOAT_OWNER'), // ✅ Added BOAT_OWNER
    validate(boatIdSchema, 'params'),
    auditLog,
    boatController.deleteBoat
);

module.exports = router;