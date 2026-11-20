const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET || 'super_secret_jwt_key_valley_express_2026'
      );

      // Support mock/dev mode
      if (decoded.id === 'dev_admin_id') {
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
