const Category = require('../models/Category');

// GET /api/categories
const getCategories = async (req, res) => {
  try {
    const { activeOnly = 'true' } = req.query;
    const filter = activeOnly === 'true' ? { isActive: true } : {};
    const categories = await Category.find(filter).sort({ sortOrder: 1, createdAt: 1 });
    res.json({ success: true, count: categories.length, categories });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/categories (Admin)
const createCategory = async (req, res) => {
  try {
    const { name, nameNe, slug, icon, isRestricted, sortOrder, isActive } = req.body;
    const category = await Category.create({
      name,
      nameNe,
      slug: slug || name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      icon: icon || '',
      isRestricted: isRestricted || false,
      sortOrder: sortOrder || 0,
      isActive: isActive !== undefined ? isActive : true,
    });
    res.status(201).json({ success: true, category });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/categories/:id (Admin)
const updateCategory = async (req, res) => {
  try {
    const { name, nameNe, slug, icon, isRestricted, sortOrder, isActive } = req.body;
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (nameNe !== undefined) updateData.nameNe = nameNe;
    if (slug !== undefined) updateData.slug = slug;
    if (icon !== undefined) updateData.icon = icon;
    if (isRestricted !== undefined) updateData.isRestricted = isRestricted;
    if (sortOrder !== undefined) updateData.sortOrder = sortOrder;
    if (isActive !== undefined) updateData.isActive = isActive;

    const category = await Category.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }

    res.json({ success: true, message: 'Category updated successfully', category });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/categories/:id (Admin)
const deleteCategory = async (req, res) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, message: 'Category deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getCategories, createCategory, updateCategory, deleteCategory };
