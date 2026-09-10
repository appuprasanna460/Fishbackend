const gradeMasterService = require('../services/gradeMasterService');

const getGrades = async (req, res, next) => {
    try {
        const grades = await gradeMasterService.listGrades(req.user.exporterId);
        return res.json({ success: true, data: grades });
    } catch (error) {
        next(error);
    }
};

const createGrade = async (req, res, next) => {
    try {
        const grade = await gradeMasterService.createGrade(req.user.exporterId, req.body);
        return res.status(201).json({ success: true, message: 'Grade created successfully', data: grade });
    } catch (error) {
        next(error);
    }
};

const updateGrade = async (req, res, next) => {
    try {
        const grade = await gradeMasterService.updateGrade(req.user.exporterId, req.params.id, req.body);
        return res.json({ success: true, message: 'Grade updated successfully', data: grade });
    } catch (error) {
        next(error);
    }
};

const toggleGradeStatus = async (req, res, next) => {
    try {
        const grade = await gradeMasterService.toggleGradeStatus(req.user.exporterId, req.params.id);
        return res.json({ success: true, message: 'Grade status updated', data: grade });
    } catch (error) {
        next(error);
    }
};

const deleteGrade = async (req, res, next) => {
    try {
        const result = await gradeMasterService.deleteGrade(req.user.exporterId, req.params.id);
        return res.json(result);
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getGrades,
    createGrade,
    updateGrade,
    toggleGradeStatus,
    deleteGrade
};
