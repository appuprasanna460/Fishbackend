const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { authenticate } = require('../middleware/authmiddleware');
const { authorize } = require('../middleware/rbacmiddleware');
const { validate } = require('../middleware/validatemiddleware');
const boatOwnerController = require('../controllers/boatownercontroller');
const crewController = require('../controllers/crewController');
const voyageController = require('../controllers/voyageController');
const fishController = require('../controllers/fishcontroller');
const haulController = require('../controllers/haulController');
const catchController = require('../controllers/catchController');
const fishingGroundController = require('../controllers/fishingGroundController');
const gpsTrackController = require('../controllers/gpsTrackController');
const voyageExpenseController = require('../controllers/voyageExpenseController');
const returnEntryController = require('../controllers/returnEntryController');
const landingEntryController = require('../controllers/landingEntryController');
const voyageChecklistController = require('../controllers/voyageChecklistController');
const financialController = require('../controllers/financialController');
// ─── Validation Schemas ───────────────────────────────────────────────────────

const objectId = Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({ 'string.pattern.base': 'Invalid ID format' });

// Fishing Location
const saveFishingLocationSchema = Joi.object({
    boatId: objectId.required().messages({ 'any.required': 'Boat ID is required' }),
    date: Joi.date().default(() => new Date()),
    latitude: Joi.number().required().min(-90).max(90).messages({
        'number.min': 'Latitude must be between -90 and 90',
        'number.max': 'Latitude must be between -90 and 90',
        'any.required': 'Latitude is required',
    }),
    longitude: Joi.number().required().min(-180).max(180).messages({
        'number.min': 'Longitude must be between -180 and 180',
        'number.max': 'Longitude must be between -180 and 180',
        'any.required': 'Longitude is required',
    }),
});

const fishingLocationQuerySchema = Joi.object({
    boatId: objectId,
    fromDate: Joi.date(),
    toDate: Joi.date().greater(Joi.ref('fromDate')).messages({
        'date.greater': 'toDate must be after fromDate',
    }),
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(500).default(10),
});

// Manual Ledger
const INCOME_CATEGORIES = ['FISH_SALE', 'OTHER_INCOME'];
const EXPENSE_CATEGORIES = ['DIESEL', 'FUEL', 'ICE', 'LABOUR', 'FOOD', 'REPAIR', 'MAINTENANCE', 'OTHER_EXPENSE'];

const createLedgerSchema = Joi.object({
    boatId: objectId.required().messages({ 'any.required': 'Boat ID is required' }),
    date: Joi.date().default(() => new Date()),
    type: Joi.string().valid('INCOME', 'EXPENSE').required().messages({
        'any.only': 'Type must be INCOME or EXPENSE',
        'any.required': 'Type is required',
    }),
    category: Joi.string()
        .valid(...INCOME_CATEGORIES, ...EXPENSE_CATEGORIES)
        .required()
        .messages({
            'any.only': 'Invalid category',
            'any.required': 'Category is required',
        }),
    amount: Joi.number().required().min(0.01).messages({
        'number.min': 'Amount must be greater than 0',
        'any.required': 'Amount is required',
    }),
    description: Joi.string().max(500).allow('', null),
});

const updateLedgerSchema = Joi.object({
    boatId: objectId,
    date: Joi.date(),
    type: Joi.string().valid('INCOME', 'EXPENSE'),
    category: Joi.string().valid(...INCOME_CATEGORIES, ...EXPENSE_CATEGORIES),
    amount: Joi.number().min(0.01),
    description: Joi.string().max(500).allow('', null),
}).min(1); // At least one field must be provided

const ledgerQuerySchema = Joi.object({
    boatId: objectId,
    type: Joi.string().valid('INCOME', 'EXPENSE'),
    category: Joi.string().valid(...INCOME_CATEGORIES, ...EXPENSE_CATEGORIES),
    fromDate: Joi.date(),
    toDate: Joi.date().greater(Joi.ref('fromDate')).messages({
        'date.greater': 'toDate must be after fromDate',
    }),
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(500).default(10),
});

// Bills
const billQuerySchema = Joi.object({
    boatId: objectId,
    fromDate: Joi.date(),
    toDate: Joi.date(),
    createdBy: objectId,
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(500).default(10),
});

