const mongoose = require('mongoose');

const ClubPositionSchema = new mongoose.Schema({
  clubId: { type: mongoose.Schema.Types.ObjectId, ref: 'Club', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  positionName: { type: String, required: true }, // e.g. "President", "Vice President", "Secretary", "Tech Head"
  status: { type: String, enum: ['ACTIVE', 'TRANSFERRED', 'REVOKED'], default: 'ACTIVE' },
  assignedAt: { type: Date, default: Date.now },
  transferredAt: { type: Date },
  previousHolder: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  transferHistory: [{
    fromUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    toUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    transferredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    date: { type: Date, default: Date.now }
  }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ClubPosition', ClubPositionSchema);
