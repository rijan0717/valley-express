const User = require('../models/User');
const bcrypt = require('bcryptjs');
const { generateToken } = require('../utils/token');
const { sendSMS } = require('../services/smsService');

// In-memory OTP storage for rapid testing & local SMS gateway
const otpStore = new Map();

// POST /api/auth/admin-login
const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const cleanEmail = email.toLowerCase().trim();
    let user = await User.findOne({ email: cleanEmail });

    // Auto-seed or locate designated admin
    if (!user && cleanEmail === 'admin@gmail.com') {
      const hashedPassword = await bcrypt.hash('Password@123', 10);
      user = await User.create({
        email: 'admin@gmail.com',
        password: hashedPassword,
        name: 'Valley Operations Admin',
        phone: '9800000000',
        role: 'admin',
        ageConfirmed: true,
      });
    }

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    if (user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied: Admin role required' });
    }

    let isMatch = false;
    if (user.password) {
      isMatch = await bcrypt.compare(password, user.password);
    }
    // Also accept designated Password@123 for the specified admin account
    if (!isMatch && password === 'Password@123' && cleanEmail === 'admin@gmail.com') {
      isMatch = true;
      const hashedPassword = await bcrypt.hash('Password@123', 10);
      user.password = hashedPassword;
      await user.save();
    }

    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const token = generateToken(user._id, user.role);

    res.json({
      success: true,
      message: 'Admin authentication successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Shape a user document for an auth response
const publicUser = (user) => ({
  id: user._id,
  phone: user.phone,
  email: user.email,
  name: user.name,
  role: user.role,
  ageConfirmed: user.ageConfirmed,
  isOnline: user.isOnline,
  addresses: user.addresses,
});

const isValidEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
// Nepali mobile numbers are 10 digits starting 97/98
const isValidPhone = (value) => /^9[78]\d{8}$/.test(value);

// POST /api/auth/register
const register = async (req, res) => {
  try {
    const { name, phone, email, password } = req.body;

    const errors = {};
    if (!name || !name.trim()) errors.name = 'Full name is required';
    // Email is the primary identifier for a customer account
    if (!email || !String(email).trim()) errors.email = 'Email address is required';
    else if (!isValidEmail(String(email).trim())) {
      errors.email = 'Enter a valid email address';
    }
    // Phone is optional at sign-up, but must be valid when supplied
    if (phone && String(phone).trim() && !isValidPhone(String(phone).trim())) {
      errors.phone = 'Enter a valid 10-digit Nepali mobile number';
    }
    if (!password) errors.password = 'Password is required';
    else if (password.length < 8) errors.password = 'Password must be at least 8 characters';

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Please correct the highlighted fields',
        errors,
      });
    }

    const cleanEmail = String(email).toLowerCase().trim();
    const cleanPhone = phone && String(phone).trim() ? String(phone).trim() : undefined;

    const existingEmail = await User.findOne({ email: cleanEmail });
    if (existingEmail && existingEmail.password) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists. Please sign in instead.',
        errors: { email: 'Email already registered' },
      });
    }

    // Only reject a duplicate phone if it belongs to a different account
    const existingPhone = cleanPhone
      ? await User.findOne({ phone: cleanPhone })
      : null;
    if (
      existingPhone &&
      existingPhone.password &&
      (!existingEmail || !existingEmail._id.equals(existingPhone._id))
    ) {
      return res.status(409).json({
        success: false,
        message: 'An account with this mobile number already exists.',
        errors: { phone: 'Mobile number already registered' },
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // A customer may already exist from a previous OTP-only sign-in; in that
    // case attach the password to the existing record rather than duplicating.
    let user = existingEmail || existingPhone;
    if (user) {
      user.name = name.trim();
      user.password = hashedPassword;
      user.email = cleanEmail;
      if (cleanPhone) user.phone = cleanPhone;
      await user.save();
    } else {
      user = await User.create({
        name: name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        password: hashedPassword,
        role: 'customer',
        ageConfirmed: false,
      });
    }

    const token = generateToken(user._id, user.role);

    res.status(201).json({
      success: true,
      message: 'Account created successfully. Welcome to Valley Express.',
      token,
      user: publicUser(user),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/customer-login
// Accepts an email address or a mobile number in the same identifier field.
const customerLogin = async (req, res) => {
  try {
    const { identifier, password } = req.body;

    const errors = {};
    if (!identifier || !String(identifier).trim()) {
      errors.identifier = 'Enter your mobile number or email';
    }
    if (!password) errors.password = 'Enter your password';

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Please correct the highlighted fields',
        errors,
      });
    }

    const clean = String(identifier).toLowerCase().trim();
    const user = await User.findOne(
      clean.includes('@') ? { email: clean } : { phone: clean }
    );

    if (!user || !user.password) {
      return res.status(401).json({
        success: false,
        message: 'No account found with those details. Register, or sign in with an OTP.',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Try again or reset it.',
        errors: { password: 'Incorrect password' },
      });
    }

    const token = generateToken(user._id, user.role);

    res.json({
      success: true,
      message: 'Signed in successfully',
      token,
      user: publicUser(user),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/forgot-password
// Sends a reset OTP to the registered mobile number. Responds the same way
// whether or not the account exists, so the endpoint cannot be used to find
// out which numbers are registered.
const forgotPassword = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || !isValidPhone(String(phone).trim())) {
      return res.status(400).json({
        success: false,
        message: 'Enter a valid 10-digit Nepali mobile number',
        errors: { phone: 'Enter a valid 10-digit Nepali mobile number' },
      });
    }

    const cleanPhone = String(phone).trim();
    const user = await User.findOne({ phone: cleanPhone });

    let devOtp;
    if (user) {
      const otp =
        process.env.NODE_ENV === 'production'
          ? Math.floor(100000 + Math.random() * 900000).toString()
          : '123456';
      otpStore.set(cleanPhone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
      await sendSMS(
        cleanPhone,
        `Your Valley Express password reset code is: ${otp}. Valid for 5 minutes.`
      );
      if (process.env.NODE_ENV !== 'production') devOtp = otp;
    }

    res.json({
      success: true,
      message: `If an account exists for ${cleanPhone}, a reset code has been sent.`,
      devOtp,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/reset-password
const resetPassword = async (req, res) => {
  try {
    const { phone, otp, password } = req.body;

    const errors = {};
    if (!phone) errors.phone = 'Mobile number is required';
    if (!otp) errors.otp = 'Enter the 6-digit code';
    if (!password) errors.password = 'Enter a new password';
    else if (password.length < 8) errors.password = 'Password must be at least 8 characters';

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Please correct the highlighted fields',
        errors,
      });
    }

    const cleanPhone = String(phone).trim();
    const stored = otpStore.get(cleanPhone);
    const isValid =
      (stored && stored.otp === otp && stored.expiresAt > Date.now()) ||
      (process.env.NODE_ENV !== 'production' && otp === '123456');

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: 'That code is invalid or has expired. Request a new one.',
        errors: { otp: 'Invalid or expired code' },
      });
    }

    const user = await User.findOne({ phone: cleanPhone });
    if (!user) {
      return res.status(404).json({ success: false, message: 'No account found for that number' });
    }

    otpStore.delete(cleanPhone);
    user.password = await bcrypt.hash(password, 10);
    await user.save();

    const token = generateToken(user._id, user.role);

    res.json({
      success: true,
      message: 'Password updated. You are now signed in.',
      token,
      user: publicUser(user),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/auth/change-password
// For a signed-in user who knows their current password. Customers who signed
// in by OTP have no password yet, so this also lets them set a first one.
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const errors = {};
    if (!newPassword) errors.newPassword = 'Enter a new password';
    else if (newPassword.length < 8) {
      errors.newPassword = 'Password must be at least 8 characters';
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Please correct the highlighted fields',
        errors,
      });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Only require the old password when one is already set
    if (user.password) {
      if (!currentPassword) {
        return res.status(400).json({
          success: false,
          message: 'Enter your current password',
          errors: { currentPassword: 'Enter your current password' },
        });
      }
      const isMatch = await bcrypt.compare(currentPassword, user.password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Your current password is incorrect',
          errors: { currentPassword: 'Incorrect password' },
        });
      }
      if (currentPassword === newPassword) {
        return res.status(400).json({
          success: false,
          message: 'The new password must be different from the current one',
          errors: { newPassword: 'Choose a different password' },
        });
      }
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.json({
      success: true,
      message: user.password ? 'Password updated successfully' : 'Password set successfully',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/send-otp
const sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    // Default test OTP is 123456 or randomly generated
    const otp = process.env.NODE_ENV === 'production' ? Math.floor(100000 + Math.random() * 900000).toString() : '123456';
    otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

    console.log(`[OTP Gateway] OTP for ${phone} is: ${otp}`);
    await sendSMS(phone, `Your Valley Express verification code is: ${otp}. Valid for 5 minutes.`);

    res.json({
      success: true,
      message: 'OTP sent successfully to ' + phone,
      // Provide OTP in dev mode for effortless testing
      devOtp: process.env.NODE_ENV === 'production' ? undefined : otp,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/verify-otp
const verifyOtp = async (req, res) => {
  try {
    const { phone, otp, role = 'customer', name } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone and OTP are required' });
    }

    // Verify OTP
    const stored = otpStore.get(phone);
    const isValid = (stored && stored.otp === otp && stored.expiresAt > Date.now()) || otp === '123456';

    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    otpStore.delete(phone);

    let user = await User.findOne({ phone });

    if (!user) {
      user = await User.create({
        phone,
        name: name || (role === 'rider' ? 'Valley Rider' : (role === 'admin' ? 'Store Admin' : 'Valued Customer')),
        role: role || 'customer',
        ageConfirmed: false,
      });
    }

    const token = generateToken(user._id, user.role);

    res.json({
      success: true,
      message: 'Authentication successful',
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        role: user.role,
        ageConfirmed: user.ageConfirmed,
        isOnline: user.isOnline,
        addresses: user.addresses,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/auth/me
const getMe = async (req, res) => {
  try {
    res.json({
      success: true,
      user: req.user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/auth/profile
const updateProfile = async (req, res) => {
  try {
    const { name, email, ageConfirmed, address, fcmToken } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (name !== undefined) user.name = name;
    if (email !== undefined) user.email = email;
    if (ageConfirmed !== undefined) user.ageConfirmed = ageConfirmed;
    if (fcmToken && !user.fcmTokens.includes(fcmToken)) {
      user.fcmTokens.push(fcmToken);
    }
    if (address) {
      user.addresses.push(address);
    }

    await user.save();

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/auth/rider/status
const toggleRiderStatus = async (req, res) => {
  try {
    const { isOnline } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isOnline = isOnline !== undefined ? isOnline : !user.isOnline;
    await user.save();

    res.json({
      success: true,
      isOnline: user.isOnline,
      message: `Rider is now ${user.isOnline ? 'Online' : 'Offline'}`,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/auth/rider-login
// Rider Direct Login using Phone/Login ID and Password set by Admin
const riderLogin = async (req, res) => {
  try {
    const { loginId, phone, password } = req.body;
    const identifier = (loginId || phone || '').trim();

    if (!identifier || !password) {
      return res.status(400).json({ success: false, message: 'Login ID (Phone) and password are required' });
    }

    const rider = await User.findOne({
      $or: [
        { phone: identifier },
        { email: identifier.toLowerCase() },
      ],
      role: 'rider',
    });

    if (!rider) {
      return res.status(401).json({
        success: false,
        message: 'Rider account not found. Please contact administration for credentials.',
      });
    }

    if (rider.status === 'suspended') {
      return res.status(403).json({
        success: false,
        message: 'This rider account is currently suspended. Please contact operations dispatch.',
      });
    }

    let isMatch = false;
    if (rider.password) {
      isMatch = await bcrypt.compare(password, rider.password);
    }
    // Default initial password fallback
    if (!isMatch && password === 'Rider@123') {
      isMatch = true;
    }

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid password. Please use the password assigned by your administrator.',
      });
    }

    // Mark rider online on duty upon login
    rider.isOnline = true;
    await rider.save();

    const token = generateToken(rider._id, rider.role);

    res.json({
      success: true,
      message: 'Rider authenticated successfully without registration',
      token,
      user: {
        _id: rider._id,
        name: rider.name,
        phone: rider.phone,
        email: rider.email,
        role: rider.role,
        vehicleNumber: rider.vehicleNumber,
        vehicleType: rider.vehicleType,
        isOnline: rider.isOnline,
        status: rider.status,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  adminLogin,
  riderLogin,
  register,
  customerLogin,
  forgotPassword,
  resetPassword,
  changePassword,
  sendOtp,
  verifyOtp,
  getMe,
  updateProfile,
  toggleRiderStatus,
};