const idParamSchema = Joi.object({
    id: objectId.required(),
});

// Crew Validations
const createCrewSchema = Joi.object({
    name: Joi.string().required().min(2).messages({ 'any.required': 'Name is required' }),
    age: Joi.number().required().min(18).messages({ 'any.required': 'Age is required' }),
    phone: Joi.string().required().pattern(/^[0-9]{10}$/).messages({ 'string.pattern.base': 'Phone must be 10 digits', 'any.required': 'Phone number is required' }),
    location: Joi.string().required().min(2).messages({ 'any.required': 'Location is required' }),
    role: Joi.string().required().valid('CAPTAIN', 'CREW').messages({ 'any.only': 'Role must be CAPTAIN or CREW' }),
    experience: Joi.number().min(0).default(0),
    notes: Joi.string().allow('', null)
});

const updateCrewSchema = Joi.object({
    name: Joi.string().min(2),
    age: Joi.number().min(18),
    phone: Joi.string().pattern(/^[0-9]{10}$/),
    location: Joi.string().min(2),
    role: Joi.string().valid('CAPTAIN', 'CREW'),
    experience: Joi.number().min(0),
    notes: Joi.string().allow('', null)
}).min(1);

// Voyage Validations
const createVoyageSchema = Joi.object({
    boatId: objectId.required(),
    captainId: objectId.required(),
    crewMembers: Joi.array().items(objectId).required().min(1),
    departureHarbour: objectId.required(),
    departureDate: Joi.date().required(),
    departureTime: Joi.string().required(),
    voyageType: Joi.string().required().valid('DEEP_SEA', 'UNDERDEEP'),
    expectedDuration: Joi.string().required().valid('5-7_DAYS', '8-9_DAYS'),
    targetSpecies: Joi.array().items(objectId).allow(null),
    supplies: Joi.object({
        fuelRequired: Joi.number().required().min(0),
        fuelInTank: Joi.number().required().min(0),
        iceRequired: Joi.number().required().min(0),
        iceInStock: Joi.number().required().min(0),
        water: Joi.number().required().min(0),
        foodSupplies: Joi.string().allow('', null),
        otherSupplies: Joi.string().allow('', null)
    }).required(),
    notes: Joi.string().allow('', null)
});

const updateVoyageSchema = Joi.object({
    boatId: objectId,
    captainId: objectId,
    crewMembers: Joi.array().items(objectId).min(1),
    departureHarbour: objectId,
    departureDate: Joi.date(),
    departureTime: Joi.string(),
    voyageType: Joi.string().valid('DEEP_SEA', 'UNDERDEEP'),
    expectedDuration: Joi.string().valid('5-7_DAYS', '8-9_DAYS'),
    targetSpecies: Joi.array().items(objectId).allow(null),
    supplies: Joi.object({
        fuelRequired: Joi.number().min(0),
        fuelInTank: Joi.number().min(0),
        iceRequired: Joi.number().min(0),
        iceInStock: Joi.number().min(0),
        water: Joi.number().min(0),
        foodSupplies: Joi.string().allow('', null),
        otherSupplies: Joi.string().allow('', null)
    }),
    checklist: Joi.object().unknown(true).allow(null),
    notes: Joi.string().allow('', null)
}).min(1);

const updateVoyageStatusSchema = Joi.object({
    status: Joi.string().required().valid('ACTIVE', 'COMPLETED', 'CANCELLED')
});

// ─── Middleware ───────────────────────────────────────────────────────────────

// All routes: authenticate + BOAT_OWNER only
router.use(authenticate);
router.use(authorize('BOAT_OWNER', 'SUPER_ADMIN'));

// ─── Dashboard ───────────────────────────────────────────────────────────────
router.get('/dashboard', boatOwnerController.getDashboard);

// ─── Bills ───────────────────────────────────────────────────────────────────
router.get('/bills',
    validate(billQuerySchema, 'query'),
    boatOwnerController.getBills
);

router.get('/bills/:id',
    validate(idParamSchema, 'params'),
    boatOwnerController.getBillById
);

// ─── Manual Ledger ────────────────────────────────────────────────────────────

