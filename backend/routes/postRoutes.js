const express = require('express');
const router = express.Router();
const { 
  getPosts, createPost, getPostById, updatePost, deletePost, 
  likePost, commentPost, sharePost 
} = require('../controllers/postController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getPosts);
router.post('/', protect, createPost);
router.get('/:id', protect, getPostById);
router.put('/:id', protect, updatePost);
router.delete('/:id', protect, deletePost);
router.post('/:id/like', protect, likePost);
router.post('/:id/comment', protect, commentPost);
router.post('/:id/share', protect, sharePost);

module.exports = router;
