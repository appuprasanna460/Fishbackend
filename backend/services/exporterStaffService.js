const User = require('../models/usermodel');
const s3Service = require('./s3Service');

const STAFF_ROLES = ['PURCHASE_STAFF', 'WAREHOUSE_STAFF', 'SALES_STAFF', 'ACCOUNTANT'];

const listStaff = async (exporterId) => {
    return await User.find({
        exporterId,
        role: { $in: STAFF_ROLES },
        isDeleted: { $ne: true }
    }).select('-password').sort({ createdAt: -1 });
};

const createStaff = async (exporterId, data) => {
    if (!STAFF_ROLES.includes(data.role)) {
        throw new Error(`Invalid role. Exporter staff role must be one of: ${STAFF_ROLES.join(', ')}`);
    }

    const existingUser = await User.findOne({ email: data.email.toLowerCase().trim() });
    if (existingUser) {
        throw new Error('User with this email already exists');
    }

    const staffData = {
        ...data,
        exporterId,
        ownerId: exporterId,
        isApproved: true,
        isActive: data.isActive !== undefined ? data.isActive : true
    };

    const staff = new User(staffData);
    await staff.save();
    return staff;
};

const updateStaff = async (exporterId, staffId, data) => {
    const staff = await User.findById(staffId);
    if (!staff || staff.isDeleted) {
        throw new Error('Staff member not found');
    }

    if (staff.exporterId && staff.exporterId.toString() !== exporterId.toString()) {
        throw new Error('Access denied. Staff does not belong to this exporter.');
    }

    if (data.role && !STAFF_ROLES.includes(data.role)) {
        throw new Error(`Invalid role. Exporter staff role must be one of: ${STAFF_ROLES.join(', ')}`);
    }

    delete data.password;
    delete data.exporterId;
    delete data.ownerId;

    Object.assign(staff, data);
    await staff.save();
    return staff;
};

const toggleStaffStatus = async (exporterId, staffId) => {
    const staff = await User.findById(staffId);
    if (!staff || staff.isDeleted) {
        throw new Error('Staff member not found');
    }
    if (staff.exporterId && staff.exporterId.toString() !== exporterId.toString()) {
        throw new Error('Access denied.');
    }

    staff.isActive = !staff.isActive;
    await staff.save();
    return staff;
};

const deleteStaff = async (exporterId, staffId) => {
    const staff = await User.findById(staffId);
    if (!staff || staff.isDeleted) {
        throw new Error('Staff member not found');
    }
    if (staff.exporterId && staff.exporterId.toString() !== exporterId.toString()) {
        throw new Error('Access denied.');
    }

    staff.isDeleted = true;
    staff.isActive = false;
    await staff.save();
    return { success: true, message: 'Staff deleted successfully' };
};

const uploadStaffDocument = async (exporterId, staffId, file, documentName) => {
    const staff = await User.findById(staffId);
    if (!staff || staff.isDeleted) {
        throw new Error('Staff member not found');
    }
    if (staff.exporterId && staff.exporterId.toString() !== exporterId.toString()) {
        throw new Error('Access denied.');
    }

    const s3Result = await s3Service.uploadFile(file, 'staff-documents');
    staff.documents = staff.documents || [];
    staff.documents.push({
        name: documentName || file.originalname,
        url: s3Result.url,
        key: s3Result.key,
        uploadedAt: new Date()
    });

    await staff.save();
    return staff;
};

const deleteStaffDocument = async (exporterId, staffId, documentId) => {
    const staff = await User.findById(staffId);
    if (!staff || staff.isDeleted) {
        throw new Error('Staff member not found');
    }
    if (staff.exporterId && staff.exporterId.toString() !== exporterId.toString()) {
        throw new Error('Access denied.');
    }

    const doc = staff.documents.id(documentId);
    if (doc) {
        try {
            await s3Service.deleteFile(doc.key);
        } catch (_) {}
        doc.deleteOne();
        await staff.save();
    }
    return staff;
};

module.exports = {
    listStaff,
    createStaff,
    updateStaff,
    toggleStaffStatus,
    deleteStaff,
    uploadStaffDocument,
    deleteStaffDocument
};
