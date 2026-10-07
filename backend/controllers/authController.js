const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const College = require('../models/College');

const generateToken = (id, role) => {
  const normRole = (role || 'student').toLowerCase();
  return jwt.sign(
    { userId: id, id: id, role: normRole },
    process.env.JWT_SECRET || 'unirise_jwt_secret_dev_fallback',
    { expiresIn: '30d' }
  );
};

// @desc    Register a new student user (Immediate access, no pending status)
// @route   POST /api/auth/register
const registerUser = async (req, res, next) => {
  try {
    const { name, email, password, collegeId, college: collegeName, department, year } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Please provide name, email, and password' });
    }

    const userExists = await User.findOne({ email: email.toLowerCase() });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // Resolve College
    let targetCollege = null;
    if (collegeId) {
      targetCollege = await College.findById(collegeId);
    } else if (collegeName) {
      targetCollege = await College.findOne({ 
        $or: [{ name: collegeName }, { shortName: collegeName }],
        status: 'approved' 
      });
    }

    // Fallback to default approved college if necessary
    if (!targetCollege) {
      targetCollege = await College.findOne({ status: 'approved', isVerified: true });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // STUDENT SECURITY POLICY: Student registrations are strictly forced to 'student' role.
    const userRole = 'student';

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      passwordHash,
      collegeId: targetCollege ? targetCollege._id : null,
      college: targetCollege ? targetCollege.name : (collegeName || 'State Institute of Technology'),
      department: department || 'Computer Engineering',
      year: year || '1st Year',
      role: userRole,
      isVerified: false
    });

    const token = generateToken(user._id, user.role);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role.toLowerCase(),
        collegeId: user.collegeId,
        college: user.college,
        department: user.department,
        year: user.year,
        profilePhoto: user.profilePhoto,
        isVerified: user.isVerified,
        verifiedBadge: user.verifiedBadge,
        verifiedClubId: user.verifiedClubId
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate user & get token
// @route   POST /api/auth/login
const loginUser = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const userRole = (user.role || 'student').toLowerCase();

    // Check College Status if user is a college admin
    if (userRole === 'college_admin' || userRole === 'admin') {
      if (user.collegeId) {
        const college = await College.findById(user.collegeId);
        if (college && college.status !== 'approved') {
          return res.status(403).json({ 
            message: `College account is currently ${college.status}. Access granted only to approved colleges.` 
          });
        }
      }
    }

    const token = generateToken(user._id, userRole);

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        _id: user._id,
        name: user.name,
        email: user.email,
        role: userRole,
        collegeId: user.collegeId,
        college: user.college,
        department: user.department,
        year: user.year,
        profilePhoto: user.profilePhoto,
        coverPhoto: user.coverPhoto,
        bio: user.bio,
        skills: user.skills || [],
        achievements: user.achievements || [],
        interests: user.interests || [],
        isVerified: user.isVerified,
        verifiedBadge: user.verifiedBadge,
        verifiedClubId: user.verifiedClubId
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user profile
// @route   GET /api/auth/me
const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id)
      .select('-passwordHash')
      .populate('collegeId', 'name shortName logo isVerified status')
      .populate('connections', 'name profilePhoto role isVerified verifiedBadge')
      .populate('verifiedClubId', 'name logo coverImage isVerified');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userData = user.toObject();
    userData.role = (userData.role || 'student').toLowerCase();
    userData.id = userData._id;

    res.json(userData);
  } catch (error) {
    next(error);
  }
};

// @desc    Logout user (client clears token)
// @route   POST /api/auth/logout
const logoutUser = async (req, res) => {
  res.json({ success: true, message: 'Logged out successfully' });
};

module.exports = {
  registerUser,
  loginUser,
  getMe,
  logoutUser
};