// IMPORTANT: /ledger/summary must come before /ledger/:id to avoid "summary" being matched as an id param
router.get('/ledger/summary',
    validate(ledgerQuerySchema, 'query'),
    boatOwnerController.getLedgerSummary
);

router.get('/ledger',
    validate(ledgerQuerySchema, 'query'),
    boatOwnerController.getLedger
);

router.post('/ledger',
    validate(createLedgerSchema),
    boatOwnerController.createLedgerEntry
);

router.put('/ledger/:id',
    validate(idParamSchema, 'params'),
    validate(updateLedgerSchema),
    boatOwnerController.updateLedgerEntry
);

router.delete('/ledger/:id',
    validate(idParamSchema, 'params'),
    boatOwnerController.deleteLedgerEntry
);

// ─── Fishing Locations ────────────────────────────────────────────────────────
router.post('/fishing-locations',
    validate(saveFishingLocationSchema),
    boatOwnerController.saveFishingLocation
);

router.get('/fishing-locations',
    validate(fishingLocationQuerySchema, 'query'),
    boatOwnerController.getFishingLocations
);

router.delete('/fishing-locations/:id',
    validate(idParamSchema, 'params'),
    boatOwnerController.deleteFishingLocation
);

// ─── Profile ──────────────────────────────────────────────────────────────────
router.get('/profile', boatOwnerController.getProfile);

// ─── Team / Company Users ────────────────────────────────────────────────────
router.get('/team', boatOwnerController.getTeamMembers);
router.post('/team', boatOwnerController.createTeamMember);
router.put('/team/:id', validate(idParamSchema, 'params'), boatOwnerController.updateTeamMember);
router.delete('/team/:id', validate(idParamSchema, 'params'), boatOwnerController.deleteTeamMember);
router.patch('/team/:id/toggle-status', validate(idParamSchema, 'params'), boatOwnerController.toggleTeamMemberStatus);

// ─── Crew Routes ──────────────────────────────────────────────────────────────
router.post('/crew', validate(createCrewSchema), crewController.createCrew);
router.get('/crew', crewController.getCrew);
router.get('/crew/available/captains', crewController.getAvailableCaptains);
router.get('/crew/available/crew', crewController.getAvailableCrew);
router.get('/crew/:id', validate(idParamSchema, 'params'), crewController.getCrewById);
router.put('/crew/:id', validate(idParamSchema, 'params'), validate(updateCrewSchema), crewController.updateCrew);
router.put('/crew/:id/availability', validate(idParamSchema, 'params'), crewController.toggleAvailability);
router.delete('/crew/:id', validate(idParamSchema, 'params'), crewController.deleteCrew);

// ─── Voyage Routes ────────────────────────────────────────────────────────────
router.post('/voyages', validate(createVoyageSchema), voyageController.createVoyage);
router.get('/voyages', voyageController.getVoyages);
router.get('/voyages/stats', voyageController.getVoyageStats);
router.get('/voyages/:id', validate(idParamSchema, 'params'), voyageController.getVoyageById);
router.put('/voyages/:id', validate(idParamSchema, 'params'), validate(updateVoyageSchema), voyageController.updateVoyage);
router.put('/voyages/:id/status', validate(idParamSchema, 'params'), validate(updateVoyageStatusSchema), voyageController.updateVoyageStatus);
router.delete('/voyages/:id', validate(idParamSchema, 'params'), voyageController.deleteVoyage);

// ─── Catch Summary (voyage-level) ─────────────────────────────────────────────
router.get('/voyages/:voyageId/catch-summary', catchController.getCatchSummaryByVoyage);

// ─── Voyage Expenses ──────────────────────────────────────────────────────────
const saveExpenseSchema = Joi.object({
    voyageId: objectId.required(),
    boatId: objectId.required(),
    date: Joi.date().required(),
    fuelUsed: Joi.number().min(0).default(0),
    iceUsed: Joi.number().min(0).default(0),
    waterUsed: Joi.number().min(0).default(0),
    notes: Joi.string().allow('', null),
});
router.get('/voyage-expenses/:voyageId', voyageExpenseController.getVoyageExpenses);
router.post('/voyage-expenses', validate(saveExpenseSchema), voyageExpenseController.saveVoyageExpenses);

