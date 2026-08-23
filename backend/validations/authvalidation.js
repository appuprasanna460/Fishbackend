const Joi = require('joi');

const loginSchema = Joi.object({
    email: Joi.string()
        .email()
        .required()
        .messages({
            'string.email': 'Please provide a valid email address',
            'any.required': 'Email is required'
        }),
    password: Joi.string()
        .required()
        .min(8)
        .messages({
            'string.min': 'Password must be at least 8 characters long',
            'any.required': 'Password is required'
        })
});

const refreshTokenSchema = Joi.object({
    refreshToken: Joi.string()
        .required()
        .messages({
            'any.required': 'Refresh token is required'
        })
});

const changePasswordSchema = Joi.object({
    currentPassword: Joi.string()
        .required()
        .messages({
            'any.required': 'Current password is required'
        }),
    newPassword: Joi.string()
        .required()
        .min(8)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])/)
        .messages({
            'string.min': 'Password must be at least 8 characters long',
            'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
            'any.required': 'New password is required'
        }),
    confirmPassword: Joi.string()
        .required()
        .valid(Joi.ref('newPassword'))
        .messages({
            'any.only': 'Passwords do not match',
            'any.required': 'Please confirm your password'
        })
});

const forgotPasswordSchema = Joi.object({
    email: Joi.string()
        .email()
        .required()
        .messages({
            'string.email': 'Please provide a valid email address',
            'any.required': 'Email is required'
        })
});

const resetPasswordSchema = Joi.object({
    token: Joi.string()
        .required()
        .messages({
            'any.required': 'Reset token is required'
        }),
    newPassword: Joi.string()
        .required()
        .min(8)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])/)
        .messages({
            'string.min': 'Password must be at least 8 characters long',
            'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
            'any.required': 'New password is required'
        }),
    confirmPassword: Joi.string()
        .required()
        .valid(Joi.ref('newPassword'))
        .messages({
            'any.only': 'Passwords do not match',
            'any.required': 'Please confirm your password'
        })
});

const registerSchema = Joi.object({
    name: Joi.string().trim().min(2).max(100).required().messages({
        'string.min': 'Name must be at least 2 characters',
        'any.required': 'Name is required'
    }),
    email: Joi.string().email().required().messages({
        'string.email': 'Please provide a valid email address',
        'any.required': 'Email is required'
    }),
    password: Joi.string().min(8).required().messages({
        'string.min': 'Password must be at least 8 characters long',
        'any.required': 'Password is required'
    }),
    phone: Joi.string().pattern(/^[0-9]{10}$/).required().messages({
        'string.pattern.base': 'Phone must be a 10-digit number',
        'any.required': 'Phone is required'
    }),
    companyName: Joi.string().trim().min(2).required().messages({
        'any.required': 'Company name is required'
    }),
    referenceBy: Joi.string().trim().allow('').optional(),
    role: Joi.string().valid('COMMISSION_AGENT', 'BOAT_OWNER', 'FISH_BUYER').required().messages({
        'any.only': 'Role must be one of: COMMISSION_AGENT, BOAT_OWNER, FISH_BUYER',
        'any.required': 'Role is required'
    }),
    harbourId: Joi.string().hex().length(24).required().messages({
        'any.required': 'Harbour is required'
    }),
    // New dynamic plan reference — the ObjectId of the selected SubscriptionPlan
    subscriptionPlanId: Joi.string().hex().length(24).required().messages({
        'string.hex': 'Subscription plan must be a valid plan ID',
        'string.length': 'Subscription plan must be a valid plan ID',
        'any.required': 'Subscription plan is required'
    }),
    // Legacy enum plan field — kept optional for backward compatibility with old clients
    subscriptionPlan: Joi.string().valid('QUARTERLY', 'HALF_YEARLY', 'YEARLY').optional().messages({
        'any.only': 'Subscription plan must be QUARTERLY, HALF_YEARLY, or YEARLY'
    }),
    aboutYou: Joi.string().trim().allow('').optional(),
    dateOfBirth: Joi.date().allow(null).optional(),
    address: Joi.string().trim().allow('').optional(),
    emergencyContactName: Joi.string().trim().allow('').optional(),
    emergencyContactRelationship: Joi.string().trim().allow('').optional(),
    emergencyContactPhone: Joi.string().trim().allow('').optional()
});

module.exports = {
    loginSchema,
    refreshTokenSchema,
    changePasswordSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    registerSchema
};