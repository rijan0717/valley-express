const jwt = require('jsonwebtoken');

const generateToken = (id, role) => {
  return jwt.sign(
    { id, role },
    process.env.JWT_SECRET || 'super_secret_jwt_key_valley_express_2026',
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '30d',
    }
  );
};

module.exports = { generateToken };
