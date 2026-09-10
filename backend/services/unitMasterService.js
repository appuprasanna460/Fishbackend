const UnitMaster = require('../models/unitMasterModel');

const listUnits = async (exporterId) => {
    return await UnitMaster.find({ exporterId }).sort({ sortOrder: 1, name: 1 });
};

const createUnit = async (exporterId, data) => {
    const unit = new UnitMaster({ ...data, exporterId });
    return await unit.save();
};

const updateUnit = async (exporterId, id, data) => {
    const unit = await UnitMaster.findOne({ _id: id, exporterId });
    if (!unit) throw new Error('Unit not found');
    delete data.isSystem;
    delete data.exporterId;
    Object.assign(unit, data);
    return await unit.save();
};

const toggleUnitStatus = async (exporterId, id) => {
    const unit = await UnitMaster.findOne({ _id: id, exporterId });
    if (!unit) throw new Error('Unit not found');
    unit.isActive = !unit.isActive;
    return await unit.save();
};

const deleteUnit = async (exporterId, id) => {
    const unit = await UnitMaster.findOne({ _id: id, exporterId });
    if (!unit) throw new Error('Unit not found');
    if (unit.isSystem) throw new Error('Cannot delete system default unit');
    await unit.deleteOne();
    return { success: true };
};

module.exports = {
    listUnits,
    createUnit,
    updateUnit,
    toggleUnitStatus,
    deleteUnit
};
