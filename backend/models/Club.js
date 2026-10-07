const mongoose = require('mongoose');

const ClubSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  logo: { type: String, default: 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=500' },
  coverImage: { type: String, default: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200' },
  tagline: { type: String, default: 'Official Campus Community Club' },
  description: { type: String, default: 'Building and innovating together.' },
  category: { type: String, default: 'Technology' },
  isVerified: { type: Boolean, default: true },
  college: { type: String, default: 'State Institute of Technology' },
  coordinatorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  socialLinks: {
    github: String,
    linkedin: String,
    instagram: String,
    website: String
  },
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Club', ClubSchema);
