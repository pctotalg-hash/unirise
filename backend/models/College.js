const mongoose = require('mongoose');

const CollegeSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  shortName: { type: String, required: true, trim: true },
  email: { type: String, required: true, lowercase: true, trim: true },
  domain: { type: String, trim: true, default: '' },
  location: { type: String, trim: true, default: '' },
  logo: { type: String, default: 'https://images.unsplash.com/photo-1562774053-701939374585?w=500' },
  coverImage: { type: String, default: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=1200' },
  adminName: { type: String, default: 'College Admin' },
  adminEmail: { type: String, default: '' },
  status: { 
    type: String, 
    enum: ['pending', 'approved', 'rejected', 'suspended'], 
    default: 'pending' 
  },
  isVerified: { type: Boolean, default: false },
  rejectionReason: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('College', CollegeSchema);
