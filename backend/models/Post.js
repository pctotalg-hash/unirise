const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

const PostSchema = new mongoose.Schema({
  authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  clubId: { type: mongoose.Schema.Types.ObjectId, ref: 'Club', default: null },
  title: { type: String },
  content: { type: String, required: true },
  media: [{ type: String }],
  category: { 
    type: String, 
    enum: ['Events', 'Hackathons', 'Internships', 'Clubs', 'Student Posts', 'Announcements', 'Opportunities'],
    default: 'Student Posts'
  },
  hashtags: [{ type: String }],
  externalUrl: { type: String },
  applyUrl: { type: String },
  eventDate: { type: Date },
  location: { type: String },
  
  // Category-Specific Structured Details
  eventDetails: {
    title: { type: String },
    date: { type: String },
    time: { type: String },
    location: { type: String },
    organizer: { type: String },
    registrationUrl: { type: String },
    contactInfo: { type: String }
  },
  hackathonDetails: {
    name: { type: String },
    organizer: { type: String },
    date: { type: String },
    time: { type: String },
    location: { type: String },
    eligibility: { type: String },
    teamSize: { type: String },
    deadline: { type: String },
    registrationUrl: { type: String }
  },
  internshipDetails: {
    company: { type: String },
    role: { type: String },
    skills: [{ type: String }],
    eligibility: { type: String },
    location: { type: String },
    duration: { type: String },
    deadline: { type: String },
    applyUrl: { type: String }
  },

  likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  comments: [CommentSchema],
  sharesCount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Index for text search
PostSchema.index({ content: 'text', title: 'text', hashtags: 'text' });

module.exports = mongoose.model('Post', PostSchema);
