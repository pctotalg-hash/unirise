const College = require('../models/College');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

// @desc    Get public approved colleges for student directory & search
// @route   GET /api/colleges
// @access  Public (strictly filtered at backend layer)
const getPublicColleges = async (req, res, next) => {
  try {
    const { search } = req.query;

    // MANDATORY BACKEND FILTER: Only approved & verified colleges can be listed for students
    const filter = {
      status: 'approved',
      isVerified: true
    };

    if (search && search.trim()) {
      const regex = new RegExp(search.trim(), 'i');
      filter.$or = [
        { name: regex },
        { shortName: regex },
        { location: regex }
      ];
    }

    const colleges = await College.find(filter)
      .select('name shortName logo coverImage location domain isVerified status')
      .sort({ name: 1 });

    res.json(colleges);
  } catch (error) {
    next(error);
  }
};

// @desc    Submit college registration application (enters 'pending' state)
// @route   POST /api/colleges/register
// @access  Public
const registerCollege = async (req, res, next) => {
  try {
    const { name, shortName, email, domain, location, adminName, adminPassword } = req.body;

    if (!name || !shortName || !email || !adminPassword) {
      return res.status(400).json({ message: 'College name, short name, email, and admin password are required' });
    }

    const existingCollege = await College.findOne({
      $or: [{ email: email.toLowerCase() }, { name: new RegExp(`^${name}$`, 'i') }]
    });

    if (existingCollege) {
      return res.status(400).json({ message: 'A college application with this name or email already exists' });
    }

    // Create College in 'pending' status
    const college = await College.create({
      name,
      shortName,
      email: email.toLowerCase(),
      domain: domain || '',
      location: location || '',
      adminName: adminName || 'College Admin',
      adminEmail: email.toLowerCase(),
      status: 'pending',
      isVerified: false
    });

    // Create College Admin User account linked to college, pending verification
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(adminPassword, salt);

    await User.create({
      name: adminName || `${shortName} Admin`,
      email: email.toLowerCase(),
      passwordHash,
      role: 'college_admin',
      collegeId: college._id,
      college: college.name,
      department: 'College Administration',
      year: 'Faculty/Admin',
      isVerified: false
    });

    res.status(201).json({
      success: true,
      message: 'College registration submitted for verification. An admin will review your request.',
      college: {
        id: college._id,
        name: college.name,
        shortName: college.shortName,
        status: college.status,
        isVerified: college.isVerified
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all colleges for platform admin management
// @route   GET /api/colleges/admin/all
// @access  Private (Admin / Platform Admin only)
const getAllCollegesAdmin = async (req, res, next) => {
  try {
    const colleges = await College.find().sort({ createdAt: -1 });
    res.json(colleges);
  } catch (error) {
    next(error);
  }
};

// @desc    Approve, reject, or suspend a college
// @route   PUT /api/colleges/admin/:id/status
// @access  Private (Admin / Platform Admin only)
const updateCollegeStatusAdmin = async (req, res, next) => {
  try {
    const { status, rejectionReason } = req.body;
    const allowedStatuses = ['approved', 'rejected', 'suspended', 'pending'];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid college status value' });
    }

    const college = await College.findById(req.params.id);
    if (!college) {
      return res.status(404).json({ message: 'College not found' });
    }

    college.status = status;
    college.isVerified = (status === 'approved');
    if (rejectionReason !== undefined) college.rejectionReason = rejectionReason;
    college.updatedAt = Date.now();

    await college.save();

    // Update associated admin users
    await User.updateMany(
      { collegeId: college._id, role: { $in: ['admin', 'college_admin'] } },
      { isVerified: college.isVerified }
    );

    res.json({
      success: true,
      message: `College status updated to ${status}`,
      college
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getPublicColleges,
  registerCollege,
  getAllCollegesAdmin,
  updateCollegeStatusAdmin
};
