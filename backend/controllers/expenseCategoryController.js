const expenseCategoryService = require('../services/expenseCategoryService');

const getCategories = async (req, res, next) => {
    try {
        const categories = await expenseCategoryService.listCategories(req.user.exporterId);
        return res.json({ success: true, data: categories });
    } catch (error) {
        next(error);
    }
};

const createCategory = async (req, res, next) => {
    try {
        const category = await expenseCategoryService.createCategory(req.user.exporterId, req.body);
        return res.status(201).json({ success: true, message: 'Expense category created', data: category });
    } catch (error) {
        next(error);
    }
};

const updateCategory = async (req, res, next) => {
    try {
        const category = await expenseCategoryService.updateCategory(req.user.exporterId, req.params.id, req.body);
        return res.json({ success: true, message: 'Expense category updated', data: category });
    } catch (error) {
        next(error);
    }
};

const toggleCategoryStatus = async (req, res, next) => {
    try {
        const category = await expenseCategoryService.toggleCategoryStatus(req.user.exporterId, req.params.id);
        return res.json({ success: true, message: 'Expense category status updated', data: category });
    } catch (error) {
        next(error);
    }
};

const deleteCategory = async (req, res, next) => {
    try {
        const result = await expenseCategoryService.deleteCategory(req.user.exporterId, req.params.id);
        return res.json(result);
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getCategories,
    createCategory,
    updateCategory,
    toggleCategoryStatus,
    deleteCategory
};
