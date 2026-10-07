const Group = require('../models/Group');

const getGroups = async (req, res, next) => {
  try {
    const groups = await Group.find()
      .populate('adminId', 'name profilePhoto')
      .populate('members', 'name profilePhoto role');
    res.json(groups);
  } catch (err) {
    next(err);
  }
};

const createGroup = async (req, res, next) => {
  try {
    const { name, description, image } = req.body;
    if (!name) return res.status(400).json({ message: 'Group name is required' });

    const group = await Group.create({
      name,
      description,
      image,
      adminId: req.user._id,
      members: [req.user._id]
    });

    res.status(201).json(group);
  } catch (err) {
    next(err);
  }
};

const getGroupById = async (req, res, next) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('adminId', 'name profilePhoto role')
      .populate('members', 'name profilePhoto role isVerified verifiedBadge');
    if (!group) return res.status(404).json({ message: 'Group not found' });
    res.json(group);
  } catch (err) {
    next(err);
  }
};

const addGroupMember = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });

    if (!group.members.includes(userId)) {
      group.members.push(userId);
      await group.save();
    }
    res.json(group);
  } catch (err) {
    next(err);
  }
};

const removeGroupMember = async (req, res, next) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });

    if (group.adminId.toString() !== req.user._id.toString() && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Only group admin can remove members' });
    }

    group.members.pull(req.params.userId);
    await group.save();
    res.json(group);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getGroups,
  createGroup,
  getGroupById,
  addGroupMember,
  removeGroupMember
};
