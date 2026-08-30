// services/bookingservice.js
const Booking = require('../models/bookingmodel');
const Boat = require('../models/boatmodel');
const { AppError, NotFoundError, ConflictError } = require('../utils/errors');
const logger = require('../config/logger');

class BookingService {

    /**
     * Create a new boat booking
     */
    async createBooking(data, user) {
        const { boatId, purpose, notes } = data;

        const boat = await Boat.findOne({
            _id: boatId,
            isActive: true,
            isDeleted: false
        });

        if (!boat) {
            throw new NotFoundError('Boat not found or inactive');
        }

        const existingBooking = await Booking.findOne({
            boatId: boatId,
            status: { $in: ['PENDING_APPROVAL', 'BOOKED', 'CONFIRMED'] },
            isDeleted: false
        });

        if (existingBooking) {
            throw new ConflictError('This boat is already booked or has a pending request');
        }

        const booking = new Booking({
            boatId,
            agentId: user._id,
            bookingDate: new Date(),
            purpose: purpose || 'Fishing',
            notes: notes || '',
            status: 'PENDING_APPROVAL'
        });

        await booking.save();

        // Send notification to boat owner
        try {
            const Notification = require('../models/notificationmodel');
            await Notification.create({
                userId: boat.ownerId,
                type: 'BOOKING_REQUEST',
                title: 'New Booking Request',
                message: `Booking request raised for boat "${boat.boatName}" by agent "${user.name || user.email}".`,
                relatedId: booking._id,
                relatedType: 'BOOKING'
            });
            logger.info(`Booking request notification sent to boat owner ${boat.ownerId}`);
        } catch (err) {
            logger.error('Failed to create booking request notification:', err);
        }

        const populatedBooking = await Booking.findById(booking._id)
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('agentId', 'name email phone');

        logger.info(`Booking request raised: ${booking.bookingNumber} - ${boat.boatNumber} by ${user.email}`);
        return populatedBooking;
    }

    /**
     * Get all bookings for an agent
     */
    async getAgentBookings(agentId) {
        const bookings = await Booking.find({
            agentId,
            isDeleted: false
        })
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('agentId', 'name email phone')
            .sort({ createdAt: -1 });

        return bookings;
    }

    /**
     * Get booking by boat ID with agent details
     */
    async getBookingByBoatId(boatId) {
        const booking = await Booking.findOne({
            boatId: boatId,
            isDeleted: false
        })
            .populate('boatId', 'boatName boatNumber')
            .populate('agentId', 'name email phone');

        return booking;
    }

    /**
     * Get ALL bookings for display (any agent)
     */
    async getAllBookingsForDisplay() {
        const bookings = await Booking.find({ isDeleted: false })
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('agentId', 'name email phone')
            .sort({ createdAt: -1 });

        return bookings;
    }

    async getAgentBookedBoats(agentId) {
        const bookings = await Booking.find({
            agentId: agentId,
            status: { $in: ['PENDING_APPROVAL', 'BOOKED', 'CONFIRMED'] },
            isDeleted: false
        })
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .sort({ createdAt: -1 });

        return bookings.map(b => b.boatId).filter(b => b !== null);
    }

    /**
     * Get all bookings (for super admin)
     */
    async getAllBookings() {
        const bookings = await Booking.find({ isDeleted: false })
            .populate('boatId', 'boatName boatNumber')
            .populate('agentId', 'name email')
            .sort({ createdAt: -1 });

        return bookings;
    }

    /**
     * Update booking status
     */
    async updateBookingStatus(bookingId, status, approvedBy) {
        const booking = await Booking.findOne({ _id: bookingId, isDeleted: false });
        if (!booking) {
            throw new NotFoundError('Booking not found');
        }

        booking.status = status;
        if (status === 'CONFIRMED' || status === 'BOOKED') {
            booking.approvedBy = approvedBy;
            booking.approvedAt = new Date();
        }

        await booking.save();

        // Fetch boat details for notification
        const boat = await Boat.findById(booking.boatId).lean();
        const boatName = boat ? boat.boatName : 'boat';

        // Send notification to agent
        if (status === 'CONFIRMED' || status === 'BOOKED') {
            try {
                const Notification = require('../models/notificationmodel');
                await Notification.create({
                    userId: booking.agentId,
                    type: 'BOOKING_APPROVED',
                    title: 'Booking Request Approved',
                    message: `Your booking request for boat "${boatName}" has been approved.`,
                    relatedId: booking._id,
                    relatedType: 'BOOKING'
                });
                logger.info(`Booking approval notification sent to agent ${booking.agentId}`);
            } catch (err) {
                logger.error('Failed to create booking approval notification:', err);
            }
        }

        return booking;
    }

