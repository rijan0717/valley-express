const Lead = require('../models/Lead');

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
// Nepali mobile numbers, with or without the +977 country code.
const PHONE_PATTERN = /^(\+?977[-\s]?)?9\d{9}$/;

const clean = (value, limit) =>
  typeof value === 'string' ? value.trim().slice(0, limit) : '';

/**
 * POST /api/leads/notify
 * Joins the app-launch notify list. Either an email or a phone is enough.
 */
exports.createNotifyLead = async (req, res, next) => {
  try {
    const email = clean(req.body.email, 200).toLowerCase();
    const phone = clean(req.body.phone, 30);
    const platform = ['android', 'ios', 'either'].includes(req.body.platform)
      ? req.body.platform
      : 'either';

    if (!email && !phone) {
      return res.status(400).json({
        success: false,
        message: 'Please give us an email address or a phone number.',
      });
    }
    if (email && !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ success: false, message: 'That email address does not look right.' });
    }
    if (phone && !PHONE_PATTERN.test(phone)) {
      return res.status(400).json({ success: false, message: 'Please enter a valid Nepali mobile number.' });
    }

    await Lead.updateOne(
      { source: 'app-notify', email, phone },
      { $set: { platform }, $setOnInsert: { source: 'app-notify', email, phone } },
      { upsert: true }
    );

    return res.status(201).json({
      success: true,
      message: 'You are on the list. We will let you know the day the app goes live.',
    });
  } catch (err) {
    // A duplicate means the visitor is already on the list, which is a success
    // from their side of the screen.
    if (err && err.code === 11000) {
      return res.status(200).json({
        success: true,
        message: 'You are already on the list. We will be in touch.',
      });
    }
    return next(err);
  }
};

/**
 * POST /api/leads/contact
 * Stores a contact-form message for the support team.
 */
exports.createContactLead = async (req, res, next) => {
  try {
    const name = clean(req.body.name, 120);
    const email = clean(req.body.email, 200).toLowerCase();
    const phone = clean(req.body.phone, 30);
    const subject = clean(req.body.subject, 160);
    const message = clean(req.body.message, 4000);

    if (!name || !message) {
      return res.status(400).json({
        success: false,
        message: 'Please tell us your name and what you would like to say.',
      });
    }
    if (!email && !phone) {
      return res.status(400).json({
        success: false,
        message: 'Please leave an email address or a phone number so we can reply.',
      });
    }
    if (email && !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ success: false, message: 'That email address does not look right.' });
    }
    if (phone && !PHONE_PATTERN.test(phone)) {
      return res.status(400).json({ success: false, message: 'Please enter a valid Nepali mobile number.' });
    }

    await Lead.create({ source: 'contact', name, email, phone, subject, message });

    return res.status(201).json({
      success: true,
      message: 'Thank you. Our Kathmandu team replies within one working day.',
    });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/leads
 * Admin: the website's contact messages and app-waitlist sign-ups.
 * `source` filters to one kind; omit it for everything, newest first.
 */
exports.getLeads = async (req, res, next) => {
  try {
    const filter = {};
    if (req.query.source === 'contact' || req.query.source === 'app-notify') {
      filter.source = req.query.source;
    }
    if (req.query.handled === 'false') filter.handled = false;

    const limit = Math.min(parseInt(req.query.limit, 10) || 200, 500);

    const [leads, unhandledContact, notifyTotal] = await Promise.all([
      Lead.find(filter).sort({ createdAt: -1 }).limit(limit).lean(),
      Lead.countDocuments({ source: 'contact', handled: false }),
      Lead.countDocuments({ source: 'app-notify' }),
    ]);

    return res.json({
      success: true,
      count: leads.length,
      unhandledContact,
      notifyTotal,
      leads,
    });
  } catch (err) {
    return next(err);
  }
};

/**
 * PATCH /api/leads/:id
 * Admin: mark a message dealt with, or put it back in the queue.
 */
exports.updateLead = async (req, res, next) => {
  try {
    const lead = await Lead.findByIdAndUpdate(
      req.params.id,
      { handled: Boolean(req.body.handled) },
      { new: true, runValidators: true }
    );
    if (!lead) {
      return res.status(404).json({ success: false, message: 'That enquiry no longer exists.' });
    }
    return res.json({ success: true, lead });
  } catch (err) {
    return next(err);
  }
};

/**
 * DELETE /api/leads/:id
 * Admin: remove an enquiry entirely, for spam or on request.
 */
exports.deleteLead = async (req, res, next) => {
  try {
    const lead = await Lead.findByIdAndDelete(req.params.id);
    if (!lead) {
      return res.status(404).json({ success: false, message: 'That enquiry no longer exists.' });
    }
    return res.json({ success: true, message: 'Enquiry deleted.' });
  } catch (err) {
    return next(err);
  }
};
