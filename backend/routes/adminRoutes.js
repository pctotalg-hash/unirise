const express = require('express');
const router = express.Router();
const { 
  getDashboardStats, getAdminUsers, getAdminClubs, 
  verifyUser, verifyClub, deletePostAdmin, getReports 
} = require('../controllers/adminController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/rbacMiddleware');

router.use(protect);
router.use(authorize('admin', 'college_admin', 'platform_admin'));

router.get('/dashboard', getDashboardStats);
router.get('/users', getAdminUsers);
router.get('/clubs', getAdminClubs);
router.post('/verify-user', verifyUser);
router.post('/verify-club', verifyClub);
router.delete('/posts/:id', deletePostAdmin);
router.get('/reports', getReports);

module.exports = router;
