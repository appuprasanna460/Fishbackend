const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const env = require('./config/env');
const logger = require('./config/logger');
const { errorHandler, notFoundHandler } = require('./middleware/errormiddleware');
const { generalLimiter } = require('./middleware/rateLimiter');
const { auditLog } = require('./middleware/auditLogmiddleware');
const bookingRoutes = require('./routes/bookingroutes');
const boatOwnerRoutes = require('./routes/boatownerroutes');

// Import routes
const authRoutes = require('./routes/authroutes');
const fishBuyerBillRoutes = require('./routes/fishBuyerBillRoutes');
const userRoutes = require('./routes/userroutes');
const locationRoutes = require('./routes/locationroutes');
const boatRoutes = require('./routes/boatroutes');
const fishRoutes = require('./routes/fishroutes');
const billRoutes = require('./routes/billroutes');
const ledgerRoutes = require('./routes/ledgerroutes');
const trackingRoutes = require('./routes/trackingroutes');
const reportRoutes = require('./routes/reportroutes');
const seedRoutes = require('./routes/seedroutes');
const invoiceTemplateRoutes = require('./routes/invoiceTemplateRoutes');
const harbourRoutes = require('./routes/harbourroutes');
const notificationRoutes = require('./routes/notificationroutes');
const subscriptionPlanRoutes = require('./routes/subscriptionPlanRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes');
const documentRoutes = require('./routes/documentroutes');
const staffRoutes = require('./routes/staffroutes');
const voyageRoutes = require('./routes/voyageRoutes');
const catchRoutes = require('./routes/catchRoutes');
const agentDashboardRoutes = require('./routes/agentDashboardRoutes');

// Exporter Module routes
const purchaseRoutes = require('./routes/purchaseRoutes');
const stockRoutes = require('./routes/stockRoutes');
const salesRoutes = require('./routes/salesRoutes');
const dispatchRoutes = require('./routes/dispatchRoutes');
const financeRoutes = require('./routes/financeRoutes');
const marketIntelRoutes = require('./routes/marketIntelRoutes');
const exporterStaffRoutes = require('./routes/exporterStaffRoutes');
const exporterDashboardRoutes = require('./routes/exporterDashboardRoutes');
const exporterReportRoutes = require('./routes/exporterReportRoutes');
const exporterMasterRoutes = require('./routes/exporterMasterRoutes');
const exporterCustomerRoutes = require('./routes/exporterCustomerRoutes');

const app = express();

// Configure CORS for mobile app access
app.use(cors({
    origin: '*', // Allow all origins for development - restrict in production
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Idempotency-Key', 'X-Idempotency-Key'],
    credentials: true
}));

// Other middlewares
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// General API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/boats', boatRoutes);
app.use('/api/fish', fishRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/ledger', ledgerRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/seed', seedRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/boat-owner', boatOwnerRoutes);
app.use('/api/fish-buyer-bills', fishBuyerBillRoutes);
app.use('/api/templates', invoiceTemplateRoutes);
app.use('/api/harbours', harbourRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/subscription-plans', subscriptionPlanRoutes);
app.use('/api/subscription', subscriptionRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/staff', staffRoutes);
app.use('/api/voyages', voyageRoutes);
app.use('/api/catches', catchRoutes);
app.use('/api/agent', agentDashboardRoutes);

// Dedicated Exporter Module Routes (/api/exporter/*)
app.use('/api/exporter/dashboard', exporterDashboardRoutes);
app.use('/api/exporter/reports', exporterReportRoutes);
app.use('/api/exporter/masters', exporterMasterRoutes);
app.use('/api/exporter/customers', exporterCustomerRoutes);
app.use('/api/exporter/staff', exporterStaffRoutes);
app.use('/api/exporter/purchases', purchaseRoutes);
app.use('/api/exporter/stock', stockRoutes);
app.use('/api/exporter/sales', salesRoutes);
app.use('/api/exporter/dispatch', dispatchRoutes);
app.use('/api/exporter/finance', financeRoutes);
app.use('/api/exporter/market-intelligence', marketIntelRoutes);

// Root Exporter routes (backward compatibility)
app.use('/api/purchases', purchaseRoutes);
app.use('/api/stock', stockRoutes);
app.use('/api/sales', salesRoutes);
app.use('/api/dispatch', dispatchRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/receivables', financeRoutes);
app.use('/api/payables', financeRoutes);
app.use('/api/expenses', financeRoutes);
app.use('/api/market-intelligence', marketIntelRoutes);
app.use('/api/exporter-staff', exporterStaffRoutes);

// Audit logging for all API routes
app.use('/api', auditLog);

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;