const Message = require('../models/Message');
const Group = require('../models/Group');
const { getConnectionStatusBetween } = require('./userController');
const { sendRealtimeNotification } = require('../services/socketService');

// GET /api/messages/public
const getPublicMessages = async (req, res, next) => {
  try {
    const messages = await Message.find({ isPublicCampusChat: true })
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      })
      .sort({ createdAt: 1 })
      .limit(100);
    res.json(messages);
  } catch (err) {
    next(err);
  }
};

// GET /api/messages/private/:userId
const getPrivateMessages = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user._id.toString();

    // Verify connection status: Must be connected or same user
    if (currentUserId !== userId) {
      const connStatus = await getConnectionStatusBetween(currentUserId, userId);
      if (connStatus !== 'ACCEPTED') {
        return res.status(403).json({ message: '403 Forbidden: You must have an accepted connection with this user to view private messages.' });
      }
    }

    const messages = await Message.find({
      $or: [
        { senderId: req.user._id, receiverId: userId },
        { senderId: userId, receiverId: req.user._id }
      ]
    })
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      })
      .sort({ createdAt: 1 })
      .limit(100);

    res.json(messages);
  } catch (err) {
    next(err);
  }
};

// GET /api/messages/group/:groupId
const getGroupMessages = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Privacy & Access Control: Auto-join user to open group if not yet member
    const isMember = group.members.some(m => m.toString() === req.user._id.toString());
    const isAdmin = req.user.role === 'admin' || req.user.role === 'ADMIN';

    if (!isMember && !isAdmin) {
      group.members.push(req.user._id);
      await group.save();
    }

    const messages = await Message.find({ groupId })
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      })
      .sort({ createdAt: 1 })
      .limit(100);

    res.json(messages);
  } catch (err) {
    next(err);
  }
};

// GET /api/messages/:targetId (Backwards compatibility)
const getMessages = async (req, res, next) => {
  try {
    const { targetId } = req.params;
    const { type } = req.query; // 'public', 'group', or 'private'

    if (targetId === 'public' || type === 'public') {
      return getPublicMessages(req, res, next);
    }

    if (type === 'group') {
      req.params.groupId = targetId;
      return getGroupMessages(req, res, next);
    }

    req.params.userId = targetId;
    return getPrivateMessages(req, res, next);
  } catch (err) {
    next(err);
  }
};

// POST /api/messages
const sendMessage = async (req, res, next) => {
  try {
    const { receiverId, groupId, isPublicCampusChat, content, replyTo } = req.body;

    if (!content) return res.status(400).json({ message: 'Message content is required' });

    // Group membership check for outgoing group messages
    if (groupId) {
      const group = await Group.findById(groupId);
      if (!group) {
        return res.status(404).json({ message: 'Group not found' });
      }
      const isMember = group.members.some(m => m.toString() === req.user._id.toString());
      const isAdmin = req.user.role === 'admin' || req.user.role === 'ADMIN';
      if (!isMember && !isAdmin) {
        group.members.push(req.user._id);
        await group.save();
      }
    }

    // 1-on-1 Private messaging connection check
    if (receiverId && !groupId && !isPublicCampusChat) {
      const connStatus = await getConnectionStatusBetween(req.user._id, receiverId);
      if (connStatus !== 'ACCEPTED') {
        return res.status(403).json({
          message: '403 Forbidden: You must have an accepted connection with this user before sending private messages.'
        });
      }
    }

    const message = await Message.create({
      senderId: req.user._id,
      receiverId: receiverId || null,
      groupId: groupId || null,
      isPublicCampusChat: !!isPublicCampusChat,
      content,
      replyTo: replyTo || null
    });

    const populated = await Message.findById(message._id)
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      });

    // Dispatch real-time chat notifications
    if (receiverId) {
      await sendRealtimeNotification(receiverId, {
        actorId: req.user._id,
        type: 'PERSONAL_CHAT',
        title: `💬 Message from ${req.user.name}`,
        body: content.length > 50 ? content.substring(0, 50) + '...' : content,
        message: content.length > 50 ? content.substring(0, 50) + '...' : content,
        entityType: 'chat',
        entityId: req.user._id.toString(),
        referenceId: message._id.toString(),
        metadata: { senderId: req.user._id.toString(), senderName: req.user.name, messageId: message._id.toString() }
      });
    } else if (groupId) {
      try {
        const group = await Group.findById(groupId);
        if (group && group.members) {
          for (const memberId of group.members) {
            if (memberId.toString() !== req.user._id.toString()) {
              await sendRealtimeNotification(memberId, {
                actorId: req.user._id,
                type: 'GROUP_CHAT',
                title: `👥 ${group.name}`,
                body: `${req.user.name}: ${content.length > 40 ? content.substring(0, 40) + '...' : content}`,
                message: `${req.user.name}: ${content.length > 40 ? content.substring(0, 40) + '...' : content}`,
                entityType: 'group',
                entityId: groupId.toString(),
                referenceId: message._id.toString(),
                metadata: { groupId: groupId.toString(), messageId: message._id.toString() }
              });
            }
          }
        }
      } catch (e) {
        console.error('Group notification dispatch error:', e);
      }
    }

    res.status(201).json(populated);
  } catch (err) {
    next(err);
  }
};

// PUT /api/messages/:id (or PATCH /api/messages/:id)
const updateMessage = async (req, res, next) => {
  try {
    const { content } = req.body;
    const message = await Message.findById(req.params.id);
    if (!message) return res.status(404).json({ message: 'Message not found' });

    // Authorization Security: Only sender can edit own message
    if (message.senderId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to edit this message' });
    }

    message.content = content;
    message.isEdited = true;
    message.updatedAt = Date.now();
    await message.save();

    const populated = await Message.findById(message._id)
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      });

    res.json(populated);
  } catch (err) {
    next(err);
  }
};

// DELETE /api/messages/:id
const deleteMessage = async (req, res, next) => {
  try {
    const message = await Message.findById(req.params.id);
    if (!message) return res.status(404).json({ message: 'Message not found' });

    // Authorization Security: Only sender or admin can delete own message
    if (message.senderId.toString() !== req.user._id.toString() && req.user.role !== 'ADMIN' && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to delete this message' });
    }

    message.isDeleted = true;
    message.content = 'This message was deleted.';
    message.updatedAt = Date.now();
    await message.save();

    const populated = await Message.findById(message._id)
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      });

    res.json(populated);
  } catch (err) {
    next(err);
  }
};

// POST /api/messages/:id/react
const reactToMessage = async (req, res, next) => {
  try {
    const { emoji } = req.body;
    const message = await Message.findById(req.params.id);
    if (!message) return res.status(404).json({ message: 'Message not found' });

    message.reactions = message.reactions || [];
    message.reactions = message.reactions.filter(r => r.userId.toString() !== req.user._id.toString());
    if (emoji) {
      message.reactions.push({ userId: req.user._id, emoji });
    }
    await message.save();

    const populated = await Message.findById(message._id)
      .populate('senderId', 'name profilePhoto role isVerified verifiedBadge')
      .populate({
        path: 'replyTo',
        populate: { path: 'senderId', select: 'name' }
      });

    res.json(populated);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMessages,
  getPublicMessages,
  getPrivateMessages,
  getGroupMessages,
  sendMessage,
  updateMessage,
  deleteMessage,
  reactToMessage
};
