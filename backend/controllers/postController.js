const Post = require('../models/Post');
const Club = require('../models/Club');
const Notification = require('../models/Notification');
const { sendRealtimeNotification } = require('../services/socketService');
const { checkSearchAlertsForEntity } = require('../services/aiSearchAlertService');

// Helper to construct short caption preview
function getShortCaption(content, title) {
  const text = content || title || '';
  if (text.length > 130) {
    return text.substring(0, 130).trim() + '...';
  }
  return text;
}

// GET /api/posts?category=&search=
const getPosts = async (req, res, next) => {
  try {
    const { category, search } = req.query;
    let query = {};

    if (category && category !== 'All' && category !== 'Mixed Feed') {
      query.category = category;
    }

    if (search) {
      query.$or = [
        { content: { $regex: search, $options: 'i' } },
        { title: { $regex: search, $options: 'i' } },
        { hashtags: { $in: [new RegExp(search, 'i')] } }
      ];
    }

    const posts = await Post.find(query)
      .populate('authorId', 'name profilePhoto role isVerified verifiedBadge college department year')
      .populate('clubId', 'name logo coverImage isVerified tagline')
      .populate('comments.userId', 'name profilePhoto')
      .sort({ createdAt: -1 });

    // Format preview response
    const formattedPosts = posts.map(p => {
      const obj = p.toObject();
      obj.shortCaption = getShortCaption(obj.content, obj.title);
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

// POST /api/posts
const createPost = async (req, res, next) => {
  try {
    const { 
      content, title, category, hashtags, media, 
      externalUrl, applyUrl, eventDate, location, clubId,
      eventDetails, hackathonDetails, internshipDetails 
    } = req.body;

    if (!content) {
      return res.status(400).json({ message: 'Post content is required' });
    }

    let postCategory = category || 'Student Posts';
    const categoryMap = {
      'events': 'Events',
      'hackathons': 'Hackathons',
      'internships': 'Internships',
      'clubs': 'Clubs',
      'student posts': 'Student Posts',
      'announcements': 'Announcements',
      'opportunities': 'Opportunities'
    };
    if (categoryMap[postCategory.toString().toLowerCase()]) {
      postCategory = categoryMap[postCategory.toString().toLowerCase()];
    }

    const post = await Post.create({
      authorId: req.user._id,
      clubId: clubId || null,
      title,
      content,
      category: postCategory,
      hashtags: hashtags || [],
      media: media || [],
      externalUrl,
      applyUrl,
      eventDate,
      location,
      eventDetails,
      hackathonDetails,
      internshipDetails
    });

    const populatedPost = await Post.findById(post._id)
      .populate('authorId', 'name profilePhoto role isVerified verifiedBadge')
      .populate('clubId', 'name logo');

    // 1. Dispatch Club Notifications if associated with a club
    if (clubId) {
      try {
        const club = await Club.findById(clubId).populate('members', '_id');
        if (club && club.members) {
          const titleStr = title || `${category || 'New Content'} Update`;
          for (const member of club.members) {
            const memberIdStr = member._id.toString();
            if (memberIdStr !== req.user._id.toString()) {
              await sendRealtimeNotification(member._id, {
                actorId: req.user._id,
                type: 'CLUB_POST',
                title: `📢 ${club.name}`,
                body: `New update posted in ${club.name}: "${titleStr}"`,
                message: `New update posted in ${club.name}: "${titleStr}"`,
                entityType: 'post',
                entityId: post._id.toString(),
                referenceId: post._id.toString(),
                metadata: { clubId: club._id.toString(), postId: post._id.toString() }
              });
            }
          }
        }
      } catch (e) {
        console.error('Club notification dispatch error:', e);
      }
    }

    // 2. Event-driven AI Search Alert matching check
    checkSearchAlertsForEntity('post', populatedPost).catch(err => {
      console.error('AI Search Alert check error:', err);
    });

    res.status(201).json(populatedPost);
  } catch (err) {
    next(err);
  }
};

// GET /api/posts/:id
const getPostById = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('authorId', 'name profilePhoto role isVerified verifiedBadge college department year bio')
      .populate('clubId', 'name logo coverImage isVerified tagline coordinatorId description')
      .populate('comments.userId', 'name profilePhoto role isVerified');

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const obj = post.toObject();
    obj.shortCaption = getShortCaption(obj.content, obj.title);
    obj.mainImage = (obj.media && obj.media.length > 0) ? obj.media[0] : null;
    obj.likeCount = obj.likes ? obj.likes.length : 0;
    obj.commentCount = obj.comments ? obj.comments.length : 0;

    res.json(obj);
  } catch (err) {
    next(err);
  }
};

// PUT /api/posts/:id
const updatePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    if (post.authorId.toString() !== req.user._id.toString() && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Not authorized to update this post' });
    }

    const { content, title, category, hashtags, externalUrl, applyUrl } = req.body;
    if (content) post.content = content;
    if (title) post.title = title;
    if (category) post.category = category;
    if (hashtags) post.hashtags = hashtags;
    if (externalUrl) post.externalUrl = externalUrl;
    if (applyUrl) post.applyUrl = applyUrl;
    post.updatedAt = Date.now();

    await post.save();
    res.json(post);
  } catch (err) {
    next(err);
  }
};

// DELETE /api/posts/:id
const deletePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    if (post.authorId.toString() !== req.user._id.toString() && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Not authorized to delete this post' });
    }

    await post.deleteOne();
    res.json({ message: 'Post deleted successfully' });
  } catch (err) {
    next(err);
  }
};

// POST /api/posts/:id/like
const likePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    const isLiked = post.likes.includes(req.user._id);
    if (isLiked) {
      post.likes.pull(req.user._id);
    } else {
      post.likes.push(req.user._id);

      if (post.authorId.toString() !== req.user._id.toString()) {
        await Notification.create({
          recipientId: post.authorId,
          actorId: req.user._id,
          senderId: req.user._id,
          type: 'LIKE',
          title: 'New Like',
          body: `${req.user.name} liked your post.`,
          message: `${req.user.name} liked your post.`,
          entityType: 'post',
          entityId: post._id.toString(),
          referenceId: post._id.toString()
        });
      }
    }

    await post.save();
    res.json({ likesCount: post.likes.length, isLiked: !isLiked });
  } catch (err) {
    next(err);
  }
};

// POST /api/posts/:id/comment
const commentPost = async (req, res, next) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ message: 'Comment text is required' });

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    post.comments.push({
      userId: req.user._id,
      text
    });

    await post.save();

    if (post.authorId.toString() !== req.user._id.toString()) {
      await Notification.create({
        recipientId: post.authorId,
        actorId: req.user._id,
        senderId: req.user._id,
        type: 'COMMENT',
        title: 'New Comment',
        body: `${req.user.name} commented on your post: "${text.substring(0, 30)}..."`,
        message: `${req.user.name} commented on your post: "${text.substring(0, 30)}..."`,
        entityType: 'post',
        entityId: post._id.toString(),
        referenceId: post._id.toString()
      });
    }

    const updatedPost = await Post.findById(post._id)
      .populate('comments.userId', 'name profilePhoto role isVerified');

    res.status(201).json(updatedPost.comments);
  } catch (err) {
    next(err);
  }
};

// POST /api/posts/:id/share
const sharePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    post.sharesCount += 1;
    await post.save();

    res.json({ sharesCount: post.sharesCount });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getPosts,
  createPost,
  getPostById,
  updatePost,
  deletePost,
  likePost,
  commentPost,
  sharePost
};
