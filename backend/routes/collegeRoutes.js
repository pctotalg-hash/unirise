const express = require('express');
const router = express.Router();
const {
  getPublicColleges,
  registerCollege,
  getAllCollegesAdmin,
  updateCollegeStatusAdmin
} = require('../controllers/collegeController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/rbacMiddleware');

// Public directory & signup routes
router.get('/', getPublicColleges);
router.post('/register', registerCollege);

// Admin management routes
router.get('/admin/all', protect, authorize('admin', 'college_admin', 'platform_admin'), getAllCollegesAdmin);
router.put('/admin/:id/status', protect, authorize('admin', 'college_admin', 'platform_admin'), updateCollegeStatusAdmin);

module.exports = router;
