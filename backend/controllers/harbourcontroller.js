const Harbour = require('../models/harbourmodel');

// Public route to fetch all active, non-deleted harbours
exports.getPublicHarbours = async (req, res) => {
    try {
        const harbours = await Harbour.find({ isActive: true, isDeleted: false }).sort({ name: 1 });
        return res.status(200).json({
            success: true,
            data: harbours
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to fetch active harbours',
            error: error.message
        });
    }
};

// Super Admin CRUD
exports.createHarbour = async (req, res) => {
    try {
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ success: false, message: 'Harbour name is required' });
        }

        const existing = await Harbour.findOne({ name: name.trim() });
        if (existing) {
            return res.status(400).json({ success: false, message: 'Harbour already exists' });
        }

        const harbour = new Harbour({ name: name.trim() });
        await harbour.save();

        return res.status(201).json({
            success: true,
            message: 'Harbour created successfully',
            data: harbour
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to create harbour',
            error: error.message
        });
    }
};

exports.getHarbours = async (req, res) => {
    try {
        const filter = { isDeleted: false };
        if (req.query.activeOnly === 'true') {
            filter.isActive = true;
        }
        const harbours = await Harbour.find(filter).sort({ name: 1 });
        return res.status(200).json({
            success: true,
            data: harbours
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to fetch harbours',
            error: error.message
        });
    }
};

exports.updateHarbour = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, isActive } = req.body;

        const harbour = await Harbour.findOne({ _id: id, isDeleted: false });
        if (!harbour) {
            return res.status(404).json({ success: false, message: 'Harbour not found' });
        }

        if (name !== undefined) harbour.name = name.trim();
        if (isActive !== undefined) harbour.isActive = isActive;

        await harbour.save();

        return res.status(200).json({
            success: true,
            message: 'Harbour updated successfully',
            data: harbour
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to update harbour',
            error: error.message
        });
    }
};

exports.deleteHarbour = async (req, res) => {
    try {
        const { id } = req.params;

        const harbour = await Harbour.findOne({ _id: id, isDeleted: false });
        if (!harbour) {
            return res.status(404).json({ success: false, message: 'Harbour not found' });
        }

        harbour.isDeleted = true;
        await harbour.save();

        return res.status(200).json({
            success: true,
            message: 'Harbour deleted successfully'
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Failed to delete harbour',
            error: error.message
        });
    }
};
