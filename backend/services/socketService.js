const Message = require('../models/Message');

let globalIo = null;
const activeUsers = new Map(); // userId -> socketId

const initSocketIO = (io) => {
  globalIo = io;

  io.on('connection', (socket) => {
    console.log(`[Socket.IO] New client connected: ${socket.id}`);

    // Register user socket & join private notification room
    socket.on('registerUser', (userId) => {
      if (userId) {
        activeUsers.set(userId.toString(), socket.id);
        socket.userId = userId.toString();
        socket.join(`user:${userId}:notifications`);
        console.log(`[Socket.IO] User ${userId} registered with socket ${socket.id} & joined room user:${userId}:notifications`);
        io.emit('onlineStatus', { userId, status: 'online' });
      }
    });

    // Join chat room (public campus, group, or private chat room ID)
    socket.on('joinRoom', (roomId) => {
      socket.join(roomId);
      console.log(`[Socket.IO] Socket ${socket.id} joined room ${roomId}`);
    });

    // Leave room
    socket.on('leaveRoom', (roomId) => {
      socket.leave(roomId);
      console.log(`[Socket.IO] Socket ${socket.id} left room ${roomId}`);
    });

    // Handle sending a message in real time
    socket.on('sendMessage', async (data) => {
      try {
        const { senderId, receiverId, groupId, isPublicCampusChat, content, replyTo } = data;

        const newMessage = new Message({
          senderId,
          receiverId: receiverId || null,
          groupId: groupId || null,
          isPublicCampusChat: !!isPublicCampusChat,
          content,
          replyTo: replyTo || null
        });

        await newMessage.save();
        await newMessage.populate('senderId', 'name profilePhoto role isVerified verifiedBadge');
        if (newMessage.replyTo) {
          await newMessage.populate('replyTo');
        }

        // Determine room or broadcast target
        if (isPublicCampusChat) {
          io.to('public_campus_chat').emit('messageReceived', newMessage);
        } else if (groupId) {
          io.to(`group_${groupId}`).emit('groupMessage', newMessage);
        } else if (receiverId) {
          const roomName = [senderId, receiverId].sort().join('_');
          io.to(`chat_${roomName}`).emit('messageReceived', newMessage);
          
          // Direct notification if receiver socket is online
          const receiverSocketId = activeUsers.get(receiverId);
          if (receiverSocketId) {
            io.to(receiverSocketId).emit('newMessageNotification', newMessage);
          }
        }
      } catch (err) {
        console.error('[Socket.IO Error] sendMessage failed:', err.message);
      }
    });

    // Handle typing events
    socket.on('typing', ({ roomId, userId, userName }) => {
      socket.to(roomId).emit('typing', { userId, userName, isTyping: true });
    });

    socket.on('stopTyping', ({ roomId, userId }) => {
      socket.to(roomId).emit('stopTyping', { userId, isTyping: false });
    });

    // Handle message editing
    socket.on('editMessage', async ({ messageId, newContent, roomId }) => {
      try {
        const msg = await Message.findByIdAndUpdate(
          messageId,
          { content: newContent, isEdited: true, updatedAt: Date.now() },
          { new: true }
        ).populate('senderId', 'name profilePhoto role isVerified verifiedBadge');

        if (msg) {
          io.to(roomId).emit('messageEdited', msg);
        }
      } catch (err) {
        console.error('[Socket.IO Error] editMessage failed:', err.message);
      }
    });

    // Handle message deletion
    socket.on('deleteMessage', async ({ messageId, roomId }) => {
      try {
        const msg = await Message.findByIdAndUpdate(
          messageId,
          { isDeleted: true, content: 'This message was deleted.', updatedAt: Date.now() },
          { new: true }
        );

        if (msg) {
          io.to(roomId).emit('messageDeleted', { messageId });
        }
      } catch (err) {
        console.error('[Socket.IO Error] deleteMessage failed:', err.message);
      }
    });

    // Handle reaction
    socket.on('reactMessage', async ({ messageId, userId, emoji, roomId }) => {
      try {
        const msg = await Message.findById(messageId);
        if (msg) {
          msg.reactions = msg.reactions.filter(r => r.userId.toString() !== userId.toString());
          if (emoji) {
            msg.reactions.push({ userId, emoji });
          }
          await msg.save();
          io.to(roomId).emit('messageReaction', { messageId, reactions: msg.reactions });
        }
      } catch (err) {
        console.error('[Socket.IO Error] reactMessage failed:', err.message);
      }
    });

    // Disconnect
    socket.on('disconnect', () => {
      console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
      if (socket.userId) {
        activeUsers.delete(socket.userId);
        io.emit('onlineStatus', { userId: socket.userId, status: 'offline' });
      }
    });
  });
};

const sendRealtimeNotification = async (recipientId, notificationData) => {
  try {
    const Notification = require('../models/Notification');
    let notification = notificationData;
    
    // Create in MongoDB if raw data object passed
    if (!notificationData._id) {
      notification = await Notification.create({
        ...notificationData,
        recipientId,
        message: notificationData.message || notificationData.body,
        body: notificationData.body || notificationData.message
      });
    }

    if (globalIo) {
      const recIdStr = recipientId.toString();
      globalIo.to(`user:${recIdStr}:notifications`).emit('notification:new', notification);

      const unreadCount = await Notification.countDocuments({ recipientId, isRead: false });
      globalIo.to(`user:${recIdStr}:notifications`).emit('notification:unreadCount', { unreadCount });
    }
    return notification;
  } catch (err) {
    console.error('[Socket.IO Error] sendRealtimeNotification failed:', err.message);
  }
};

module.exports = { initSocketIO, sendRealtimeNotification };
