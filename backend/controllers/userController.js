const User = require('../models/User');
const Post = require('../models/Post');
const Connection = require('../models/Connection');
const ClubPosition = require('../models/ClubPosition');

// Helper to get connection status between 2 users
const getConnectionStatusBetween = async (userAId, userBId) => {
  if (!userAId || !userBId || userAId.toString() === userBId.toString()) {
    return 'SELF';
  }

  const userA = await User.findById(userAId);
  const userB = await User.findById(userBId);
  if (!userA || !userB) return 'NONE';

  const inA = userA.connections.some(c => c.toString() === userBId.toString());
  const inB = userB.connections.some(c => c.toString() === userAId.toString());

  const conn = await Connection.findOne({
    $or: [
      { senderId: userAId, receiverId: userBId },
      { senderId: userBId, receiverId: userAId }
    ]
  });

  if (conn) {
    if (conn.status === 'ACCEPTED') {
      if (!inA) { userA.connections.push(userBId); await userA.save(); }
      if (!inB) { userB.connections.push(userAId); await userB.save(); }
      return 'ACCEPTED';
    }
    if (conn.status === 'PENDING') {
      if (conn.senderId.toString() === userAId.toString()) {
        return 'PENDING_SENT';
      } else {
        return 'PENDING_RECEIVED';
      }
    }
  }

  if (inA || inB) {
    return 'ACCEPTED';
  }

  return 'NONE';
};

// GET /api/users
const getUsers = async (req, res, next) => {
  try {
    const users = await User.find()
      .select('-passwordHash')
      .populate('collegeId', 'name shortName logo isVerified')
      .populate('verifiedClubId', 'name logo');
    res.json(users);
  } catch (err) {
    next(err);
  }
};

// GET /api/users/:id
const getUserById = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-passwordHash')
      .populate('collegeId', 'name shortName logo isVerified')
      .populate('connections', 'name profilePhoto role isVerified verifiedBadge department year')
      .populate('verifiedClubId', 'name logo coverImage isVerified tagline');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const positions = await ClubPosition.find({ userId: req.params.id })
      .populate('clubId', 'name logo coverImage tagline');

    const userObj = user.toObject();
    userObj.positions = positions || [];

    if (req.user) {
      userObj.connectionStatus = await getConnectionStatusBetween(req.user._id, req.params.id);
    } else {
      userObj.connectionStatus = 'NONE';
    }

    res.json(userObj);
  } catch (err) {
    next(err);
  }
};

// PUT /api/users/:id
const updateUser = async (req, res, next) => {
  try {
    const targetUserId = (!req.params.id || req.params.id === 'profile') 
      ? req.user._id.toString() 
      : req.params.id;

    const isOwner = req.user._id.toString() === targetUserId;
    const isAdmin = req.user.role === 'admin' || req.user.role === 'ADMIN' || req.user.role === 'platform_admin';

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ message: 'Not authorized to update this profile' });
    }

    const { 
      name, bio, skills, achievements, structuredAchievements, 
      interests, profilePhoto, coverPhoto, department, year, socialLinks,
      role, collegeId, isVerified, verifiedBadge, verifiedClubId
    } = req.body;
    
    // STRICT BACKEND SECURITY CHECK: Non-admin users cannot change role, collegeId, or verification fields
    if (!isAdmin) {
      if (role !== undefined || collegeId !== undefined || isVerified !== undefined || verifiedBadge !== undefined || verifiedClubId !== undefined) {
        return res.status(403).json({ message: 'Forbidden: Cannot modify role, collegeId, or verification attributes' });
      }
    }

    const user = await User.findById(targetUserId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (skills) user.skills = skills;
    if (achievements) user.achievements = achievements;
    if (structuredAchievements) user.structuredAchievements = structuredAchievements;
    if (interests) user.interests = interests;
    if (profilePhoto) user.profilePhoto = profilePhoto;
    if (coverPhoto) user.coverPhoto = coverPhoto;
    if (department) user.department = department;
    if (year) user.year = year;
    if (socialLinks) user.socialLinks = { ...user.socialLinks, ...socialLinks };

    // Verified fields can ONLY be changed by Admin
    if (isAdmin) {
      if (role) user.role = role.toLowerCase();
      if (collegeId) user.collegeId = collegeId;
      if (isVerified !== undefined) user.isVerified = isVerified;
      if (verifiedBadge !== undefined) user.verifiedBadge = verifiedBadge;
      if (verifiedClubId !== undefined) user.verifiedClubId = verifiedClubId;
    }

    user.updatedAt = Date.now();

    await user.save();
    res.json(user);
  } catch (err) {
    next(err);
  }
};

