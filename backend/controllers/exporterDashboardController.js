const exporterDashboardService = require('../services/exporterDashboardService');

const getDashboard = async (req, res, next) => {
    try {
        const dashboardData = await exporterDashboardService.getDashboard(req.user.exporterId);
        return res.json({ success: true, data: dashboardData });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getDashboard
};
