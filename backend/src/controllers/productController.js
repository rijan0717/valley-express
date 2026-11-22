const Product = require('../models/Product');
const Category = require('../models/Category');
const Setting = require('../models/Setting');
const User = require('../models/User');
const { createNotification } = require('./notificationController');

// GET /api/products
const getProducts = async (req, res) => {
  try {
    const { category, search, isAlcohol, activeOnly = 'true' } = req.query;

    let query = {};
    if (activeOnly === 'true') {
      query.isActive = true;
    }

    if (category) {
      query.category = category;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { nameNe: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    // Check store settings regarding alcohol
    const settings = await Setting.findOne();
    const alcoholGlobalEnabled = settings ? settings.alcoholEnabled : false;

    // If client is asking for alcohol or checking restriction
    if (isAlcohol !== undefined) {
      query.isAlcohol = isAlcohol === 'true';
    } else if (!alcoholGlobalEnabled) {
      // If alcohol sales are globally disabled (licensing pending), hide alcohol items for public users
      if (!req.user || req.user.role !== 'admin') {
        query.isAlcohol = false;
      }
    }

    const products = await Product.find(query).populate('category').sort({ createdAt: -1 });

    res.json({
      success: true,
      count: products.length,
      alcoholGlobalEnabled,
      products,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/products/:id
const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, product });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/products (Admin)
const createProduct = async (req, res) => {
  try {
    const { name, nameNe, description, category, price, discountPrice, stock, unit, images, isAlcohol, alcoholPercentage, isFeatured } = req.body;

    const product = await Product.create({
      name,
      nameNe,
      description,
      category,
      price,
      discountPrice,
      stock: stock || 0,
      unit: unit || 'item',
      images: images || [],
      isAlcohol: isAlcohol || false,
      alcoholPercentage: alcoholPercentage || 0,
      isFeatured: isFeatured || false,
      isActive: true,
    });

    const populatedProduct = await Product.findById(product._id).populate('category');

    // If product has a special discount price, notify customers
    if (discountPrice && Number(discountPrice) < Number(price)) {
      User.find({ role: 'customer' }).select('_id').then((customers) => {
        customers.forEach((c) => {
          createNotification(c._id, {
            title: `Product Deal: ${product.name}! 🔥`,
            body: `Now on sale for Rs. ${product.discountPrice} (Reduced from Rs. ${product.price})! Tap to order.`,
            type: 'promo',
            data: { productId: product._id, url: `/product/${product._id}` },
          });
        });
      }).catch(() => {});
    }

    res.status(201).json({ success: true, message: 'Product created successfully', product: populatedProduct });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/products/:id (Admin)
const updateProduct = async (req, res) => {
  try {
    const updateData = { ...req.body };
    if (updateData.category && typeof updateData.category === 'object' && updateData.category._id) {
      updateData.category = updateData.category._id;
    }

    const product = await Product.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    }).populate('category');

    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    // If product is put on offer or discountPrice is set
    if (updateData.discountPrice && Number(updateData.discountPrice) < Number(product.price)) {
      User.find({ role: 'customer' }).select('_id').then((customers) => {
        customers.forEach((c) => {
          createNotification(c._id, {
            title: `Price Drop: ${product.name}! 🔥`,
            body: `Now on sale for Rs. ${product.discountPrice} (Reduced from Rs. ${product.price})! Tap to order now.`,
            type: 'promo',
            data: { productId: product._id, url: `/product/${product._id}` },
          });
        });
      }).catch(() => {});
    }

    res.json({ success: true, message: 'Product updated successfully', product });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/products/:id (Admin)
const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, message: 'Product removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
};
