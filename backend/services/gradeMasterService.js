const GradeMaster = require('../models/gradeMasterModel');

const listGrades = async (exporterId) => {
    return await GradeMaster.find({ exporterId }).sort({ sortOrder: 1, name: 1 });
};

const createGrade = async (exporterId, data) => {
    const grade = new GradeMaster({ ...data, exporterId });
    return await grade.save();
};

const updateGrade = async (exporterId, id, data) => {
    const grade = await GradeMaster.findOne({ _id: id, exporterId });
    if (!grade) throw new Error('Grade not found');
    delete data.exporterId;
    Object.assign(grade, data);
    return await grade.save();
};

const toggleGradeStatus = async (exporterId, id) => {
    const grade = await GradeMaster.findOne({ _id: id, exporterId });
    if (!grade) throw new Error('Grade not found');
    grade.isActive = !grade.isActive;
    return await grade.save();
};

const deleteGrade = async (exporterId, id) => {
    const grade = await GradeMaster.findOne({ _id: id, exporterId });
    if (!grade) throw new Error('Grade not found');
    await grade.deleteOne();
    return { success: true };
};

module.exports = {
    listGrades,
    createGrade,
    updateGrade,
    toggleGradeStatus,
    deleteGrade
};