// ─── Return Entry Routes ───
router.get('/voyages/:voyageId/return-entry', returnEntryController.getReturnEntry);
router.post('/voyages/:voyageId/return-entry', returnEntryController.saveReturnEntry);

// ─── Landing Entry Routes ───
router.get('/voyages/:voyageId/landing-entry', landingEntryController.getLandingEntry);
router.post('/voyages/:voyageId/landing-entry', landingEntryController.saveLandingEntry);

// ─── Voyage Checklist Routes ───
router.get('/voyages/:voyageId/checklist-details', voyageChecklistController.getChecklist);
router.post('/voyages/:voyageId/checklist-details', voyageChecklistController.saveChecklist);

// ─── Fish Routes ──────────────────────────────────────────────────────────────
router.get('/fish', fishController.getFish);

// ─── Haul Routes ──────────────────────────────────────────────────────────────
router.post('/hauls', haulController.startHaul);
router.get('/hauls', haulController.getHauls);
router.get('/hauls/active', haulController.getActiveHaul);
router.get('/hauls/recent', haulController.getRecentHauls);
router.get('/hauls/:id', validate(idParamSchema, 'params'), haulController.getHaulById);
router.put('/hauls/:id/gps', validate(idParamSchema, 'params'), haulController.updateGpsTrack);
router.put('/hauls/:id/stop', validate(idParamSchema, 'params'), haulController.stopHaul);

// ─── Catch Routes ─────────────────────────────────────────────────────────────
router.post('/catches', catchController.createCatch);
router.get('/catches/haul/:haulId', catchController.getCatchesByHaul);
router.get('/catches/pending/:haulId', catchController.hasPendingCatch);
router.get('/catches/:id', validate(idParamSchema, 'params'), catchController.getCatchById);
router.put('/catches/:id', validate(idParamSchema, 'params'), catchController.updateCatch);
router.delete('/catches/:id', validate(idParamSchema, 'params'), catchController.deleteCatch);

// ─── Fishing Ground Routes ────────────────────────────────────────────────────
router.get('/fishing-grounds', fishingGroundController.getFishingGrounds);
router.get('/fishing-grounds/favourites', fishingGroundController.getFavouriteGrounds);
router.get('/fishing-grounds/history', fishingGroundController.getGroundHistory);
router.put('/fishing-grounds/:id/favourite', validate(idParamSchema, 'params'), fishingGroundController.toggleFavourite);

// ─── GPS Track Routes ─────────────────────────────────────────────────────────
// History list (summary, with trackPreview, supports ?period=today|week|month)
router.get('/gps-tracks/history', gpsTrackController.getTrackHistory);
// Full voyage detail (complete GPS track for map view)
router.get('/gps-tracks/voyage/:voyageId/detail', gpsTrackController.getVoyageTrackDetail);
// By voyage / haul (raw haul-level tracks)
router.get('/gps-tracks/voyage/:voyageId', gpsTrackController.getTracksByVoyage);
router.get('/gps-tracks/haul/:haulId', gpsTrackController.getTracksByHaul);
router.get('/gps-tracks', gpsTrackController.getTracks);
router.get('/gps-tracks/summary/:voyageId', gpsTrackController.getTrackSummary);

// ─── Financial Management Routes ─────────────────────────────────────────────
router.get('/financial/dashboard', financialController.getFinancialDashboard);
router.get('/financial/voyages', financialController.getVoyagesPLList);
router.get('/financial/voyages/:voyageId', financialController.getVoyagePLSummary);
router.put('/financial/voyages/:voyageId/income', financialController.upsertCatchRates);
router.post('/financial/voyages/:voyageId/other-income', financialController.addOtherIncome);
router.delete('/financial/voyages/:voyageId/other-income/:id', financialController.deleteOtherIncome);
router.put('/financial/voyages/:voyageId/expenses', financialController.upsertVoyageExpenses);
router.post('/financial/voyages/:voyageId/custom-expenses', financialController.addCustomExpense);
router.delete('/financial/voyages/:voyageId/custom-expenses/:id', financialController.deleteCustomExpense);
router.put('/financial/voyages/:voyageId/crew-settlement', financialController.upsertCrewSettlement);

module.exports = router;
