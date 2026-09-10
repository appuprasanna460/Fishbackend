const customerService = require('../services/customerService');

const getCustomers = async (req, res, next) => {
    try {
        const customers = await customerService.listCustomers(req.user.exporterId);
        return res.json({ success: true, data: customers });
    } catch (error) {
        next(error);
    }
};

const createCustomer = async (req, res, next) => {
    try {
        const customer = await customerService.createCustomer(req.user.exporterId, req.body);
        return res.status(201).json({ success: true, message: 'Customer created successfully', data: customer });
    } catch (error) {
        next(error);
    }
};

const updateCustomer = async (req, res, next) => {
    try {
        const customer = await customerService.updateCustomer(req.user.exporterId, req.params.id, req.body);
        return res.json({ success: true, message: 'Customer updated successfully', data: customer });
    } catch (error) {
        next(error);
    }
};

const deleteCustomer = async (req, res, next) => {
    try {
        const result = await customerService.deleteCustomer(req.user.exporterId, req.params.id);
        return res.json(result);
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getCustomers,
    createCustomer,
    updateCustomer,
    deleteCustomer
};
