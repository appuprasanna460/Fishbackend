const User = require('../models/usermodel');
const UnitMaster = require('../models/unitMasterModel');
const ExpenseCategory = require('../models/expenseCategoryModel');
const GradeMaster = require('../models/gradeMasterModel');

const provisionExporter = async (userId) => {
    const user = await User.findById(userId);
    if (!user) {
        throw new Error('User not found for provisioning');
    }

    user.exporterId = user._id;
    await user.save();

    const exporterId = user._id;

    // Seed default UnitMaster
    const defaultUnits = [
        { name: 'KG', symbol: 'kg', sortOrder: 1 },
        { name: 'Box', symbol: 'box', sortOrder: 2 },
        { name: 'Net', symbol: 'net', sortOrder: 3 },
        { name: 'Satti', symbol: 'sat', sortOrder: 4 },
        { name: 'Basket', symbol: 'bsk', sortOrder: 5 }
    ];

    for (const unit of defaultUnits) {
        await UnitMaster.findOneAndUpdate(
            { exporterId, name: unit.name },
            { exporterId, ...unit, isSystem: true, isActive: true },
            { upsert: true, new: true }
        );
    }

    // Seed default ExpenseCategory
    const defaultCategories = [
        'Ice', 'Packing', 'Handling', 'Transport', 'Fuel', 'Labour', 'Market Charges', 'Other'
    ];

    for (const category of defaultCategories) {
        await ExpenseCategory.findOneAndUpdate(
            { exporterId, name: category },
            { exporterId, name: category, isSystem: true, isActive: true },
            { upsert: true, new: true }
        );
    }

    // Seed default GradeMaster
    const defaultGrades = [
        { name: 'A', description: 'Premium Grade', sortOrder: 1 },
        { name: 'B', description: 'Standard Grade', sortOrder: 2 },
        { name: 'C', description: 'Commercial Grade', sortOrder: 3 }
    ];

    for (const grade of defaultGrades) {
        await GradeMaster.findOneAndUpdate(
            { exporterId, name: grade.name },
            { exporterId, ...grade, isActive: true },
            { upsert: true, new: true }
        );
    }

    return { success: true, message: 'Exporter provisioned successfully' };
};

module.exports = {
    provisionExporter
};
