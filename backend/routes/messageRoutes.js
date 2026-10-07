const express = require('express');
const router = express.Router();
const { 
  getMessages, 
  getPublicMessages, 
  getPrivateMessages, 
  getGroupMessages, 
  sendMessage, 
  updateMessage, 
  deleteMessage,
  reactToMessage 
} = require('../controllers/messageController');
const { protect } = require('../middleware/authMiddleware');

router.get('/public', protect, getPublicMessages);
router.get('/private/:userId', protect, getPrivateMessages);
router.get('/group/:groupId', protect, getGroupMessages);
router.get('/:targetId', protect, getMessages);

router.post('/', protect, sendMessage);
router.put('/:id', protect, updateMessage);
router.patch('/:id', protect, updateMessage);
router.delete('/:id', protect, deleteMessage);
router.post('/:id/react', protect, reactToMessage);

module.exports = router;
