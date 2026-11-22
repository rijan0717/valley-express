const Offer = require('../models/Offer');
const User = require('../models/User');
const { createNotification } = require('./notificationController');

// GET /api/offers
const getOffers = async (req, res) => {
  try {
    const now = new Date();
    const offers = await Offer.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
    }).sort({ createdAt: -1 });

    res.json({ success: true, count: offers.length, offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/offers/all (Admin)
const getAllOffers = async (req, res) => {
  try {
    const offers = await Offer.find().sort({ createdAt: -1 });
    res.json({ success: true, count: offers.length, offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/offers (Admin)
const createOffer = async (req, res) => {
  try {
    const { code, title, description, discountType, discountValue, minOrderAmount, maxDiscountAmount, startDate, endDate, usageLimit } = req.body;

    const offer = await Offer.create({
      code: code.toUpperCase(),
      title,
      description,
      discountType,
      discountValue,
      minOrderAmount: minOrderAmount || 0,
      maxDiscountAmount: maxDiscountAmount || null,
      startDate: startDate || new Date(),
      endDate: endDate || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      usageLimit: usageLimit || 1000,
      isActive: true,
    });

    // Dispatch promo notification to all customers
    try {
      const discountLabel = offer.discountType === 'percentage'
        ? `${offer.discountValue}% OFF`
        : `Rs. ${offer.discountValue} FLAT OFF`;

      User.find({ role: 'customer' }).select('_id').then((customers) => {
        customers.forEach((c) => {
          createNotification(c._id, {
            title: `New Deal: Use Code ${offer.code} (${discountLabel})! 🎉`,
            body: `${offer.title || 'Special discount active'}: ${offer.description || 'Enjoy extra savings on your late night delivery!'}`,
            type: 'promo',
            data: { offerId: offer._id, code: offer.code, url: '/offers' },
          });
        });
      }).catch(() => {});
    } catch (_) {}

    res.status(201).json({ success: true, offer });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'An offer with this coupon code already exists' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/offers/:id/toggle (Admin)
const toggleOffer = async (req, res) => {
  try {
    const offer = await Offer.findById(req.params.id);
    if (!offer) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }
    offer.isActive = !offer.isActive;
    await offer.save();
    res.json({ success: true, isActive: offer.isActive });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/offers/:id (Admin)
const updateOffer = async (req, res) => {
  try {
    const { code, title, description, discountType, discountValue, minOrderAmount, maxDiscountAmount, startDate, endDate, usageLimit, isActive } = req.body;
    const updateData = {};
    if (code !== undefined) updateData.code = code.toUpperCase();
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (discountType !== undefined) updateData.discountType = discountType;
    if (discountValue !== undefined) updateData.discountValue = discountValue;
    if (minOrderAmount !== undefined) updateData.minOrderAmount = minOrderAmount;
    if (maxDiscountAmount !== undefined) updateData.maxDiscountAmount = maxDiscountAmount;
    if (startDate !== undefined) updateData.startDate = startDate;
    if (endDate !== undefined) updateData.endDate = endDate;
    if (usageLimit !== undefined) updateData.usageLimit = usageLimit;
    if (isActive !== undefined) updateData.isActive = isActive;

    const offer = await Offer.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!offer) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }

    res.json({ success: true, message: 'Offer updated successfully', offer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/offers/:id (Admin)
const deleteOffer = async (req, res) => {
  try {
    const offer = await Offer.findByIdAndDelete(req.params.id);
    if (!offer) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }
    res.json({ success: true, message: 'Offer deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/offers/validate
const validateOffer = async (req, res) => {
  try {
    const { code, orderAmount = 0 } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, message: 'Coupon code is required' });
    }

    const now = new Date();
    const offer = await Offer.findOne({
      code: code.toUpperCase().trim(),
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
    });

    if (!offer) {
      return res.status(404).json({ success: false, message: 'Invalid or expired coupon code' });
    }

    if (orderAmount < (offer.minOrderAmount || 0)) {
      return res.status(400).json({
        success: false,
        message: `Minimum order amount of Rs. ${offer.minOrderAmount} required for this coupon.`,
      });
    }

    let discount = 0;
    if (offer.discountType === 'percentage') {
      discount = Math.round((orderAmount * offer.discountValue) / 100);
      if (offer.maxDiscountAmount) {
        discount = Math.min(discount, offer.maxDiscountAmount);
      }
    } else {
      discount = offer.discountValue;
    }

    res.json({
      success: true,
      message: `Coupon "${offer.code}" applied! Saved Rs. ${discount}`,
      offer: {
        code: offer.code,
        title: offer.title,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        discountAmount: discount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getOffers,
  getAllOffers,
  createOffer,
  toggleOffer,
  updateOffer,
  deleteOffer,
  validateOffer,
};
