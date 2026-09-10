const ExpenseCategory = require('../models/expenseCategoryModel');

const listCategories = async (exporterId) => {
    return await ExpenseCategory.find({ exporterId }).sort({ name: 1 });
};

const createCategory = async (exporterId, data) => {
    const category = new ExpenseCategory({ ...data, exporterId });
    return await category.save();
};

const updateCategory = async (exporterId, id, data) => {
    const category = await ExpenseCategory.findOne({ _id: id, exporterId });
    if (!category) throw new Error('Expense category not found');
    delete data.isSystem;
    delete data.exporterId;
    Object.assign(category, data);
    return await category.save();
};

const toggleCategoryStatus = async (exporterId, id) => {
    const category = await ExpenseCategory.findOne({ _id: id, exporterId });
    if (!category) throw new Error('Expense category not found');
    category.isActive = !category.isActive;
    return await category.save();
};

const deleteCategory = async (exporterId, id) => {
    const category = await ExpenseCategory.findOne({ _id: id, exporterId });
    if (!category) throw new Error('Expense category not found');
    if (category.isSystem) throw new Error('Cannot delete system default expense category');
    await category.deleteOne();
    return { success: true };
};

module.exports = {
    listCategories,
    createCategory,
    updateCategory,
    toggleCategoryStatus,
    deleteCategory
};