// POST /api/users/:id/achievements
const addAchievement = async (req, res, next) => {
  try {
    const isOwner = req.user._id.toString() === req.params.id;
    if (!isOwner && req.user.role !== 'admin' && req.user.role !== 'ADMIN' && req.user.role !== 'platform_admin') {
      return res.status(403).json({ message: 'Not authorized to add achievements to this profile' });
    }

    const { title, description, date, organization, certificateUrl } = req.body;
    if (!title) {
      return res.status(400).json({ message: 'Achievement title is required' });
    }

    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (!user.structuredAchievements) user.structuredAchievements = [];
    user.structuredAchievements.push({ title, description, date, organization, certificateUrl });
    
    // Also push title to string achievements for backward compatibility
    user.achievements.push(`${title}${organization ? ' - ' + organization : ''}`);
    user.updatedAt = Date.now();

    await user.save();
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
};

// DELETE /api/users/:id/achievements/:achId
const deleteAchievement = async (req, res, next) => {
  try {
    const isOwner = req.user._id.toString() === req.params.id;
    if (!isOwner && req.user.role !== 'admin' && req.user.role !== 'ADMIN' && req.user.role !== 'platform_admin') {
      return res.status(403).json({ message: 'Not authorized to delete achievements from this profile' });
    }

    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const achId = req.params.achId;
    user.structuredAchievements = (user.structuredAchievements || []).filter(a => a._id.toString() !== achId);
    user.updatedAt = Date.now();

    await user.save();
    res.json(user);
  } catch (err) {
    next(err);
  }
};

// GET /api/users/:id/posts
const getUserPosts = async (req, res, next) => {
  try {
    const posts = await Post.find({ authorId: req.params.id })
      .populate('authorId', 'name profilePhoto role isVerified verifiedBadge')
      .populate('clubId', 'name logo')
      .sort({ createdAt: -1 });
    res.json(posts);
  } catch (err) {
    next(err);
  }
};

// POST /api/users/:id/connect
const connectUser = async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const currentUserId = req.user._id;

    if (targetUserId === currentUserId.toString()) {
      return res.status(400).json({ message: 'Cannot connect with yourself' });
    }

    const currentUser = await User.findById(currentUserId);
    const targetUser = await User.findById(targetUserId);

    if (!targetUser) return res.status(404).json({ message: 'User not found' });

    const currentStatus = await getConnectionStatusBetween(currentUserId, targetUserId);
    const { sendRealtimeNotification } = require('../services/socketService');

    if (currentStatus === 'NONE') {
      // Create connection request in PENDING state
      await Connection.create({
        senderId: currentUserId,
        receiverId: targetUserId,
        status: 'PENDING'
      });

      // Send real-time notification
      try {
        await sendRealtimeNotification(targetUserId, {
          actorId: currentUserId,
          type: 'CONNECTION_REQUEST',
          title: '🤝 Campus Connection Request',
          body: `${currentUser.name} sent you a connection request on UNIRISE!`,
          message: `${currentUser.name} sent you a connection request on UNIRISE!`,
          entityType: 'user',
          entityId: currentUserId.toString(),
          referenceId: currentUserId.toString(),
          metadata: { userId: currentUserId.toString(), userName: currentUser.name }
        });
      } catch (e) {
        console.error('Connection request notification error:', e);
      }

      return res.json({ status: 'PENDING_SENT', connected: false, message: 'Connection request sent' });

    } else if (currentStatus === 'PENDING_SENT') {
      // Cancel sent pending request
      await Connection.deleteOne({ senderId: currentUserId, receiverId: targetUserId, status: 'PENDING' });
      return res.json({ status: 'NONE', connected: false, message: 'Connection request cancelled' });

    } else if (currentStatus === 'PENDING_RECEIVED') {
      // Accept pending request
      await Connection.findOneAndUpdate(
        { senderId: targetUserId, receiverId: currentUserId, status: 'PENDING' },
        { status: 'ACCEPTED' }
      );

      if (!currentUser.connections.includes(targetUserId)) currentUser.connections.push(targetUserId);
      if (!targetUser.connections.includes(currentUserId)) targetUser.connections.push(currentUserId);
      await currentUser.save();
      await targetUser.save();

      // Send notification to original sender
      try {
        await sendRealtimeNotification(targetUserId, {
          actorId: currentUserId,
          type: 'CONNECTION_ACCEPTED',
          title: '🤝 Connection Accepted',
          body: `${currentUser.name} accepted your campus connection request!`,
          message: `${currentUser.name} accepted your campus connection request!`,
          entityType: 'user',
          entityId: currentUserId.toString(),
          referenceId: currentUserId.toString(),
          metadata: { userId: currentUserId.toString(), userName: currentUser.name }
        });
      } catch (e) {
        console.error('Connection accepted notification error:', e);
      }

      return res.json({ status: 'ACCEPTED', connected: true, message: 'Connection request accepted' });

    } else if (currentStatus === 'ACCEPTED') {
      // Disconnect
      await Connection.deleteMany({
        $or: [
          { senderId: currentUserId, receiverId: targetUserId },
          { senderId: targetUserId, receiverId: currentUserId }
        ]
      });

      currentUser.connections.pull(targetUserId);
      targetUser.connections.pull(currentUserId);
      await currentUser.save();
      await targetUser.save();

      return res.json({ status: 'NONE', connected: false, message: 'Disconnected successfully' });
    }
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getConnectionStatusBetween,
  getUsers,
  getUserById,
  updateUser,
  addAchievement,
  deleteAchievement,
  getUserPosts,
  connectUser
};
