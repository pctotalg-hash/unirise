const bcrypt = require('bcryptjs');
const User = require('../models/User');
const College = require('../models/College');
const Club = require('../models/Club');
const ClubPosition = require('../models/ClubPosition');
const Post = require('../models/Post');
const Event = require('../models/Event');
const Group = require('../models/Group');

const autoSeedIfEmpty = async () => {
  try {
    const salt = await bcrypt.genSalt(10);
    const adminPasswordHash = await bcrypt.hash('Admin@123', salt);
    const studentPasswordHash = await bcrypt.hash('Student@123', salt);
    const coordinatorPasswordHash = await bcrypt.hash('Coordinator@123', salt);

    // 0. Seed Primary College: D. Y. Patil College of Engineering, Akurdi, Pune (DYPCOE)
    const dypcoeCollege = await College.findOneAndUpdate(
      { email: 'admin@unirise.demo' },
      {
        name: 'D. Y. Patil College of Engineering, Akurdi, Pune',
        shortName: 'DYPCOE',
        email: 'admin@unirise.demo',
        domain: 'dypcoeakurdi.ac.in',
        location: 'Akurdi, Pune, Maharashtra',
        adminName: 'DYPCOE Campus Admin',
        status: 'approved',
        isVerified: true
      },
      { upsert: true, new: true }
    );

    await College.deleteMany({ shortName: { $in: ['SIT', 'NCE', 'PTI'] } });

    // 1. Seed Accounts: Admin, Coordinator, and TWO Fictional Test Students (Aarav & Ananya)
    const adminUser = await User.findOneAndUpdate(
      { email: 'admin@unirise.demo' },
      {
        name: 'DYPCOE Campus Admin',
        email: 'admin@unirise.demo',
        passwordHash: adminPasswordHash,
        role: 'admin',
        isVerified: true,
        collegeId: dypcoeCollege._id,
        college: dypcoeCollege.name,
        department: 'Campus Administration',
        year: 'Faculty/Admin',
        bio: 'Official College Administration Account for D. Y. Patil College of Engineering, Akurdi, Pune.',
        profilePhoto: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500'
      },
      { upsert: true, new: true }
    );

    const coordinatorUser = await User.findOneAndUpdate(
      { email: 'coordinator@unirise.demo' },
      {
        name: 'Faculty Coordinator',
        email: 'coordinator@unirise.demo',
        passwordHash: coordinatorPasswordHash,
        role: 'club_coordinator',
        isVerified: true,
        collegeId: dypcoeCollege._id,
        college: dypcoeCollege.name,
        department: 'Computer Engineering',
        year: 'Faculty Lead',
        bio: 'Official Student Activities & Club Coordinator at DYPCOE Akurdi.',
        skills: ['Leadership', 'Event Management', 'Public Relations'],
        profilePhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500'
      },
      { upsert: true, new: true }
    );

    // STUDENT 1: Aarav Kulkarni
    const aaravUser = await User.findOneAndUpdate(
      { email: 'aarav@unirise.demo' },
      {
        name: 'Aarav Kulkarni',
        email: 'aarav@unirise.demo',
        passwordHash: studentPasswordHash,
        role: 'student',
        isVerified: true,
        collegeId: dypcoeCollege._id,
        college: dypcoeCollege.name,
        department: 'Computer Engineering',
        year: '2nd Year',
        bio: 'Building products and learning by doing.',
        skills: ['JavaScript', 'HTML', 'CSS', 'React', 'UI/UX'],
        interests: ['Web Development', 'Hackathons', 'AI', 'Startups'],
        achievements: [
          'Built multiple student projects',
          'Participated in college-level technical events'
        ],
        structuredAchievements: [
          { title: 'Student Web Projects', organization: 'DYPCOE', date: '2026', description: 'Built web apps for campus activities.' }
        ],
        profilePhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        coverPhoto: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1200'
      },
      { upsert: true, new: true }
    );

    // STUDENT 2: Ananya Deshmukh
    const ananyaUser = await User.findOneAndUpdate(
      { email: 'ananya@unirise.demo' },
      {
        name: 'Ananya Deshmukh',
        email: 'ananya@unirise.demo',
        passwordHash: studentPasswordHash,
        role: 'student',
        isVerified: true,
        collegeId: dypcoeCollege._id,
        college: dypcoeCollege.name,
        department: 'Information Technology',
        year: '1st Year',
        bio: 'Exploring AI, design and new ideas.',
        skills: ['Python', 'Data Science', 'AI/ML', 'Canva / Design'],
        interests: ['Artificial Intelligence', 'Data Science', 'Design', 'Events'],
        achievements: [
          'Participated in technical workshops',
          'Interested in AI/ML projects'
        ],
        structuredAchievements: [
          { title: 'Technical Workshop Attendee', organization: 'DYPCOE IT Dept', date: '2026', description: 'Participated in hands-on AI & skill development sessions.' }
        ],
        profilePhoto: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
        coverPhoto: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200'
      },
      { upsert: true, new: true }
    );

    // Student fallback alias
    await User.findOneAndUpdate(
      { email: 'student@unirise.demo' },
      {
        name: 'Aarav Kulkarni',
        email: 'student@unirise.demo',
        passwordHash: studentPasswordHash,
        role: 'student',
        isVerified: true,
        collegeId: dypcoeCollege._id,
        college: dypcoeCollege.name,
        department: 'Computer Engineering',
        year: '2nd Year',
        bio: 'Building products and learning by doing.',
        skills: ['JavaScript', 'HTML', 'CSS', 'React', 'UI/UX'],
        interests: ['Web Development', 'Hackathons', 'AI', 'Startups'],
        achievements: ['Built multiple student projects', 'Participated in college-level technical events'],
        profilePhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'
      },
      { upsert: true, new: true }
    );

    await User.deleteMany({ email: { $in: ['alex@unirise.demo', 'rahul@unirise.demo', 'priya@unirise.demo', 'emily@unirise.demo'] } });

    // Mutual connection
    aaravUser.connections = [ananyaUser._id];
    ananyaUser.connections = [aaravUser._id];
    await aaravUser.save();
    await ananyaUser.save();

    // 2. STRICTLY 4 CLUBS ONLY — REMOVE ALL OTHER CLUBS / FAKE CLUBS / POSTER CLUBS
    await Club.deleteMany({}); // Wipe out any extra/demo clubs

    const tedxClub = await Club.create({
      name: 'TEDx DYP Akurdi',
      tagline: 'Meet the Voices • Ideas Worth Spreading',
      description: 'Independently organized TED event at D.Y. Patil Akurdi, showcasing inspirational talks on astrophysics, education, AI & aviation, endurance, screen & stage, and music.',
      category: 'Talk / Conference',
      isVerified: true,
      coordinatorId: adminUser._id,
      logo: '/assets/clubs/club_tedx_dyp_akurdi.jpg',
      coverImage: '/assets/posters/poster_tedx_dyp_akurdi.png',
      members: [aaravUser._id],
      socialLinks: { instagram: 'https://www.instagram.com/tedxdypakurdi' }
    });

    const nssClub = await Club.create({
      name: 'NSS DYPCOE',
      tagline: 'Not Me But You — Youth & Community Service',
      description: 'National Service Scheme unit of DYPCOE engaged in community service, social awareness, and youth development.',
      category: 'Social Service & Community',
      isVerified: true,
      coordinatorId: adminUser._id,
      logo: '/assets/clubs/club_nss_dypcoe.jpg',
      coverImage: '/assets/clubs/club_nss_dypcoe.jpg',
      members: [ananyaUser._id],
      socialLinks: { instagram: 'https://www.instagram.com/nssdypcoe' }
    });

    const merakiBand = await Club.create({
      name: 'The Meraki Band',
      tagline: 'Official Music Band of DYPCOE',
      description: 'Official Music Band of DYPCOE performing live campus concerts and inter-college competitions.',
      category: 'Music & Arts',
      isVerified: true,
      coordinatorId: coordinatorUser._id,
      logo: '/assets/clubs/club_meraki_band.png',
      coverImage: '/assets/clubs/club_meraki_band.png',
      members: [aaravUser._id],
      socialLinks: { instagram: 'https://www.instagram.com/the.merakiband' }
    });

    const gdgcClub = await Club.create({
      name: 'GDGC DYPCOE',
      tagline: 'Google Developer Groups On Campus DYPCOE',
      description: 'Google Developer Groups on Campus at DYPCOE empowering students with Android, Cloud, Web, and AI technology.',
      category: 'Technology & Open Source',
      isVerified: true,
      coordinatorId: coordinatorUser._id,
      logo: '/assets/clubs/club_gdgc_dypcoe.png',
      coverImage: '/assets/clubs/club_gdgc_dypcoe.png',
      members: [aaravUser._id, ananyaUser._id],
      socialLinks: { instagram: 'https://www.instagram.com/gdgc.dypcoe' }
    });

    // Clean positions
    await ClubPosition.deleteMany({});
    await ClubPosition.create({
      clubId: gdgcClub._id,
      userId: aaravUser._id,
      positionName: 'Student Member',
      status: 'ACTIVE'
    });

    // 3. SEED REAL POSTS / EVENTS / OPPORTUNITIES (Posters are content/posts, not extra clubs)
    await Post.deleteMany({});

    const realPosts = [
      {
        title: "AI Club Coordinator Recruitment",
        content: "ARE YOU READY TO MAKE AN IMPACT?\n\nIT Department Club - Join the AI Club!\nCoordinator Recruitment for 1st & 2nd Year Students.\n\nTagline: LEARN — BUILD — INNOVATE\n\nAvailable Coordinator Roles:\n• Generative AI (Gen AI)\n• AI & ML\n• Data Science\n• Web Development\n• Design\n• Documentation\n• PR\n• Events & Activities\n• Finance\n• Media\n\nRegistration Last Date: 8 Oct 2026\nTrain Your Brain, Train Your Model.",
        category: "Opportunities",
        hashtags: ["#AI", "#ArtificialIntelligence", "#MachineLearning", "#DataScience", "#WebDevelopment", "#ClubRecruitment", "#DYPCOE"],
        applyUrl: "https://www.dypcoeakurdi.ac.in",
        media: ["/assets/posters/poster_ai_club_recruitment.png"],
        authorId: coordinatorUser._id
      },
      {
        title: "5 Days Skill Development Workshop",
        content: "ACM–Pradnyan Student Chapter (Department of Computer Engineering) presents 5 Days Skill Development Workshop on UI/UX, OOPs and Data Structures!\n\nDate: 05 Oct – 09 Oct 2026\nTime: 7:30 P.M. – 8:30 P.M. (Online)\nMode: Online (Attend from anywhere)\nCertificate: E-Certificate (Participation)\nFee: No Registration Charges!\n\nSchedule:\n• Day 1 (05/10/2026): Introduction to UI/UX\n• Day 2 (06/10/2026): Information Architecture\n• Day 3 (07/10/2026): Designs and Deploy\n• Day 4 (08/10/2026): OOPs and DSA\n• Day 5 (09/10/2026): Mini Project Development\n\nWhy Join:\n- Learn with real examples\n- Guidance from experienced faculty\n- Hands-on practice\n- Build skills for projects and placements\n\nWho Can Join: All students interested in UI/UX, OOPs and Data Structures.",
        category: "Events",
        hashtags: ["#ACM", "#Pradnyan", "#Workshop", "#UIUX", "#OOP", "#DataStructures", "#ComputerEngineering"],
        applyUrl: "https://www.dypcoeakurdi.ac.in",
        media: ["/assets/posters/poster_acm_pradnyan_workshop.jpg"],
        authorId: aaravUser._id
      },
      {
        title: "DEBATE X — Technical Debate Championship 2026",
        content: "IEI Student Chapter (Department of Computer Engineering) presents DEBATE X — Technical Debate Championship 2026!\n\nTagline: THINK | ANALYSE | ARGUE | WIN\n\nA platform to discuss today's technology, sharpen your perspective and build your voice.\n\nTopics:\n• AI & Emerging Tech\n• Software & Computing\n• Internet of Things\n• Cybersecurity\n• Cloud & Network Technologies\n• And More\n\nStructure:\n• Team Size: 4 Members per team\n• 3 Rounds (Round 1: Easy - Team vs Team, Round 2: Moderate - Switch Sides, Round 3: Difficult)\n\nDate: 8 October 2026\nOrganised by: IEI Student Chapter, Dept. of Computer Engineering.",
        category: "Events",
        hashtags: ["#IEI", "#Debate", "#Technology", "#Competition", "#ComputerEngineering", "#AI", "#Cybersecurity", "#IoT"],
        applyUrl: "https://www.dypcoeakurdi.ac.in",
        media: ["/assets/posters/poster_iei_debate_x.png"],
        authorId: coordinatorUser._id
      },
      {
        title: "TEDx DYP Akurdi — Meet the Voices",
        content: "TEDx DYP Akurdi — Meet the Voices took place on 06 October 2026 at Shantai Auditorium, D. Y. Patil, Akurdi, Pune!\n\nFeatured Speakers:\n1. Prof. Ajit Kembhavi (Astrophysics) — Emeritus Professor, founder & former Director IUCAA. Ex-Vice President IAU. Member, Apex Science Board ISRO.\n2. Dr. Anuj Pachhel (Education) — NEET educator and content creator with 1M+ YouTube subscribers.\n3. Mr. Dinakara Nagalla (AI & Aviation) — AI innovator, entrepreneur and founder across AI, education and technology.\n4. Mr. Adil Nargolwala (Endurance) — Senior HR & talent leader. Marathons on all 7 continents, Ironman, Mount Elbrus.\n5. Mrs. Apurva Nemlekar (Screen & Stage) — Popular Marathi actress across TV, theatre and film.\n6. Mrs. Sonali Sonawane (Music) — Marathi playback singer behind hits like Nakhrewali and Jhumka.\n\nVenue: Shantai Auditorium, D Y Patil, Akurdi, Pune.",
        category: "Events",
        hashtags: ["#TEDx", "#TEDxDYP", "#DYPCOE", "#Talk", "#Technology", "#Education"],
        applyUrl: "https://www.dypcoeakurdi.ac.in",
        media: ["/assets/posters/poster_tedx_dyp_akurdi.png"],
        authorId: adminUser._id,
        clubId: tedxClub._id
      },
      {
        title: "SAMBHAV 4.0 — Coordinator Recruitment",
        content: "SAMBHAV 4.0 — WE ARE RECRUITING!\nThe Official TechFest of DYPCOE is searching for passionate coordinators!\n\nDate: 8th and 9th October 2026\nVenue: C Wing Entrance Lobby\n\nRecruitment Areas:\n• Media (Photo/Video/Editing)\n• Event Management\n• Sponsorship\n• Public Relations\n• Creatives (Decoration)\n• Design\n• Technical\n• Documentation\n\nAPPLY NOW at C Wing Entrance Lobby!",
        category: "Opportunities",
        hashtags: ["#SAMBHAV4", "#TechFest", "#Recruitment", "#Media", "#EventManagement", "#Sponsorship", "#PR", "#Design", "#Technical", "#Documentation"],
        applyUrl: "https://www.dypcoeakurdi.ac.in",
        media: ["/assets/posters/poster_sambhav_recruitment.png"],
        authorId: coordinatorUser._id
      }
    ];

    for (const postData of realPosts) {
      await Post.create(postData);
    }

    // 4. Seed Real Events
    await Event.deleteMany({});

    // ACM Workshop (Ongoing Oct 5 - Oct 9)
    await Event.create({
      title: '5 Days Skill Development Workshop on UI/UX, OOPs and Data Structures',
      description: 'Skill development workshop organized by ACM–Pradnyan Student Chapter covering UI/UX, OOPs, Data Structures, and Mini Project Development.',
      createdBy: aaravUser._id,
      date: new Date('2026-10-05T19:30:00.000Z'),
      endDate: new Date('2026-10-09T20:30:00.000Z'),
      time: '07:30 PM – 08:30 PM',
      location: 'Online (Google Meet)',
      registrationUrl: 'https://www.dypcoeakurdi.ac.in',
      mediaUrl: '/assets/posters/poster_acm_pradnyan_workshop.jpg'
    });

    // IEI DEBATE X (Upcoming Oct 8)
    await Event.create({
      title: 'DEBATE X — Technical Debate Championship 2026',
      description: '3-Round Technical Debate Championship organized by IEI Student Chapter covering AI, Cybersecurity, IoT, and Computing.',
      createdBy: coordinatorUser._id,
      date: new Date('2026-10-08T09:00:00.000Z'),
      time: '09:00 AM',
      location: 'Computer Engineering Department, DYPCOE',
      registrationUrl: 'https://www.dypcoeakurdi.ac.in',
      mediaUrl: '/assets/posters/poster_iei_debate_x.png'
    });

    // TEDx DYP Akurdi (Past Oct 6)
    await Event.create({
      title: 'TEDx DYP Akurdi — Meet the Voices',
      description: 'Independently organized TED event featuring 6 inspirational speakers across Astrophysics, Education, AI & Aviation, Endurance, Screen & Stage, and Music.',
      clubId: tedxClub._id,
      createdBy: adminUser._id,
      date: new Date('2026-10-06T10:00:00.000Z'),
      time: '10:00 AM',
      location: 'Shantai Auditorium, D Y Patil, Akurdi, Pune',
      registrationUrl: 'https://www.dypcoeakurdi.ac.in',
      mediaUrl: '/assets/posters/poster_tedx_dyp_akurdi.png'
    });

    // SAMBHAV 4.0 TechFest (Upcoming Oct 8-9)
    await Event.create({
      title: 'SAMBHAV 4.0 — Coordinator Recruitment Drive',
      description: 'Official TechFest of DYPCOE coordinator recruitment drive for Media, Event Management, Sponsorship, PR, Creatives, Design, Technical, and Documentation.',
      createdBy: coordinatorUser._id,
      date: new Date('2026-10-08T09:00:00.000Z'),
      endDate: new Date('2026-10-09T17:00:00.000Z'),
      time: '09:00 AM – 05:00 PM',
      location: 'C Wing Entrance Lobby, DYPCOE',
      registrationUrl: 'https://www.dypcoeakurdi.ac.in',
      mediaUrl: '/assets/posters/poster_sambhav_recruitment.png'
    });

    // 5. Seed Real Campus Groups
    await Group.deleteMany({});
    await Group.create({
      name: 'DYPCOE Computer Engineering Tech Group',
      description: 'Official group for Computer Engineering students discussing workshops, projects, and coding contests.',
      adminId: coordinatorUser._id,
      isPrivate: false,
      members: [aaravUser._id, ananyaUser._id, coordinatorUser._id]
    });

    await Group.create({
      name: 'AI & Data Science Student Forum',
      description: 'Official forum for AI & Data Science enthusiasts at DYPCOE.',
      adminId: coordinatorUser._id,
      isPrivate: false,
      members: [ananyaUser._id, aaravUser._id]
    });

    console.log('==================================================');
    console.log('✅ REAL DYPCOE DATABASE SEED COMPLETE (EXACTLY 4 CLUBS ONLY)!');
    console.log('Clubs: 1. TEDx DYP Akurdi | 2. NSS DYPCOE | 3. The Meraki Band | 4. GDGC DYPCOE');
    console.log('==================================================');
  } catch (err) {
    console.error('AutoSeed Error:', err.message);
  }
};

module.exports = { autoSeedIfEmpty };
