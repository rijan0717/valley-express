const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const categoryRoutes = require('./routes/categories');
const orderRoutes = require('./routes/orders');
const offerRoutes = require('./routes/offers');
const chatRoutes = require('./routes/chat');
const settingRoutes = require('./routes/settings');
const riderRoutes = require('./routes/rider');
const userRoutes = require('./routes/users');
const mapRoutes = require('./routes/maps');
const paymentRoutes = require('./routes/payments');
const issueRoutes = require('./routes/issues');
const notificationRoutes = require('./routes/notifications');
const coinRoutes = require('./routes/coins');
const wishlistRoutes = require('./routes/wishlist');
const leadRoutes = require('./routes/leads');

const app = express();

// Security Middleware
app.use(helmet());

// CORS configuration (allow admin web and mobile apps securely)
const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
  : ['http://localhost:5173', 'http://localhost:3000', 'http://localhost:8080'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile native apps, curl, etc.)
      if (!origin) return callback(null, true);
      if (
        allowedOrigins.includes(origin) ||
        process.env.NODE_ENV !== 'production' ||
        /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
      ) {
        return callback(null, true);
      }
      return callback(null, false);
    },
    credentials: true,
  })
);

// Body parser (supports multiple high-resolution drag & drop product images)
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ limit: '25mb', extended: true }));

// HTTP Request Logger
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Rate limiter for OTP endpoint (security best practice)
const otpLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10, // max 10 requests per IP
  message: { success: false, message: 'Too many OTP requests, please try again after 5 minutes' },
});
app.use('/api/auth/send-otp', otpLimiter);

// The credential endpoints were unthrottled, so a password or OTP could be
// guessed at full speed. Counted per IP; successful sign-ins are not held
// against the limit, so a customer typing one wrong password is unaffected.
const credentialLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  skipSuccessfulRequests: true,
  message: {
    success: false,
    message: 'Too many sign-in attempts. Please wait a few minutes and try again.',
  },
});
app.use('/api/auth/customer-login', credentialLimiter);
app.use('/api/auth/rider-login', credentialLimiter);
app.use('/api/auth/admin-login', credentialLimiter);
app.use('/api/auth/verify-otp', credentialLimiter);
app.use('/api/auth/reset-password', credentialLimiter);

// The public website writes here, so it is throttled harder than a signed-in
// endpoint would be: the forms are open to anyone who loads the homepage.
const publicFormLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 12,
  message: {
    success: false,
    message: 'Too many submissions from this network. Please try again shortly.',
  },
});
// Only the public POSTs are throttled; the admin inbox below reads freely.
app.use('/api/leads/notify', publicFormLimiter);
app.use('/api/leads/contact', publicFormLimiter);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date(),
    service: 'Valley Express Backend API',
    version: '1.0.0',
  });
});

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/admin/settings', settingRoutes);
app.use('/api/settings', settingRoutes);
app.use('/api/rider', riderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin/users', userRoutes);
app.use('/api/maps', mapRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/issues', issueRoutes);
app.use('/api/admin/issues', issueRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/coins', coinRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/leads', leadRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Cannot ${req.method} ${req.url}` });
});

// Central Error Handler
app.use(errorHandler);

module.exports = app;
