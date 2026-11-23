const mongoose = require('mongoose');
const User = require('../models/User');
const Product = require('../models/Product');

/// The customer's saved products, with the product details filled in.
const getWishlist = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select('wishlist')
      .populate('wishlist', 'name price images category isAlcohol stock discountPrice');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    // A product deleted since it was saved populates as null; drop those
    // rather than handing the app a hole in the list.
    const items = (user.wishlist || []).filter(Boolean);

    res.json({ success: true, count: items.length, products: items });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/// Saves a product. $addToSet keeps it idempotent, so tapping twice cannot
/// put the same product in the list twice.
const addToWishlist = async (req, res) => {
  try {
    const { productId } = req.body;
    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return res.status(400).json({ success: false, message: 'A valid product is required' });
    }

    const exists = await Product.exists({ _id: productId });
    if (!exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { wishlist: productId },
    });

    res.json({ success: true, message: 'Saved to your list' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/// Removes a product from the list.
const removeFromWishlist = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'A valid product is required' });
    }

    await User.findByIdAndUpdate(req.user._id, {
      $pull: { wishlist: id },
    });

    res.json({ success: true, message: 'Removed from your list' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getWishlist, addToWishlist, removeFromWishlist };
