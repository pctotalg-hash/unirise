const express = require('express');
const router = express.Router();
const { 
  getUsers, getUserById, updateUser, 
  addAchievement, deleteAchievement, 
  getUserPosts, connectUser 
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getUsers);
router.put('/profile', protect, updateUser);
router.get('/:id', protect, getUserById);
router.put('/:id', protect, updateUser);
router.post('/:id/achievements', protect, addAchievement);
router.delete('/:id/achievements/:achId', protect, deleteAchievement);
router.get('/:id/posts', protect, getUserPosts);
router.post('/:id/connect', protect, connectUser);

module.exports = router;
