const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  receiverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // for 1-on-1 private chat
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', default: null },   // for community group chat
  isPublicCampusChat: { type: Boolean, default: false },                              // for Section A open chat
  content: { type: String, required: true },
  replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
  isEdited: { type: Boolean, default: false },
  isDeleted: { type: Boolean, default: false },
  reactions: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    emoji: { type: String }
  }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Compound & single-field indexes for query performance & scale
MessageSchema.index({ senderId: 1, receiverId: 1, createdAt: 1 });
MessageSchema.index({ groupId: 1, createdAt: 1 });
MessageSchema.index({ isPublicCampusChat: 1, createdAt: 1 });
MessageSchema.index({ replyTo: 1 });

module.exports = mongoose.model('Message', MessageSchema);
