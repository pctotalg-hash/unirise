const express = require('express');
const router = express.Router();
const { getEvents, createEvent, getEventById, deleteEvent } = require('../controllers/eventController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/rbacMiddleware');

router.get('/', protect, getEvents);
router.post('/', protect, authorize('admin', 'club_coordinator'), createEvent);
router.get('/:id', protect, getEventById);
router.delete('/:id', protect, authorize('admin', 'club_coordinator'), deleteEvent);

module.exports = router;
