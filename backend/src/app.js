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

const app = express();

// Security Middleware
app.use(helmet());

// CORS configuration (allow admin web and mobile apps)
app.use(
  cors({
    origin: '*',
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

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Cannot ${req.method} ${req.url}` });
});

// Central Error Handler
app.use(errorHandler);

module.exports = app;
