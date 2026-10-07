const express = require('express');
const router = express.Router();
const { getGroups, createGroup, getGroupById, addGroupMember, removeGroupMember } = require('../controllers/groupController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getGroups);
router.post('/', protect, createGroup);
router.get('/:id', protect, getGroupById);
router.post('/:id/members', protect, addGroupMember);
router.delete('/:id/members/:userId', protect, removeGroupMember);

module.exports = router;
