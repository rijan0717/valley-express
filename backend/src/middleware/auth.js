const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { secret } = require('../utils/token');

const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      token = req.headers.authorization.split(' ')[1];
      // Shared with the signer so the production guard applies to both.
      const decoded = jwt.verify(token, secret());

      // Local mock admin. Gated on the environment: a token carrying this id
      // grants full admin without any corresponding account, so it must never
      // be honoured by a production server.
      if (decoded.id === 'dev_admin_id' && process.env.NODE_ENV !== 'production') {
        req.user = {
          _id: 'dev_admin_id',
          name: 'Valley Express Admin',
          phone: '9800000000',
          role: 'admin',
        };
        return next();
      }

      req.user = await User.findById(decoded.id).select('-__v');
      if (!req.user) {
        return res.status(401).json({ success: false, message: 'User not found' });
      }
      next();
    } catch (error) {
      return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ success: false, message: 'Not authorized, no token provided' });
  }
};

const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden: role '${req.user?.role}' does not have permission to access this resource`,
      });
    }
    next();
  };
};

module.exports = { protect, requireRole };
