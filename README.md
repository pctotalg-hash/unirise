# UNIRISE — Connect. Discover. Rise.

![UNIRISE Logo](frontend/web/logo.png)

UNIRISE is a comprehensive campus social & community platform built for **D. Y. Patil College of Engineering (DYPCOE), Akurdi, Pune**. It connects students, verified student clubs, event organizers, and campus administration into one integrated environment.

---

## 📌 Project Overview

UNIRISE solves campus fragmentation by unifying student profiles, club discovery, event registrations, hackathons, skill-building workshops, peer networking, and real-time messaging into a single application.

---

## ❓ Problem Statement

In modern college environments:
1. **Fragmented Communication**: Notices, hackathons, and recruitment drives are scattered across disparate social media channels and WhatsApp groups.
2. **Disconnected Student Profiles**: Students lack a verified campus portfolio showcasing their projects, technical skills, achievements, and club positions.
3. **Complex Club Management**: Verification of student leadership positions and transfer of official club roles lack clear audit trails and verification.
4. **Restricted Messaging**: Unrestricted cold messaging often leads to spam, necessitating verified connection mutual consent before private 1-on-1 messaging.

---

##💡 Solution

UNIRISE provides a secure, single-sign-on campus platform featuring:
- **Verified Campus Feed**: Interactive posts for Hackathons, Internships, Workshops, and Opportunities with full-screen poster inspection.
- **Official Club Directory**: Verified student organizations with verified position badges (`STUDENT MEMBER ✓`).
- **Connection-Based Messaging**: A 3-state connection machine (`NOT_CONNECTED` ➔ `PENDING` ➔ `ACCEPTED`) that protects student privacy before enabling private 1-on-1 messaging.
- **AI Search Agent**: Natural language intent recognition and automated campus recommendation synthesis.
- **Real-Time Communication**: Multi-channel Socket.IO chat for public campus forums, community groups, and private messages.

---

## ✨ Key Features

- **Interactive Feed & Media Posters**: High-resolution poster viewer for campus opportunities (AI Club Recruitment, ACM Skill Development Workshop, IEI DEBATE X, TEDx DYP Akurdi, SAMBHAV 4.0).
- **Verified Clubs & Organizations**:
  - **TEDx DYP Akurdi** (Talks & Conference)
  - **NSS DYPCOE** (National Service Scheme Unit)
  - **The Meraki Band** (Official Campus Music Band)
  - **GDGC DYPCOE** (Google Developer Groups on Campus)
- **Role-Based Access Control (RBAC)**: Distinct permissions for `student`, `club_coordinator`, and `admin` roles.
- **Privacy & Security**: Enforced authorization checks blocking unauthorized access to private chats and groups.
- **Theme System**: Full support for Dark Mode (`#0C0E14`) and Light Mode (`#F8FAFC`) with dynamic theme persistence.
- **Progressive Web App (PWA)**: Web manifest (`manifest.json`), touch icons, and mobile app layout frame.

---

## 🛠️ Technology Stack

- **Frontend**: Web App (HTML5, Tailwind CSS, JavaScript ES6+) & Flutter (Dart)
- **Backend Server**: Node.js, Express.js
- **Database**: MongoDB Atlas (Mongoose ODM with in-memory fallback)
- **Real-Time Engine**: Socket.IO
- **Authentication**: JSON Web Tokens (JWT) & bcryptjs password hashing
- **Testing**: Node.js Automated Verification Test Suite

---

## 📁 Project Structure

```
unirise/
├── backend/
│   ├── config/             # Database connection setup (MongoDB Atlas & Fallback)
│   ├── controllers/        # REST API controllers (Auth, Posts, Clubs, Events, Search, Messages)
│   ├── middleware/         # JWT authentication & error handling middleware
│   ├── models/             # Mongoose schemas (User, College, Club, Post, Event, Group, Message)
│   ├── routes/             # Express API routes
│   ├── seed/               # Automated DYPCOE data seed script (autoSeed.js)
│   ├── services/           # Socket.IO & AI Search service modules
│   ├── tests/              # Functional verification & security test scripts
│   ├── .env.example        # Environment variable templates
│   └── server.js           # Main Node.js server entry point
├── frontend/
│   ├── assets/             # Images, poster graphics, and official logos
│   ├── lib/                # Flutter source files (models, services, features, navigation)
│   └── web/                # Production web build (index.html, manifest.json, favicons, posters, clubs)
├── docs/                   # Documentation and API references
├── .env.example            # Root environment variable template
├── .gitignore              # Git ignore rules protecting secrets and build binaries
├── package.json            # Root npm script launcher
└── README.md               # Project documentation
```

---

## 📋 Prerequisites

- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **MongoDB**: Local MongoDB instance or MongoDB Atlas Connection String
- *(Optional)* **Flutter SDK**: v3.0.0+ for running mobile builds

---

