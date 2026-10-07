const Event = require('../models/Event');
const Club = require('../models/Club');
const { sendRealtimeNotification } = require('../services/socketService');
const { checkSearchAlertsForEntity } = require('../services/aiSearchAlertService');

const getEvents = async (req, res, next) => {
  try {
    const events = await Event.find()
      .populate('clubId', 'name logo coverImage')
      .populate('createdBy', 'name profilePhoto')
      .sort({ date: 1 });
    res.json(events);
  } catch (err) {
    next(err);
  }
};

const createEvent = async (req, res, next) => {
  try {
    const { title, description, clubId, date, time, location, registrationUrl, image } = req.body;

    if (!title || !description || !date) {
      return res.status(400).json({ message: 'Title, description, and date are required' });
    }

    const event = await Event.create({
      title,
      description,
      clubId: clubId || null,
      createdBy: req.user._id,
      date,
      time: time || '10:00 AM',
      location: location || 'Campus Main Hall',
      registrationUrl,
      image: image || 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200'
    });

    // Notify club members
    if (clubId) {
      try {
        const club = await Club.findById(clubId).populate('members', '_id');
        if (club && club.members) {
          for (const member of club.members) {
            if (member._id.toString() !== req.user._id.toString()) {
              await sendRealtimeNotification(member._id, {
                actorId: req.user._id,
                type: 'CLUB_EVENT',
                title: `📅 New Event in ${club.name}`,
                body: `Event: "${title}" at ${location || 'Campus'} on ${new Date(date).toLocaleDateString()}`,
                message: `Event: "${title}" at ${location || 'Campus'} on ${new Date(date).toLocaleDateString()}`,
                entityType: 'event',
                entityId: event._id.toString(),
                referenceId: event._id.toString(),
                metadata: { clubId: club._id.toString(), eventId: event._id.toString() }
              });
            }
          }
        }
      } catch (e) {
        console.error('Event notification dispatch error:', e);
      }
    }

    // Check AI search alerts
    checkSearchAlertsForEntity('event', event).catch(err => console.error('AI Alert check error:', err));

    res.status(201).json(event);
  } catch (err) {
    next(err);
  }
};

const getEventById = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('clubId', 'name logo tagline coverImage')
      .populate('createdBy', 'name profilePhoto role');
    if (!event) return res.status(404).json({ message: 'Event not found' });
    res.json(event);
  } catch (err) {
    next(err);
  }
};

const deleteEvent = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ message: 'Event not found' });

    if (event.createdBy.toString() !== req.user._id.toString() && req.user.role !== 'ADMIN') {
      return res.status(403).json({ message: 'Not authorized to delete this event' });
    }

    await event.deleteOne();
    res.json({ message: 'Event deleted successfully' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getEvents,
  createEvent,
  getEventById,
  deleteEvent
};
