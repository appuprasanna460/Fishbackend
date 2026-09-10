const Customer = require('../models/customerModel');

const listCustomers = async (exporterId) => {
    return await Customer.find({ exporterId, isDeleted: false }).sort({ name: 1 });
};

const createCustomer = async (exporterId, data) => {
    const customer = new Customer({ ...data, exporterId });
    return await customer.save();
};

const updateCustomer = async (exporterId, id, data) => {
    const customer = await Customer.findOne({ _id: id, exporterId, isDeleted: false });
    if (!customer) throw new Error('Customer not found');
    delete data.exporterId;
    Object.assign(customer, data);
    return await customer.save();
};

const deleteCustomer = async (exporterId, id) => {
    const customer = await Customer.findOne({ _id: id, exporterId, isDeleted: false });
    if (!customer) throw new Error('Customer not found');
    customer.isDeleted = true;
    customer.isActive = false;
    await customer.save();
    return { success: true };
};

module.exports = {
    listCustomers,
    createCustomer,
    updateCustomer,
    deleteCustomer
};