## ⚙️ Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/unirise.git
   cd unirise
   ```

2. **Install Backend Dependencies**:
   ```bash
   cd backend
   npm install
   ```

---

## 🔐 Environment Variables

Create a `.env` file inside the `backend/` directory using the provided `.env.example` template:

```env
PORT=5000
MONGO_URI=mongodb+srv://your_username:your_password@your_cluster.mongodb.net/unirise?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_jwt_key_unirise_2026
AI_API_KEY=your_gemini_or_openai_api_key
CLIENT_URL=*
```

> ⚠️ **IMPORTANT**: Never commit your real `.env` file or database credentials to GitHub!

---

## 🚀 How to Run

### Option 1: Quick Start (Node.js & Web Platform)

From the project root directory, run:

```bash
npm start
```

This starts the Node.js backend server and automatically seeds the DYPCOE campus dataset.

Open your browser and navigate to:
👉 **`http://localhost:5000`**

### Option 2: Running Flutter Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 🔑 Demo Credentials

Quick-login buttons are built into the web interface for easy testing:

| Role | Name | Email | Password | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Student 1** | Aarav Kulkarni | `aarav@unirise.demo` | `Student@123` | 2nd Year, Computer Engineering |
| **Student 2** | Ananya Deshmukh | `ananya@unirise.demo` | `Student@123` | 1st Year, Information Technology |
| **Coordinator** | Faculty Coordinator | `coordinator@unirise.demo` | `Coordinator@123` | Computer Engineering Faculty Lead |
| **College Admin**| DYPCOE Campus Admin | `admin@unirise.demo` | `Admin@123` | Official College Administration |

---

## 🗄️ Database Setup

UNIRISE uses an **idempotent auto-seeding system** located at `backend/seed/autoSeed.js`.

Upon server startup:
- Connects to **MongoDB Atlas**.
- If MongoDB Atlas is unavailable, it automatically starts an **in-memory MongoDB server** (`mongodb-memory-server`) for zero-configuration local prototyping.
- Automatically seeds the DYPCOE college record, verified club profiles, event schedules, and real poster posts.

---

## 🌐 API Setup

The REST API runs under the `/api` prefix:
- `POST /api/auth/login` — Authenticate user & receive JWT.
- `POST /api/auth/register` — Student account registration.
- `GET /api/posts` — Fetch campus feed posts.
- `GET /api/clubs` — Fetch official verified clubs directory.
- `GET /api/events` — Fetch campus events and status.
- `GET /api/search` — Perform global multi-category campus search.
- `GET /api/search/ai` — Query AI Assistant Agent.
- `POST /api/users/:id/connect` — Send/accept/cancel connection requests.
- `GET /api/messages/history/:userId` — Fetch private 1-on-1 chat history.

---

## 🤖 AI Features

The **UNIRISE AI Search Agent** (`backend/services/aiSearchService.js`):
1. Analyzes user search queries to recognize intent (e.g. *Artificial Intelligence Focus*, *Career Search*, *Club Discovery*).
2. Dynamically queries the database for matching skills, posts, and clubs.
3. Synthesizes personalized campus recommendations without generating hallucinated or non-existent events.

---

## 💬 Communication / Chat

- **Public Campus Forum**: Real-time broadcast channel using Socket.IO events (`send_message`, `receive_message`).
- **Community Groups**: Multi-member discussions for technical topics (e.g. *DYPCOE Computer Engineering Tech Group*).
- **Personal 1-on-1 Messaging**: Privacy-protected direct messaging accessible **only** after a mutual connection request is accepted.

---

## 🏛️ Clubs and Events

- **Clubs Section**: Dedicated profiles for official DYPCOE organizations:
  - **TEDx DYP Akurdi**
  - **NSS DYPCOE**
  - **The Meraki Band**
  - **GDGC DYPCOE**
- **Events Section**: Tracks ongoing, upcoming, and past events with real poster media:
  - **5 Days Skill Development Workshop** (ACM–Pradnyan — Status: *ONGOING*)
  - **DEBATE X Technical Debate Championship** (IEI — Status: *UPCOMING*)
  - **SAMBHAV 4.0 Recruitment Drive** (Status: *UPCOMING*)
  - **TEDx DYP Akurdi Conference** (Status: *PAST / COMPLETED*)

---

## 🧪 Testing

To execute the complete backend automated test suite:

```bash
node backend/tests/test_critical_bugs.js
node backend/tests/test_dypcoe_search_ai.js
```

All 5/5 critical bug tests and 19/19 search & AI queries pass with 100% success.

---

## 🔮 Future Scope

- **Push Notifications**: Integration with Firebase Cloud Messaging (FCM) for native mobile push alerts.
- **Web3 Credentials**: Blockchain-verified digital certificates for club positions and hackathon wins.
- **Expanded AI Agent**: AI-driven teammate matching based on complementary skill sets and project interests.

---

## 👥 Team

- **Platform**: UNIRISE Campus Community Team
- **College**: D. Y. Patil College of Engineering, Akurdi, Pune
- **Website**: [dypcoeakurdi.ac.in](https://www.dypcoeakurdi.ac.in)

---
*License: MIT*
