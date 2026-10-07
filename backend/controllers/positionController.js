const ClubPosition = require('../models/ClubPosition');
const User = require('../models/User');
const Club = require('../models/Club');
const Notification = require('../models/Notification');

// GET /api/clubs/:id/positions
const getPositionsByClub = async (req, res, next) => {
  try {
    const positions = await ClubPosition.find({ clubId: req.params.id })
      .populate('userId', 'name profilePhoto role isVerified verifiedBadge')
      .populate('previousHolder', 'name profilePhoto')
      .sort({ assignedAt: -1 });
    res.json(positions);
  } catch (err) {
    next(err);
  }
};

// POST /api/clubs/:id/positions
const assignPosition = async (req, res, next) => {
  try {
    const { userId, positionName } = req.body;
    const clubId = req.params.id;

    if (!userId || !positionName) {
      return res.status(400).json({ message: 'User ID and position name are required' });
    }

    const club = await Club.findById(clubId);
    if (!club) return res.status(404).json({ message: 'Club not found' });

    // Check authorization: Admin or assigned coordinator
    const isCoordinator = club.coordinatorId && club.coordinatorId.toString() === req.user._id.toString();
    if (!isCoordinator && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Not authorized to assign positions for this club' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'Target user not found' });

    const newPosition = await ClubPosition.create({
      clubId,
      userId,
      positionName,
      status: 'ACTIVE',
      assignedAt: Date.now()
    });

    // Update user profile verified badge link!
    user.isVerified = true;
    user.verifiedBadge = `${club.name.toUpperCase()} ${positionName.toUpperCase()}`;
    user.verifiedClubId = club._id;
    if (user.role === 'STUDENT') {
      user.role = 'CLUB_COORDINATOR'; // Upgrade role if applicable
    }
    await user.save();

    // Create notification
    await Notification.create({
      recipientId: user._id,
      senderId: req.user._id,
      type: 'POSITION_TRANSFER',
      title: 'Club Position Assigned',
      message: `You have been officially assigned as ${positionName} of ${club.name}!`,
      referenceId: club._id.toString()
    });

    res.status(201).json(newPosition);
  } catch (err) {
    next(err);
  }
};

// POST /api/clubs/:id/positions/:positionId/transfer
const transferPosition = async (req, res, next) => {
  try {
    const { newUserId } = req.body;
    const { id: clubId, positionId } = req.params;

    if (!newUserId) {
      return res.status(400).json({ message: 'newUserId is required for position transfer' });
    }

    const club = await Club.findById(clubId);
    if (!club) return res.status(404).json({ message: 'Club not found' });

    // Check permission
    const isCoordinator = club.coordinatorId && club.coordinatorId.toString() === req.user._id.toString();
    if (!isCoordinator && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Not authorized to transfer positions for this club' });
    }

    const positionRecord = await ClubPosition.findById(positionId);
    if (!positionRecord) return res.status(404).json({ message: 'Position record not found' });

    const oldUserId = positionRecord.userId;
    const oldUser = await User.findById(oldUserId);
    const newUser = await User.findById(newUserId);

    if (!newUser) return res.status(404).json({ message: 'New candidate user not found' });

    // Execute Position Transfer
    positionRecord.status = 'TRANSFERRED';
    positionRecord.transferredAt = Date.now();
    await positionRecord.save();

    // Create new active position record for the new user
    const newPositionRecord = await ClubPosition.create({
      clubId,
      userId: newUserId,
      positionName: positionRecord.positionName,
      status: 'ACTIVE',
      assignedAt: Date.now(),
      previousHolder: oldUserId,
      transferHistory: [
        ...(positionRecord.transferHistory || []),
        {
          fromUser: oldUserId,
          toUser: newUserId,
          transferredBy: req.user._id,
          date: Date.now()
        }
      ]
    });

    // Update Old User badge
    if (oldUser) {
      oldUser.verifiedBadge = null;
      oldUser.verifiedClubId = null;
      await oldUser.save();

      await Notification.create({
        recipientId: oldUser._id,
        senderId: req.user._id,
        type: 'POSITION_TRANSFER',
        title: 'Position Transferred',
        message: `Your position "${positionRecord.positionName}" in ${club.name} was transferred to ${newUser.name}.`,
        referenceId: club._id.toString()
      });
    }

    // Update New User badge
    newUser.isVerified = true;
    newUser.verifiedBadge = `${club.name.toUpperCase()} ${positionRecord.positionName.toUpperCase()}`;
    newUser.verifiedClubId = club._id;
    if (newUser.role === 'STUDENT') {
      newUser.role = 'CLUB_COORDINATOR';
    }
    await newUser.save();

    await Notification.create({
      recipientId: newUser._id,
      senderId: req.user._id,
      type: 'POSITION_TRANSFER',
      title: 'Position Transfer Complete',
      message: `Congratulations! You are now official ${positionRecord.positionName} of ${club.name}!`,
      referenceId: club._id.toString()
    });

    res.json({
      message: `Position successfully transferred from ${oldUser ? oldUser.name : 'Previous'} to ${newUser.name}`,
      position: newPositionRecord
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getPositionsByClub,
  assignPosition,
  transferPosition
};
