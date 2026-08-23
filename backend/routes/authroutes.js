const express = require('express');
const router = express.Router();
const authController = require('../controllers/authcontroller');
const { authenticate } = require('../middleware/authmiddleware');
const { validate } = require('../middleware/validatemiddleware');
const {
    loginSchema,
    refreshTokenSchema,
    changePasswordSchema,
    registerSchema
} = require('../validations/authvalidation');

// Public routes
router.post('/login', validate(loginSchema), authController.login);
router.post('/refresh', validate(refreshTokenSchema), authController.refresh);
// ✅ NEW: Public self-registration
router.post('/register', validate(registerSchema), authController.register);

// Protected routes
router.post('/logout', authenticate, authController.logout);
router.post('/change-password', authenticate, validate(changePasswordSchema), authController.changePassword);
router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, authController.updateProfile);

module.exports = router;