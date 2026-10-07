const User = require('../models/User');
const Club = require('../models/Club');
const Post = require('../models/Post');
const Event = require('../models/Event');
const Group = require('../models/Group');

const generateAISuggestions = async (query) => {
  if (!query || query.trim() === '') {
    return {
      intent: 'Campus Discovery',
      suggestions: [
        { type: 'hackathon', title: 'Upcoming: Campus Hackathon 2026', subtitle: '48-hour coding marathon with $5,000 prizes' },
        { type: 'club', title: 'Featured: Coding Club ✓', subtitle: 'Build • Code • Innovate' },
        { type: 'internship', title: 'Trending: Product Design Internship', subtitle: 'Summer 2026 • Stipend $1,200/mo' },
        { type: 'event', title: 'Workshop: Hands-on AI & Deep Learning', subtitle: 'Friday 5 PM at Auditorium B' }
      ]
    };
  }

  const q = query.toLowerCase().trim();
  const regex = new RegExp(q, 'i');
  const suggestions = [];

  // 1. Check for profile match intent
  const matchedUsers = await User.find({
    $or: [{ name: regex }, { department: regex }, { skills: { $in: [regex] } }, { interests: { $in: [regex] } }]
  }).select('name profilePhoto department year verifiedBadge').limit(3);

  // 2. Check for club match intent
  const matchedClubs = await Club.find({
    $or: [{ name: regex }, { tagline: regex }, { category: regex }]
  }).select('name logo tagline category').limit(3);

  // 3. Check for related posts/hackathons/internships
  const matchedPosts = await Post.find({
    $or: [{ title: regex }, { content: regex }, { hashtags: { $in: [regex] } }]
  }).select('title category content applyUrl media').limit(3);

  // Synthesize AI Intent & Suggestions based strictly on database findings
  let intentName = 'Campus Information Lookup';

  if (q.includes('hackathon') || q.includes('code') || q.includes('dev')) {
    intentName = 'Hackathon & Software Engineering Interest';
  } else if (q.includes('ai') || q.includes('machine') || q.includes('robot')) {
    intentName = 'Artificial Intelligence & Robotics Focus';
  } else if (q.includes('intern') || q.includes('job') || q.includes('career')) {
    intentName = 'Career & Internship Opportunity Search';
  } else if (q.includes('club') || q.includes('society')) {
    intentName = 'Campus Club Discovery';
  }

  // Populate dynamic suggestions
  matchedClubs.forEach(c => {
    suggestions.push({
      type: 'club',
      title: `Recommended Club: ${c.name} ✓`,
      subtitle: c.tagline || `${c.category} Society`,
      referenceId: c._id
    });
  });

  matchedPosts.forEach(p => {
    suggestions.push({
      type: p.category.toLowerCase(),
      title: `Related Opportunity: ${p.title || p.category}`,
      subtitle: p.content ? (p.content.length > 80 ? p.content.substring(0, 80) + '...' : p.content) : 'Campus post',
      referenceId: p._id
    });
  });

  matchedUsers.forEach(u => {
    suggestions.push({
      type: 'user',
      title: `Campus Student: ${u.name} ✓`,
      subtitle: `${u.department || 'Student'} • ${u.year || ''}`,
      referenceId: u._id
    });
  });

  // Fallback defaults if database yields under 3 results
  if (suggestions.length < 3) {
    suggestions.push({
      type: 'event',
      title: `Discover #${q.replace(/\s+/g, '')} Events`,
      subtitle: `Explore upcoming campus events tagged with ${query}`
    });
    suggestions.push({
      type: 'group',
      title: `Join ${query} Study Groups`,
      subtitle: `Connect with peers in Open Campus Communication`
    });
  }

  return {
    query,
    intent: intentName,
    suggestions: suggestions.slice(0, 6)
  };
};

module.exports = { generateAISuggestions };