    /**
     * Get bookings for boats owned by a specific owner
     */
    async getBookingsForOwner(ownerId) {
        // First find all boats owned by this owner
        const ownerBoats = await Boat.find({ ownerId, isDeleted: false }).select('_id').lean();
        const boatIds = ownerBoats.map(b => b._id);

        if (boatIds.length === 0) return [];

        const bookings = await Booking.find({
            boatId: { $in: boatIds },
            isDeleted: false
        })
            .populate('boatId', 'boatName boatNumber registrationNumber capacity')
            .populate('agentId', 'name email phone')
            .sort({ createdAt: -1 });

        return bookings;
    }

    /**
     * Get active booked boat IDs for agent
     */
    async getActiveBookedBoatsForAgent(agentId) {
        const bookings = await Booking.find({
            agentId,
            status: { $in: ['PENDING_APPROVAL', 'BOOKED', 'CONFIRMED'] },
            isDeleted: false
        }).select('boatId').lean();

        return bookings.map(b => b.boatId.toString());
    }

    /**
     * Delete booking
     */
    async deleteBooking(id, user) {
        const booking = await Booking.findOne({
            _id: id,
            isDeleted: false
        });

        if (!booking) {
            throw new NotFoundError('Booking not found');
        }

        if (user.role !== 'SUPER_ADMIN' && booking.agentId.toString() !== user._id.toString()) {
            throw new AppError('You are not authorized to delete this booking', 403);
        }

        await Booking.deleteOne({ _id: id });

        logger.info(`Booking ${booking.bookingNumber} deleted by ${user.email}`);
        return booking;
    }

    /**
     * Check if boat is booked
     */
    async isBoatBooked(boatId) {
        const booking = await Booking.findOne({
            boatId,
            status: { $in: ['PENDING_APPROVAL', 'BOOKED', 'CONFIRMED'] },
            isDeleted: false
        });
        return !!booking;
    }

    /**
     * Get active bookings with boat and owner details
     */
    async getActiveBookingsWithDetails(agentId) {
        const bookings = await Booking.find({
            agentId,
            status: { $in: ['BOOKED', 'CONFIRMED'] },
            isDeleted: false
        })
        .populate({
            path: 'boatId',
            populate: {
                path: 'ownerId',
                select: 'name'
            }
        })
        .lean();

        return bookings.map(b => {
            const boat = b.boatId || {};
            const owner = boat.ownerId || {};
            return {
                boatId: boat._id ? boat._id.toString() : '',
                boatName: boat.boatName || '',
                boatNumber: boat.boatNumber || '',
                ownerName: owner.name || '',
                status: b.status
            };
        });
    }

    /**
     * Deactivate a booking by the boat owner (sets status to CANCELLED)
     */
    async deactivateBookingByOwner(bookingId, ownerId) {
        const booking = await Booking.findOne({ _id: bookingId, isDeleted: false });
        if (!booking) {
            throw new NotFoundError('Booking not found');
        }

        // Verify the boat belongs to this owner
        const boat = await Boat.findOne({ _id: booking.boatId, ownerId, isDeleted: false });
        if (!boat) {
            throw new AppError('You are not authorised to modify this booking', 403);
        }

        booking.status = 'CANCELLED';
        await booking.save();

        // Notify the commission agent
        try {
            const Notification = require('../models/notificationmodel');
            await Notification.create({
                userId: booking.agentId,
                type: 'BOOKING_CANCELLED',
                title: 'Booking Deactivated',
                message: `Your booking for boat "${boat.boatName}" has been deactivated by the boat owner.`,
                relatedId: booking._id,
                relatedType: 'BOOKING'
            });
        } catch (err) {
            logger.error('Failed to create deactivation notification:', err);
        }

        logger.info(`Booking ${booking.bookingNumber} deactivated by owner ${ownerId}`);
        return booking;
    }

    /**
     * Activate a booking by the boat owner (restores status to CONFIRMED)
     */
    async activateBookingByOwner(bookingId, ownerId) {
        const booking = await Booking.findOne({ _id: bookingId, isDeleted: false });
        if (!booking) {
            throw new NotFoundError('Booking not found');
        }

        // Verify the boat belongs to this owner
        const boat = await Boat.findOne({ _id: booking.boatId, ownerId, isDeleted: false });
        if (!boat) {
            throw new AppError('You are not authorised to modify this booking', 403);
        }

        booking.status = 'CONFIRMED';
        booking.approvedBy = ownerId;
        booking.approvedAt = new Date();
        await booking.save();

        // Notify the commission agent
        try {
            const Notification = require('../models/notificationmodel');
            await Notification.create({
                userId: booking.agentId,
                type: 'BOOKING_APPROVED',
                title: 'Booking Activated',
                message: `Your booking for boat "${boat.boatName}" has been activated by the boat owner.`,
                relatedId: booking._id,
                relatedType: 'BOOKING'
            });
        } catch (err) {
            logger.error('Failed to create activation notification:', err);
        }

        logger.info(`Booking ${booking.bookingNumber} activated by owner ${ownerId}`);
        return booking;
    }
}

module.exports = new BookingService();