const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true },
  profilePhoto: { type: String, default: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500' },
  coverPhoto: { type: String, default: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200' },
  collegeId: { type: mongoose.Schema.Types.ObjectId, ref: 'College', default: null },
  college: { type: String, default: 'State Institute of Technology' },
  department: { type: String, default: 'Computer Engineering' },
  year: { type: String, default: '3rd Year' },
  bio: { type: String, default: 'Passionate developer & tech enthusiast.' },
  skills: [{ type: String }],
  achievements: [{ type: String }],
  structuredAchievements: [{
    title: { type: String, required: true },
    description: { type: String },
    date: { type: String },
    organization: { type: String },
    certificateUrl: { type: String }
  }],
  interests: [{ type: String }],
  socialLinks: {
    github: { type: String, default: '' },
    linkedin: { type: String, default: '' },
    instagram: { type: String, default: '' },
    website: { type: String, default: '' }
  },
  role: { 
    type: String, 
    enum: ['admin', 'college_admin', 'platform_admin', 'student', 'club_coordinator'], 
    default: 'student',
    lowercase: true,
    trim: true
  },
  isVerified: { type: Boolean, default: false },
  verifiedBadge: { type: String, default: null }, // e.g. "CODING CLUB PRESIDENT"
  verifiedClubId: { type: mongoose.Schema.Types.ObjectId, ref: 'Club', default: null },
  connections: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
