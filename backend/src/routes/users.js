const express = require('express');
const router = express.Router();
const {
  getAllUsers,
  getUserById,
  updateUserStatus,
  updateUserRole,
  deleteUser,
} = require('../controllers/userController');
const { protect, requireRole } = require('../middleware/auth');

// All endpoints in this router are restricted to Administrator
router.use(protect, requireRole('admin'));

router.get('/', getAllUsers);
router.get('/:id', getUserById);
router.patch('/:id/status', updateUserStatus);
router.patch('/:id/role', updateUserRole);
router.delete('/:id', deleteUser);

module.exports = router;
