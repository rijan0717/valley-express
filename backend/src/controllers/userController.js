const User = require('../models/User');
const Order = require('../models/Order');

// GET /api/users
// Admin: Get all registered users with metrics and filters
const getAllUsers = async (req, res) => {
  try {
    const { role, status, search } = req.query;
    const filter = {};

    if (role && role !== 'all') {
      filter.role = role;
    }

    if (status && status !== 'all') {
      filter.status = status;
    }

    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), 'i');
      filter.$or = [
        { name: searchRegex },
        { phone: searchRegex },
        { email: searchRegex },
      ];
    }

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .lean();

    // Aggregate orders count and total spent for these users
    const userIds = users.map((u) => u._id);
    const orderAggregates = await Order.aggregate([
      {
        $match: {
          customer: { $in: userIds },
          status: { $ne: 'cancelled' },
        },
      },
      {
        $group: {
          _id: '$customer',
          orderCount: { $sum: 1 },
          totalSpent: { $sum: '$total' },
        },
      },
    ]);

    const orderStatsMap = new Map();
    orderAggregates.forEach((agg) => {
      orderStatsMap.set(agg._id.toString(), {
        orderCount: agg.orderCount,
        totalSpent: agg.totalSpent,
      });
    });

    const enrichedUsers = users.map((u) => {
      const stats = orderStatsMap.get(u._id.toString()) || { orderCount: 0, totalSpent: 0 };
      return {
        ...u,
        orderCount: stats.orderCount,
        totalSpent: stats.totalSpent,
      };
    });

    // Compute summary KPI counts
    const totalCount = await User.countDocuments();
    const customerCount = await User.countDocuments({ role: 'customer' });
    const riderCount = await User.countDocuments({ role: 'rider' });
    const adminCount = await User.countDocuments({ role: 'admin' });
    const ageVerifiedCount = await User.countDocuments({ ageConfirmed: true });

    res.json({
      success: true,
      count: enrichedUsers.length,
      users: enrichedUsers,
      summary: {
        total: totalCount,
        customers: customerCount,
        riders: riderCount,
        admins: adminCount,
        ageVerified: ageVerifiedCount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/:id
// Admin: Get specific user details with addresses and order history
const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const orders = await Order.find({ customer: user._id })
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      user,
      recentOrders: orders,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/users/:id/status
// Admin: Suspend or activate a registered user
const updateUserStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!['active', 'suspended', 'pending_approval'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value' });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.email === 'admin@gmail.com' && status !== 'active') {
      return res.status(400).json({ success: false, message: 'Primary administrator cannot be suspended' });
    }

    user.status = status;
    await user.save();

    res.json({
      success: true,
      message: `User status updated to ${status}`,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/users/:id/role
// Admin: Change user role (customer, rider, admin)
const updateUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    if (!['customer', 'rider', 'admin'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Invalid role value' });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.email === 'admin@gmail.com' && role !== 'admin') {
      return res.status(400).json({ success: false, message: 'Primary administrator role cannot be altered' });
    }

    user.role = role;
    await user.save();

    res.json({
      success: true,
      message: `User role updated to ${role}`,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/users/:id
// Admin: Delete registered user
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.email === 'admin@gmail.com') {
      return res.status(400).json({ success: false, message: 'Primary administrator cannot be deleted' });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'User removed from registered database',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUserStatus,
  updateUserRole,
  deleteUser,
};
