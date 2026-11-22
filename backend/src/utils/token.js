const jwt = require('jsonwebtoken');

// The development fallback is a value committed to this repository, so any
// token signed with it can be forged by anyone who has read the source —
// including one claiming the admin role. It is therefore allowed only outside
// production, where a real secret must be supplied.
const DEV_SECRET = 'super_secret_jwt_key_valley_express_2026';

const secret = () => {
  if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'JWT_SECRET must be set in production. Refusing to sign tokens with the public development key.'
    );
  }
  return DEV_SECRET;
};

const generateToken = (id, role) => {
  return jwt.sign({ id, role }, secret(), {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

module.exports = { generateToken, secret };
