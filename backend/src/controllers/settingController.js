const Setting = require('../models/Setting');
const User = require('../models/User');
const RiderLocation = require('../models/RiderLocation');
const bcrypt = require('bcryptjs');
const { getIO } = require('../sockets');

// GET /api/admin/settings
const getSettings = async (req, res) => {
  try {
    let settings = await Setting.findOne();
    if (!settings) {
      settings = await Setting.create({
        alcoholEnabled: false,
        storeOpen: true,
        defaultDeliveryFee: 100,
        surgeFeePerKm: 25,
        freeDeliveryThreshold: 1500,
      });
    }
    res.json({ success: true, settings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/admin/settings (Admin)
const updateSettings = async (req, res) => {
  try {
    let settings = await Setting.findOne();
    if (!settings) {
      settings = new Setting();
    }

    const {
      alcoholEnabled,
      storeOpen,
      defaultDeliveryFee,
      freeDeliveryThreshold,
      serviceHours,
      contactPhone,
      contactEmail,
    } = req.body;

    if (alcoholEnabled !== undefined) settings.alcoholEnabled = alcoholEnabled;
    if (storeOpen !== undefined) settings.storeOpen = storeOpen;
    if (defaultDeliveryFee !== undefined) settings.defaultDeliveryFee = defaultDeliveryFee;
    if (freeDeliveryThreshold !== undefined) settings.freeDeliveryThreshold = freeDeliveryThreshold;
    if (serviceHours !== undefined) settings.serviceHours = serviceHours;
    if (contactPhone !== undefined) settings.contactPhone = contactPhone;
    if (contactEmail !== undefined) settings.contactEmail = contactEmail;

    await settings.save();

    res.json({ success: true, message: 'Store settings updated successfully', settings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/admin/riders (Admin)
const getAllRiders = async (req, res) => {
  try {
    const riders = await User.find({ role: 'rider' }).select(
      'name phone email isOnline vehicleNumber vehicleType currentCoordinates status updatedAt'
    );
    res.json({ success: true, count: riders.length, riders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/admin/settings/riders (Admin)
const createRider = async (req, res) => {
  try {
    const { name, phone, email, password, vehicleNumber, vehicleType, isOnline = true, currentCoordinates } = req.body;

    if (!name || !phone) {
      return res.status(400).json({ success: false, message: 'Rider name and phone are required' });
    }

    const cleanPhone = phone.trim();
    const existing = await User.findOne({ phone: cleanPhone });
    if (existing) {
      return res.status(400).json({ success: false, message: 'A user or rider with this phone already exists' });
    }

    const rawPassword = (password && password.trim()) ? password.trim() : 'Rider@123';
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const rider = await User.create({
      name: name.trim(),
      phone: cleanPhone,
      email: email ? email.trim() : undefined,
      password: hashedPassword,
      role: 'rider',
      isOnline,
      vehicleNumber: vehicleNumber || 'BA 99 PA 0000',
      vehicleType: vehicleType || 'Motorcycle',
      currentCoordinates: currentCoordinates || [85.3240, 27.7172],
      status: 'active',
      ageConfirmed: true,
    });

    res.status(201).json({
      success: true,
      message: 'Rider created successfully with direct mobile login credentials',
      rider,
      loginId: cleanPhone,
      initialPassword: rawPassword,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/admin/settings/riders/:id (Admin)
const updateRider = async (req, res) => {
  try {
    const { name, phone, email, password, vehicleNumber, vehicleType, isOnline, status, currentCoordinates } = req.body;
    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (phone !== undefined) updateData.phone = phone.trim();
    if (email !== undefined) updateData.email = email.trim();
    if (vehicleNumber !== undefined) updateData.vehicleNumber = vehicleNumber;
    if (vehicleType !== undefined) updateData.vehicleType = vehicleType;
    if (isOnline !== undefined) updateData.isOnline = isOnline;
    if (status !== undefined) updateData.status = status;
    if (currentCoordinates !== undefined) updateData.currentCoordinates = currentCoordinates;
    if (password && password.trim()) {
      updateData.password = await bcrypt.hash(password.trim(), 10);
    }

    const rider = await User.findOneAndUpdate(
      { _id: req.params.id, role: 'rider' },
      updateData,
      { new: true, runValidators: true }
    );

    if (!rider) {
      return res.status(404).json({ success: false, message: 'Rider not found' });
    }

    res.json({ success: true, message: 'Rider updated successfully', rider });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/admin/settings/riders/:id (Admin)
const deleteRider = async (req, res) => {
  try {
    const rider = await User.findOneAndDelete({ _id: req.params.id, role: 'rider' });
    if (!rider) {
      return res.status(404).json({ success: false, message: 'Rider not found' });
    }
    res.json({ success: true, message: 'Rider removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/admin/settings/riders/:id/toggle (Admin)
const toggleRiderDuty = async (req, res) => {
  try {
    const rider = await User.findOne({ _id: req.params.id, role: 'rider' });
    if (!rider) {
      return res.status(404).json({ success: false, message: 'Rider not found' });
    }
    rider.isOnline = !rider.isOnline;
    await rider.save();
    res.json({ success: true, isOnline: rider.isOnline, message: `Rider is now ${rider.isOnline ? 'Online' : 'Offline'}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/rider/location (Rider)
const updateRiderLocation = async (req, res) => {
  try {
    const { coordinates, orderId, heading, speed } = req.body;
    // coordinates: [longitude, latitude] e.g. [85.3240, 27.7172] for Kathmandu

    if (!coordinates || coordinates.length !== 2) {
      return res.status(400).json({ success: false, message: 'Invalid coordinates array [lng, lat]' });
    }

    await User.findByIdAndUpdate(req.user._id, {
      currentCoordinates: coordinates,
    });

    const locationRecord = await RiderLocation.create({
      rider: req.user._id,
      order: orderId || null,
      location: {
        type: 'Point',
        coordinates,
      },
      heading: heading || 0,
      speed: speed || 0,
    });

    // Real-time broadcast
    const broadcastData = {
      riderId: req.user._id,
      riderName: req.user.name,
      orderId,
      coordinates,
      heading,
      speed,
      updatedAt: new Date(),
    };

    try {
      getIO().to('admin-room').emit('rider:location', broadcastData);
      if (orderId) {
        getIO().to(`order:${orderId}`).emit('rider:location', broadcastData);
      }
    } catch (e) {
      console.error('[Socket Location Error]', e.message);
    }

    res.json({ success: true, message: 'Location updated', data: broadcastData });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getSettings,
  updateSettings,
  getAllRiders,
  createRider,
  updateRider,
  deleteRider,
  toggleRiderDuty,
  updateRiderLocation,
};
