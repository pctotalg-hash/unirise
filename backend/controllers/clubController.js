const Club = require('../models/Club');
const Post = require('../models/Post');
const Event = require('../models/Event');
const ClubPosition = require('../models/ClubPosition');
const User = require('../models/User');

// GET /api/clubs?isVerified=true
const getClubs = async (req, res, next) => {
  try {
    const { isVerified, category } = req.query;
    let query = {};

    if (isVerified === 'true' || isVerified === true) {
      query.isVerified = true;
    }

    if (category && category !== 'All') {
      query.category = category;
    }

    const clubs = await Club.find(query)
      .populate('coordinatorId', 'name email profilePhoto role isVerified verifiedBadge department year bio')
      .populate('members', 'name profilePhoto department year role isVerified verifiedBadge bio')
      .sort({ name: 1 });

    res.json(clubs);
  } catch (err) {
    next(err);
  }
};

// POST /api/clubs
const createClub = async (req, res, next) => {
  try {
    const { name, tagline, description, category, logo, coverImage, coordinatorId } = req.body;

    if (!name) return res.status(400).json({ message: 'Club name is required' });

    const club = await Club.create({
      name,
      tagline,
      description,
      category: category || 'Technology',
      logo,
      coverImage,
      coordinatorId: coordinatorId || req.user._id,
      isVerified: true
    });

    res.status(201).json(club);
  } catch (err) {
    next(err);
  }
};

// GET /api/clubs/:id
const getClubById = async (req, res, next) => {
  try {
    const club = await Club.findById(req.params.id)
      .populate('coordinatorId', 'name email profilePhoto role isVerified verifiedBadge department year bio')
      .populate('members', 'name profilePhoto role isVerified verifiedBadge department year bio');

    if (!club) return res.status(404).json({ message: 'Club not found' });
    res.json(club);
  } catch (err) {
    next(err);
  }
};

// PUT /api/clubs/:id
const updateClub = async (req, res, next) => {
  try {
    const club = await Club.findById(req.params.id);
    if (!club) return res.status(404).json({ message: 'Club not found' });

    // Access control: only assigned coordinator or Admin / College
    const isCoordinator = club.coordinatorId && club.coordinatorId.toString() === req.user._id.toString();
    const isCollegeAdmin = req.user.role === 'admin' || req.user.role === 'ADMIN';
    if (!isCoordinator && !isCollegeAdmin) {
      return res.status(403).json({ message: 'Not authorized to edit this club profile' });
    }

    const { tagline, description, logo, coverImage, socialLinks, isVerified } = req.body;
    if (tagline !== undefined) club.tagline = tagline;
    if (description !== undefined) club.description = description;
    if (logo) club.logo = logo;
    if (coverImage) club.coverImage = coverImage;
    if (socialLinks) club.socialLinks = socialLinks;
    if (isVerified !== undefined && isCollegeAdmin) club.isVerified = isVerified;
    club.updatedAt = Date.now();

    await club.save();
    res.json(club);
  } catch (err) {
    next(err);
  }
};

// GET /api/clubs/:id/posts
const getClubPosts = async (req, res, next) => {
  try {
    const posts = await Post.find({ clubId: req.params.id })
      .populate('authorId', 'name profilePhoto role isVerified verifiedBadge')
      .populate('clubId', 'name logo coverImage isVerified')
      .populate('comments.userId', 'name profilePhoto')
      .sort({ createdAt: -1 });

    const formattedPosts = posts.map(p => {
      const obj = p.toObject();
      obj.shortCaption = (obj.content && obj.content.length > 120) ? obj.content.substring(0, 120) + '...' : obj.content;
      obj.mainImage = (obj.media && obj.media.length > 0) ? obj.media[0] : null;
      obj.likeCount = obj.likes ? obj.likes.length : 0;
      obj.commentCount = obj.comments ? obj.comments.length : 0;
      return obj;
    });

    res.json(formattedPosts);
  } catch (err) {
    next(err);
  }
};

// GET /api/clubs/:id/events
const getClubEvents = async (req, res, next) => {
  try {
    const events = await Event.find({ clubId: req.params.id }).sort({ date: 1 });
    res.json(events);
  } catch (err) {
    next(err);
  }
};

// GET /api/clubs/:id/core-team
const getClubCoreTeam = async (req, res, next) => {
  try {
    let positions = await ClubPosition.find({ clubId: req.params.id, status: 'ACTIVE' })
      .populate('userId', 'name profilePhoto email department year role isVerified verifiedBadge bio')
      .sort({ assignedAt: -1 });

    if (!positions || positions.length === 0) {
      const club = await Club.findById(req.params.id)
        .populate('coordinatorId', 'name profilePhoto email department year role isVerified verifiedBadge bio');

      if (club && club.coordinatorId) {
        positions = [{
          _id: `default-coord-${club._id}`,
          clubId: club._id,
          userId: club.coordinatorId,
          positionName: 'President',
          status: 'ACTIVE'
        }];
      }
    }

    res.json(positions);
  } catch (err) {
    next(err);
  }
};

// GET /api/clubs/:id/members
const getClubMembers = async (req, res, next) => {
  try {
    const club = await Club.findById(req.params.id)
      .populate('members', 'name profilePhoto email department year role isVerified verifiedBadge bio');

    if (!club) return res.status(404).json({ message: 'Club not found' });
    
    res.json(club.members || []);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getClubs,
  createClub,
  getClubById,
  updateClub,
  getClubPosts,
  getClubEvents,
  getClubCoreTeam,
  getClubMembers
};
