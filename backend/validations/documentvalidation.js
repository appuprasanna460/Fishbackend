const Joi = require('joi');

const objectIdRegex = /^[0-9a-fA-F]{24}$/;

const documentBaseSchema = {
    documentName: Joi.string().required().trim().min(2).max(100).messages({
        'any.required': 'Document name is required'
    }),
    documentNumber: Joi.string().required().trim().min(1).max(50).messages({
        'any.required': 'Document number is required'
    }),
    boatId: Joi.string().pattern(objectIdRegex).allow(null, '').messages({
        'string.pattern.base': 'Invalid boat ID format'
    }),
    crewMemberId: Joi.string().pattern(objectIdRegex).allow(null, '').messages({
        'string.pattern.base': 'Invalid crew member ID format'
    }),
    issueDate: Joi.date().required().messages({
        'any.required': 'Issue date is required'
    }),
    expiryDate: Joi.date().greater(Joi.ref('issueDate')).required().messages({
        'date.greater': 'Expiry date must be after issue date',
        'any.required': 'Expiry date is required'
    }),
    issuedBy: Joi.string().required().trim().min(2).max(100).messages({
        'any.required': 'Issued by is required'
    })
};

const createDocumentSchema = Joi.object(documentBaseSchema);

const updateDocumentSchema = Joi.object({
    documentName: Joi.string().trim().min(2).max(100),
    documentNumber: Joi.string().trim().min(1).max(50),
    boatId: Joi.string().pattern(objectIdRegex).allow(null, ''),
    crewMemberId: Joi.string().pattern(objectIdRegex).allow(null, ''),
    issueDate: Joi.date(),
    expiryDate: Joi.date().greater(Joi.ref('issueDate')),
    issuedBy: Joi.string().trim().min(2).max(100)
}).min(1);

const documentIdParamSchema = Joi.object({
    id: Joi.string().pattern(objectIdRegex).required().messages({
        'string.pattern.base': 'Invalid document ID format',
        'any.required': 'Document ID is required'
    })
});

const documentListQuerySchema = Joi.object({
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(100).default(10),
    boatId: Joi.string().pattern(objectIdRegex),
    crewMemberId: Joi.string().pattern(objectIdRegex),
    status: Joi.string().valid('All', 'Valid', 'Expiring', 'Expired', 'Expiring Soon'),
    search: Joi.string().allow('', null)
});

module.exports = {
    createDocumentSchema,
    updateDocumentSchema,
    documentIdParamSchema,
    documentListQuerySchema
};
