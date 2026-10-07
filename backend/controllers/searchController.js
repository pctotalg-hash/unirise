const User = require('../models/User');
const Club = require('../models/Club');
const Post = require('../models/Post');
const Event = require('../models/Event');
const Group = require('../models/Group');
const { generateAISuggestions } = require('../services/aiSearchService');

// GET /api/search?q=&category=
const globalSearch = async (req, res, next) => {
  try {
    const query = req.query.q || '';
    const category = req.query.category || req.query.filter || 'ALL';

    const defaultEmptyResults = {
      users: [],
      clubs: [],
      posts: [],
      events: [],
      hackathons: [],
      internships: [],
      groups: [],
      opportunities: []
    };

    if (!query.trim()) {
      return res.json({
        success: true,
        query: '',
        category,
        results: defaultEmptyResults
      });
    }

    const regex = new RegExp(query.trim(), 'i');
    const upperCategory = category.toUpperCase();

    let users = [];
    let clubs = [];
    let posts = [];
    let events = [];
    let hackathons = [];
    let internships = [];
    let groups = [];
    let opportunities = [];

    // 1. Search Users / People
    if (upperCategory === 'ALL' || upperCategory === 'PEOPLE') {
      users = await User.find({
        $or: [
          { name: regex },
          { department: regex },
          { verifiedBadge: regex },
          { skills: { $in: [regex] } },
          { interests: { $in: [regex] } }
        ]
      }).select('-passwordHash').limit(10);
    }

    // 2. Search Clubs
    if (upperCategory === 'ALL' || upperCategory === 'CLUBS') {
      clubs = await Club.find({
        $or: [{ name: regex }, { tagline: regex }, { category: regex }, { description: regex }]
      }).populate('coordinatorId', 'name profilePhoto').limit(10);
    }

    // 3. Search Posts & Specific Post Categories
    if (
      upperCategory === 'ALL' ||
      upperCategory === 'POSTS' ||
      upperCategory === 'HACKATHONS' ||
      upperCategory === 'INTERNSHIPS' ||
      upperCategory === 'OPPORTUNITIES'
    ) {
      let postQuery = {
        $or: [{ content: regex }, { title: regex }, { hashtags: { $in: [regex] } }, { category: regex }]
      };

      if (upperCategory === 'HACKATHONS') postQuery.category = 'Hackathons';
      if (upperCategory === 'INTERNSHIPS') postQuery.category = 'Internships';
      if (upperCategory === 'OPPORTUNITIES') postQuery.category = 'Opportunities';

      const foundPosts = await Post.find(postQuery)
        .populate('authorId', 'name profilePhoto role isVerified verifiedBadge department year')
        .populate('clubId', 'name logo coverImage isVerified')
        .sort({ createdAt: -1 })
        .limit(15);

      foundPosts.forEach(p => {
        const pObj = p.toObject();
        pObj.shortCaption = (pObj.content && pObj.content.length > 120) ? pObj.content.substring(0, 120) + '...' : pObj.content;
        pObj.mainImage = (pObj.media && pObj.media.length > 0) ? pObj.media[0] : null;

        if (pObj.category === 'Hackathons') hackathons.push(pObj);
        else if (pObj.category === 'Internships') internships.push(pObj);
        else if (pObj.category === 'Opportunities') opportunities.push(pObj);
        else posts.push(pObj);
      });
    }

    // 4. Search Events
    if (upperCategory === 'ALL' || upperCategory === 'EVENTS') {
      events = await Event.find({
        $or: [{ title: regex }, { description: regex }, { location: regex }]
      }).populate('clubId', 'name logo').limit(10);
    }

    // 5. Search Groups (respect private group authorization)
    if (upperCategory === 'ALL' || upperCategory === 'GROUPS') {
      const currentUserId = req.user?._id;
      const isAdmin = (req.user?.role || '').toLowerCase() === 'admin';

      let groupQuery = {
        $or: [{ name: regex }, { description: regex }]
      };

      if (!isAdmin && currentUserId) {
        groupQuery.$and = [
          { $or: [{ name: regex }, { description: regex }] },
          {
            $or: [
              { isPrivate: { $ne: true } },
              { members: currentUserId },
              { adminId: currentUserId }
            ]
          }
        ];
        delete groupQuery.$or;
      }

      groups = await Group.find(groupQuery).limit(10);
    }

    res.json({
      success: true,
      query: query.trim(),
      category: upperCategory,
      results: {
        users: users || [],
        clubs: clubs || [],
        posts: posts || [],
        events: events || [],
        hackathons: hackathons || [],
        internships: internships || [],
        groups: groups || [],
        opportunities: opportunities || []
      }
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Search failed: ' + err.message,
      query: req.query.q || '',
      category: req.query.category || 'ALL',
      results: {
        users: [],
        clubs: [],
        posts: [],
        events: [],
        hackathons: [],
        internships: [],
        groups: [],
        opportunities: []
      }
    });
  }
};

// GET /api/search/ai?q=
const aiSearch = async (req, res, next) => {
  try {
    const query = req.query.q || req.body?.query || '';
    const aiData = await generateAISuggestions(query);
    res.json({
      success: true,
      ...aiData
    });
  } catch (err) {
    res.json({
      success: false,
      query: req.query.q || '',
      intent: 'Campus Recommendations',
      suggestions: []
    });
  }
};

module.exports = {
  globalSearch,
  aiSearch
};
