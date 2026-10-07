const express = require('express');
const router = express.Router();
const { globalSearch, aiSearch } = require('../controllers/searchController');
const { 
  createSearchAlert, 
  getSearchAlerts, 
  updateSearchAlertStatus, 
  deleteSearchAlert 
} = require('../controllers/searchAlertController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, globalSearch);
router.get('/ai', protect, aiSearch);
router.post('/ai', protect, aiSearch);

// Search Alerts API
router.post('/', protect, createSearchAlert);
router.post('/alerts', protect, createSearchAlert);
router.get('/alerts', protect, getSearchAlerts);
router.patch('/alerts/:id/status', protect, updateSearchAlertStatus);
router.put('/alerts/:id/status', protect, updateSearchAlertStatus);
router.delete('/alerts/:id', protect, deleteSearchAlert);

// Direct Search Alerts Routes (for /api/search-alerts)
router.patch('/:id/status', protect, updateSearchAlertStatus);
router.patch('/:id/toggle', protect, async (req, res, next) => {
  try {
    const alert = await require('../models/SearchAlert').findById(req.params.id);
    if (!alert) return res.status(404).json({ success: false, message: 'Search alert not found' });
    if (alert.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    alert.status = alert.status === 'active' ? 'paused' : 'active';
    await alert.save();
    res.json({ success: true, alert });
  } catch (e) {
    next(e);
  }
});
router.delete('/:id', protect, deleteSearchAlert);

module.exports = router;
