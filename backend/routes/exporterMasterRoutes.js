const express = require('express');
const router = express.Router();
const unitMasterController = require('../controllers/unitMasterController');
const expenseCategoryController = require('../controllers/expenseCategoryController');
const gradeMasterController = require('../controllers/gradeMasterController');
const { authenticateExporterUser } = require('../middleware/exporterMiddleware');

router.use(authenticateExporterUser);

// Unit Master Routes
router.get('/units', unitMasterController.getUnits);
router.post('/units', unitMasterController.createUnit);
router.put('/units/:id', unitMasterController.updateUnit);
router.patch('/units/:id/toggle', unitMasterController.toggleUnitStatus);
router.delete('/units/:id', unitMasterController.deleteUnit);

// Expense Category Routes
router.get('/expense-categories', expenseCategoryController.getCategories);
router.post('/expense-categories', expenseCategoryController.createCategory);
router.put('/expense-categories/:id', expenseCategoryController.updateCategory);
router.patch('/expense-categories/:id/toggle', expenseCategoryController.toggleCategoryStatus);
router.delete('/expense-categories/:id', expenseCategoryController.deleteCategory);

// Grade Master Routes
router.get('/grades', gradeMasterController.getGrades);
router.post('/grades', gradeMasterController.createGrade);
router.put('/grades/:id', gradeMasterController.updateGrade);
router.patch('/grades/:id/toggle', gradeMasterController.toggleGradeStatus);
router.delete('/grades/:id', gradeMasterController.deleteGrade);

module.exports = router;
