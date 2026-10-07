const Notification = require('../models/Notification');

// GET /api/notifications
const getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({ recipientId: req.user._id })
      .populate('actorId', 'name profilePhoto role isVerified verifiedBadge')
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .sort({ createdAt: -1 });

    const unreadCount = notifications.filter(n => !n.isRead).length;

    res.json({
      success: true,
      notifications: notifications || [],
      unreadCount
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/notifications/unread-count
const getUnreadCount = async (req, res, next) => {
  try {
    const unreadCount = await Notification.countDocuments({ 
      recipientId: req.user._id, 
      isRead: false 
    });

    res.json({
      success: true,
      unreadCount
    });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/:id/read or PUT
const markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findById(req.params.id);
    if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

    if (notification.recipientId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    notification.isRead = true;
    notification.readAt = Date.now();
    await notification.save();

    const unreadCount = await Notification.countDocuments({ recipientId: req.user._id, isRead: false });

    res.json({
      success: true,
      notification,
      unreadCount
    });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/notifications/read-all or PUT
const markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany(
      { recipientId: req.user._id, isRead: false }, 
      { isRead: true, readAt: Date.now() }
    );

    res.json({ 
      success: true, 
      message: 'All notifications marked as read',
      unreadCount: 0
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/notifications/:id
const deleteNotification = async (req, res, next) => {
  try {
    const notification = await Notification.findById(req.params.id);
    if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

    if (notification.recipientId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await notification.deleteOne();

    const unreadCount = await Notification.countDocuments({ recipientId: req.user._id, isRead: false });

    res.json({
      success: true,
      message: 'Notification deleted successfully',
      unreadCount
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification
};
