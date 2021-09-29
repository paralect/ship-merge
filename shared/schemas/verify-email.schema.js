const Joi = require('joi');

const schema = Joi.object({
  token: Joi.string()
    .required()
    .messages({
      'any.required': 'Token is required',
      'string.empty': 'Token is required',
    }),
});

module.exports = (obj) => schema.validate(obj, { allowUnknown: false });
