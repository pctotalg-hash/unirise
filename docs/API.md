# UNIRISE REST API & Real-time Architecture Documentation

UNIRISE is a cross-platform campus social and community application connecting students, clubs, and college administration.

---

## 1. Environment Variables & Setup

Create a `.env` file in the `backend/` directory:

```env
PORT=5000
MONGO_URI=mongodb+srv://your_username:your_password@your_cluster.mongodb.net/unirise?retryWrites=true&w=majority
JWT_SECRET=your_jwt_secret_here
AI_API_KEY=your_ai_api_key_here
CLIENT_URL=*
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

---

## 2. Demo Credentials

| Role | Email | Password | Access Level |
|---|---|---|---|
| **Admin** | `admin@unirise.demo` | `Admin@123` | Full System Access, User/Club Verification, Position Transfers, Admin Dashboard |
| **Student** | `student@unirise.demo` | `Student@123` | Feed, Posts, Search, Chat, Clubs, Connections, Apply to Internships |
| **Club Coordinator** | `coordinator@unirise.demo` | `Coordinator@123` | Student Access + Assigned Club Profile Edit, Create Club Posts/Events, Core Team & Position Transfer |

---

## 3. API Endpoints Reference

### AUTHENTICATION (`/api/auth`)
- `POST /api/auth/register` - Register new student (Body: `name`, `email`, `password`, `college`, `department`, `year`)
- `POST /api/auth/login` - Authenticate user & get JWT token (Body: `email`, `password`)
- `POST /api/auth/logout` - Logout user session
- `GET /api/auth/me` - Get current authenticated user profile (`Bearer <token>`)

### USERS (`/api/users`)
- `GET /api/users` - Get list of campus users
- `GET /api/users/:id` - Get user profile details
- `PUT /api/users/:id` - Update user bio, skills, achievements, profile/cover photos
- `GET /api/users/:id/posts` - Get user's post history
- `POST /api/users/:id/connect` - Connect or disconnect with a campus student

### POSTS & FEED (`/api/posts`)
- `GET /api/posts?category=&search=` - Get mixed feed or category-filtered posts
- `POST /api/posts` - Create post (Body: `title`, `content`, `category`, `hashtags`, `media`, `applyUrl`, `eventDate`)
- `GET /api/posts/:id` - Get single post full details (Double tap target)
- `PUT /api/posts/:id` - Update post
- `DELETE /api/posts/:id` - Delete post
- `POST /api/posts/:id/like` - Toggle like on post
- `POST /api/posts/:id/comment` - Add comment (Body: `text`)
- `POST /api/posts/:id/share` - Increment share count

### CLUBS & POSITIONS (`/api/clubs`)
- `GET /api/clubs` - Get official campus clubs grid
- `POST /api/clubs` - Create new club (Admin / Coordinator)
- `GET /api/clubs/:id` - Get club details, mission, social links
- `PUT /api/clubs/:id` - Update club profile / cover image (Coordinator/Admin)
- `GET /api/clubs/:id/posts` - Get club announcements & posts
- `GET /api/clubs/:id/events` - Get club events
- `GET /api/clubs/:id/core-team` - Get club positions & verified core team
- `GET /api/clubs/:id/positions` - Get position audit trail
- `POST /api/clubs/:id/positions` - Assign position badge (Body: `userId`, `positionName`)
- `POST /api/clubs/:id/positions/:positionId/transfer` - **Transfer Position** (Body: `newUserId`)

### SEARCH & AI ASSISTANT (`/api/search`)
- `GET /api/search?q=&filter=` - Global search across Students, Clubs, Posts, Events, Hackathons, Internships, Groups
- `GET /api/search/ai?q=` - AI Search Assistant intelligent suggestions

### COMMUNICATION & MESSAGES (`/api/messages`)
- `GET /api/messages/:targetId?type=` - Fetch messages (`type=public`, `type=group`, or `type=private`)
- `POST /api/messages` - Send message (Body: `content`, `receiverId`, `groupId`, `isPublicCampusChat`)
- `PUT /api/messages/:id` - Edit message
- `DELETE /api/messages/:id` - Delete message

### NOTIFICATIONS (`/api/notifications`)
- `GET /api/notifications` - Get user notifications & unread count
- `PUT /api/notifications/:id/read` - Mark single notification as read
- `PUT /api/notifications/read-all` - Mark all notifications read

### ADMIN DASHBOARD (`/api/admin`)
- `GET /api/admin/dashboard` - Get platform overview stats
- `GET /api/admin/users` - Get all registered users
- `GET /api/admin/clubs` - Get all campus clubs
- `POST /api/admin/verify-user` - Verify/Unverify user account & assign official verified badge
- `POST /api/admin/verify-club` - Verify official club badge
- `DELETE /api/admin/posts/:id` - Moderate/Remove content

---

## 4. Socket.IO Real-time Events

- **Connection**: `connection`
- **Register**: `registerUser` (`userId`)
- **Rooms**: `joinRoom` (`roomId`), `leaveRoom` (`roomId`)
- **Messages**: `sendMessage`, `messageReceived`, `groupMessage`
- **Interactions**: `typing`, `stopTyping`, `messageEdited`, `messageDeleted`, `messageReaction`, `onlineStatus`
