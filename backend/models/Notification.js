const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Alias for actorId for backwards compatibility
  type: { 
    type: String, 
    enum: [
      'CLUB_POST', 'CLUB_EVENT', 'CLUB_ANNOUNCEMENT', 'CLUB_INVITE', 'CLUB_APPROVAL',
      'PERSONAL_CHAT', 'GROUP_CHAT', 'COMMUNITY', 'MENTION', 'REPLY', 'LIKE', 'COMMENT',
      'CONNECTION_REQUEST', 'CONNECTION_ACCEPTED', 'POSITION_UPDATE', 'POSITION_TRANSFER',
      'VERIFICATION_UPDATE', 'AI_SEARCH_ALERT'
    ],
    required: true,
    index: true
  },
  title: { type: String, required: true },
  body: { type: String, required: true },
  message: { type: String }, // Alias for body
  entityType: { type: String, enum: ['post', 'event', 'club', 'user', 'group', 'chat', 'opportunity', 'hackathon', 'internship', 'search_alert'] },
  entityId: { type: String, index: true },
  referenceId: { type: String }, // Legacy field alias
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  isRead: { type: Boolean, default: false, index: true },
  createdAt: { type: Date, default: Date.now },
  readAt: { type: Date }
});

// Compound indexes
NotificationSchema.index({ recipientId: 1, createdAt: -1 });
NotificationSchema.index({ recipientId: 1, isRead: 1 });

module.exports = mongoose.model('Notification', NotificationSchema);
