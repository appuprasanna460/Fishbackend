const User = require('../models/usermodel');
const { uploadToS3 } = require('./s3Service');
const bcrypt = require('bcryptjs');
const env = require('../config/env');
const logger = require('../config/logger');

class StaffService {
    /**
     * Map user document to staff response format
     */
    mapStaffResponse(user) {
        if (!user) return null;
        return {
            id: user._id,
            _id: user._id,
            name: user.name,
            age: user.age,
            phone: user.phone,
            address: user.address,
            email: user.email,
            emergencyContact: {
                name: user.emergencyContactName || '',
                relationship: user.emergencyContactRelationship || '',
                phone: user.emergencyContactPhone || ''
            },
            emergencyContactName: user.emergencyContactName || '',
            emergencyContactRelationship: user.emergencyContactRelationship || '',
            emergencyContactPhone: user.emergencyContactPhone || '',
            documents: user.documents || [],
            isActive: user.isActive,
            agentId: user.agentId,
            role: user.role,
            createdAt: user.createdAt
        };
    }

    /**
     * Get all staff under agent
     */
    async getStaffByAgent(agentId, search = '') {
        const query = {
            agentId,
            role: 'STAFF',
            isDeleted: false
        };

        if (search) {
            query.$or = [
                { name: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } }
            ];
        }

        const staffList = await User.find(query).sort({ createdAt: -1 });
        return staffList.map(s => this.mapStaffResponse(s));
    }

    /**
     * Create staff
     */
    async createStaff(data, agentId) {
        // Validate unique email
        const existingEmail = await User.findOne({
            email: data.email.toLowerCase().trim(),
            isDeleted: false
        });
        if (existingEmail) {
            throw new Error('Email is already registered');
        }

        // Validate Age (18 to 100)
        const age = Number(data.age);
        if (isNaN(age) || age < 18 || age > 100) {
            throw new Error('Age must be between 18 and 100');
        }

        // Validate Phone (10 digits)
        const phone = data.phone;
        if (!phone || !/^[0-9]{10}$/.test(phone)) {
            throw new Error('Phone number must be exactly 10 digits');
        }

        // Validate Password strength
        const password = data.password;
        if (!password || password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
            throw new Error('Password must be at least 8 characters, and contain at least 1 uppercase letter, 1 lowercase letter, and 1 number');
        }

        const newUser = new User({
            name: data.name,
            age,
            phone,
            address: data.address,
            email: data.email.toLowerCase().trim(),
            password,
            emergencyContactName: data.emergencyContactName,
            emergencyContactRelationship: data.emergencyContactRelationship,
            emergencyContactPhone: data.emergencyContactPhone,
            role: 'STAFF',
            agentId,
            isApproved: true,
            isActive: true
        });

        await newUser.save();
        logger.info(`Staff created: ${newUser.email} under agent ${agentId}`);
        return this.mapStaffResponse(newUser);
    }

    /**
     * Get staff profile preview
     */
    async getStaffProfile(staffId, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }
        return this.mapStaffResponse(staff);
    }

    /**
     * Update staff
     */
    async updateStaff(staffId, data, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }

        // Email validation if email is changing
        if (data.email && data.email.toLowerCase().trim() !== staff.email) {
            const existingEmail = await User.findOne({
                email: data.email.toLowerCase().trim(),
                _id: { $ne: staffId },
                isDeleted: false
            });
            if (existingEmail) {
                throw new Error('Email is already in use');
            }
            staff.email = data.email.toLowerCase().trim();
        }

        // Validate Age (18 to 100)
        if (data.age !== undefined) {
            const age = Number(data.age);
            if (isNaN(age) || age < 18 || age > 100) {
                throw new Error('Age must be between 18 and 100');
            }
            staff.age = age;
        }

        // Validate Phone (10 digits)
        if (data.phone !== undefined) {
            const phone = data.phone;
            if (!phone || !/^[0-9]{10}$/.test(phone)) {
                throw new Error('Phone number must be exactly 10 digits');
            }
            staff.phone = phone;
        }

        // Optional password update
        if (data.password) {
            const password = data.password;
            if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
                throw new Error('Password must be at least 8 characters, and contain at least 1 uppercase letter, 1 lowercase letter, and 1 number');
            }
            staff.password = password;
        }

        if (data.name) staff.name = data.name;
        if (data.address) staff.address = data.address;
        if (data.emergencyContactName) staff.emergencyContactName = data.emergencyContactName;
        if (data.emergencyContactRelationship) staff.emergencyContactRelationship = data.emergencyContactRelationship;
        if (data.emergencyContactPhone) staff.emergencyContactPhone = data.emergencyContactPhone;

        await staff.save();
        logger.info(`Staff updated: ${staff.email}`);
        return this.mapStaffResponse(staff);
    }

    /**
     * Toggle staff status
     */
    async toggleStaffStatus(staffId, isActive, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }

        staff.isActive = isActive;
        await staff.save();
        logger.info(`Staff status updated for ${staff.email} to ${isActive}`);
        return { id: staff._id, isActive: staff.isActive };
    }

    /**
     * Delete staff (soft delete)
     */
    async deleteStaff(staffId, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }

        staff.isDeleted = true;
        staff.isActive = false;
        await staff.save();
        logger.info(`Staff soft-deleted: ${staff.email}`);
    }

    /**
     * Upload staff document
     */
    async uploadDocument(staffId, file, documentName, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }

        // Upload to S3
        const folderPath = `staff/${staffId}/documents`;
        const { url, key } = await uploadToS3(file.buffer, file.originalname, file.mimetype, folderPath);

        const newDoc = {
            name: documentName || file.originalname,
            url,
            key,
            uploadedAt: new Date()
        };

        staff.documents.push(newDoc);
        await staff.save();

        // Get the inserted document (usually the last one added)
        const savedDoc = staff.documents[staff.documents.length - 1];
        logger.info(`Document uploaded for staff ${staff.email}: ${savedDoc.name}`);

        return {
            id: savedDoc._id || savedDoc.id,
            name: savedDoc.name,
            url: savedDoc.url,
            key: savedDoc.key,
            uploadedAt: savedDoc.uploadedAt
        };
    }

    /**
     * Delete staff document
     */
    async deleteDocument(staffId, documentId, agentId = null) {
        const query = { _id: staffId, role: 'STAFF', isDeleted: false };
        if (agentId) query.agentId = agentId;

        const staff = await User.findOne(query);
        if (!staff) {
            throw new Error('Staff member not found');
        }

        const documentIndex = staff.documents.findIndex(doc => (doc._id || doc.id).toString() === documentId.toString());
        if (documentIndex === -1) {
            throw new Error('Document not found');
        }

        staff.documents.splice(documentIndex, 1);
        await staff.save();
        logger.info(`Document ${documentId} deleted for staff ${staff.email}`);
    }
}

module.exports = new StaffService();
