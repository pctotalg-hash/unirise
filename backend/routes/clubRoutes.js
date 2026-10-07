const express = require('express');
const router = express.Router();
const { 
  getClubs, createClub, getClubById, updateClub, 
  getClubPosts, getClubEvents, getClubCoreTeam, getClubMembers 
} = require('../controllers/clubController');
const { getPositionsByClub, assignPosition, transferPosition } = require('../controllers/positionController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/rbacMiddleware');

router.get('/', protect, getClubs);
router.post('/', protect, authorize('admin', 'club_coordinator'), createClub);
router.get('/:id', protect, getClubById);
router.put('/:id', protect, authorize('admin', 'club_coordinator'), updateClub);

router.get('/:id/posts', protect, getClubPosts);
router.get('/:id/events', protect, getClubEvents);
router.get('/:id/core-team', protect, getClubCoreTeam);
router.get('/:id/members', protect, getClubMembers);

// Positions
router.get('/:id/positions', protect, getPositionsByClub);
router.post('/:id/positions', protect, authorize('admin', 'club_coordinator'), assignPosition);
router.post('/:id/positions/:positionId/transfer', protect, authorize('admin', 'club_coordinator'), transferPosition);

module.exports = router;
