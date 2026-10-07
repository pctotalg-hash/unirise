const User = require('../models/User');
const Club = require('../models/Club');
const Post = require('../models/Post');
const Event = require('../models/Event');
const Group = require('../models/Group');
const Report = require('../models/Report');
const ClubPosition = require('../models/ClubPosition');
const Notification = require('../models/Notification');

// GET /api/admin/dashboard
const getDashboardStats = async (req, res, next) => {
  try {
    const filter = {};
    if (req.user.role === 'college_admin' && req.user.collegeId) {
      filter.collegeId = req.user.collegeId;
    }

    const totalStudents = await User.countDocuments({ ...filter, role: { $regex: /^student$/i } });
    const totalCoordinators = await User.countDocuments({ ...filter, role: { $regex: /^club_coordinator$/i } });
    const totalClubs = await Club.countDocuments();
    const totalPosts = await Post.countDocuments();
    const totalEvents = await Event.countDocuments();
    const totalGroups = await Group.countDocuments();
    const pendingReports = await Report.countDocuments({ status: 'PENDING' });

    res.json({
      totalStudents,
      totalCoordinators,
      totalClubs,
      totalPosts,
      totalEvents,
      totalGroups,
      pendingReports
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/admin/users
const getAdminUsers = async (req, res, next) => {
  try {
    const filter = {};
    if (req.user.role === 'college_admin' && req.user.collegeId) {
      filter.collegeId = req.user.collegeId;
    }
    const users = await User.find(filter).select('-passwordHash').sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    next(err);
  }
};

// GET /api/admin/clubs
const getAdminClubs = async (req, res, next) => {
  try {
    const clubs = await Club.find().populate('coordinatorId', 'name email').sort({ createdAt: -1 });
    res.json(clubs);
  } catch (err) {
    next(err);
  }
};

// POST /api/admin/verify-user
const verifyUser = async (req, res, next) => {
  try {
    const { userId, isVerified, verifiedBadge } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.isVerified = isVerified !== undefined ? isVerified : true;
    if (verifiedBadge !== undefined) user.verifiedBadge = verifiedBadge;
    await user.save();

    await Notification.create({
      recipientId: user._id,
      senderId: req.user._id,
      type: 'VERIFICATION_UPDATE',
      title: 'Profile Verification Updated',
      message: `Your account verification status was updated by College Administration.`
    });

    res.json(user);
  } catch (err) {
    next(err);
  }
};

// POST /api/admin/verify-club
const verifyClub = async (req, res, next) => {
  try {
    const { clubId, isVerified } = req.body;
    const club = await Club.findById(clubId);
    if (!club) return res.status(404).json({ message: 'Club not found' });

    club.isVerified = isVerified !== undefined ? isVerified : true;
    await club.save();

    res.json(club);
  } catch (err) {
    next(err);
  }
};

// DELETE /api/admin/posts/:id
const deletePostAdmin = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    await post.deleteOne();
    res.json({ message: 'Post removed by Administrator' });
  } catch (err) {
    next(err);
  }
};

// GET /api/admin/reports
const getReports = async (req, res, next) => {
  try {
    const reports = await Report.find().populate('reportedBy', 'name email').sort({ createdAt: -1 });
    res.json(reports);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getDashboardStats,
  getAdminUsers,
  getAdminClubs,
  verifyUser,
  verifyClub,
  deletePostAdmin,
  getReports
};
