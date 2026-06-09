import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/event.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

/// All mock content Anza ships with. Because the app has no backend, this
/// file is the single source of truth for "day one" data — providers copy
/// from here into memory (and shared_preferences) at startup.
///
/// Dates are generated relative to "now" so there's always at least one
/// event happening "today", which makes the check-in flow demoable
/// regardless of when the team runs the app.
class SeedData {
  SeedData._();

  // ---------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------

  static final List<AppUser> users = [
    const AppUser(
      id: 'u1',
      name: 'Amara Chen',
      email: 'amara.chen@alustudent.com',
      role: UserRole.student,
      interests: ['Hackathon', 'Startup', 'Workshop'],
      avatarColor: AppColors.primary,
    ),
    const AppUser(
      id: 'u2',
      name: 'David Okafor',
      email: 'david.okafor@alustudent.com',
      role: UserRole.verified,
      verifiedOrg: 'Robotics Club',
      interests: ['Hackathon', 'Workshop'],
      avatarColor: AppColors.secondary,
    ),
    const AppUser(
      id: 'u3',
      name: 'Grace Mwangi',
      email: 'grace.mwangi@alustudent.com',
      role: UserRole.student,
      interests: ['Leadership', 'Internship'],
      avatarColor: Color(0xFF7C5CFC),
    ),
    const AppUser(
      id: 'u4',
      name: 'Samuel Diallo',
      email: 'samuel.diallo@alustudent.com',
      role: UserRole.verified,
      verifiedOrg: 'Academic Success Team',
      interests: ['Leadership', 'Internship'],
      avatarColor: AppColors.verified,
    ),
    const AppUser(
      id: 'u5',
      name: 'Fatima Yusuf',
      email: 'fatima.yusuf@alustudent.com',
      role: UserRole.verified,
      verifiedOrg: 'Founders Hub',
      interests: ['Startup', 'Leadership'],
      avatarColor: Color(0xFFE8A33D),
    ),
    const AppUser(
      id: 'u6',
      name: 'Brian Tumusiime',
      email: 'brian.tumusiime@alustudent.com',
      role: UserRole.student,
      interests: ['Event', 'Hackathon', 'Workshop'],
      avatarColor: Color(0xFF1E9E5A),
    ),
  ];

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  static List<Event> events() {
    final now = DateTime.now();
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      final base = now.add(Duration(days: dayOffset));
      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    return [
      Event(
        id: 'e1',
        title: "Founders' Friday Pitch Night",
        description:
            'Pitch your startup idea to a panel of student founders and mentors. '
            'Open floor for feedback, networking, and a little friendly competition. '
            'Snacks provided — bring your boldest idea.',
        category: EventCategory.startup,
        posterId: 'u5',
        posterName: 'Fatima Yusuf',
        posterVerifiedOrg: 'Founders Hub',
        dateTime: at(0, 17, 30),
        location: 'Innovation Hub, Room 204',
        imageColor: AppColors.accentPalette[0],
        checkInCode: 'PITCH1',
        rsvpUserIds: ['u1', 'u3'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e2',
        title: 'Intro to Flutter Workshop',
        description:
            'Hands-on session building your first mobile screen with Flutter. '
            'Laptops required — we will get you from zero to a working app by the end '
            'of the session. Beginners welcome.',
        category: EventCategory.workshop,
        posterId: 'u2',
        posterName: 'David Okafor',
        posterVerifiedOrg: 'Robotics Club',
        dateTime: at(0, 14, 0),
        location: 'Engineering Lab B',
        imageColor: AppColors.accentPalette[1],
        checkInCode: 'FLUTR2',
        rsvpUserIds: ['u1', 'u6'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e3',
        title: 'Climate Ventures Info Session',
        description:
            'Learn about paid internship placements with climate-focused startups '
            'across East Africa. Reps from three partner companies will be on campus '
            'to answer questions and collect applications.',
        category: EventCategory.internship,
        posterId: 'u4',
        posterName: 'Samuel Diallo',
        posterVerifiedOrg: 'Academic Success Team',
        dateTime: at(2, 11, 0),
        location: 'Auditorium A',
        imageColor: AppColors.accentPalette[4],
        checkInCode: 'CLIM3X',
        rsvpUserIds: ['u3'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e4',
        title: 'ALU Hackathon: Build for Rwanda',
        description:
            '48 hours to design and prototype a solution to a real local challenge. '
            'Form a team of up to four, or join one on the night. Prizes for the top '
            'three teams and a fast-track interview with our partner incubator.',
        category: EventCategory.hackathon,
        posterId: 'u2',
        posterName: 'David Okafor',
        posterVerifiedOrg: 'Robotics Club',
        dateTime: at(5, 9, 0),
        location: 'Main Campus Atrium',
        imageColor: AppColors.accentPalette[2],
        checkInCode: 'HACK4R',
        rsvpUserIds: ['u1', 'u6', 'u3'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e5',
        title: 'Leadership Lab: Speak With Confidence',
        description:
            'A practical workshop on public speaking and presence — for student '
            'leaders preparing for elections, pitches, or panels. Includes live '
            'practice rounds with feedback from peers.',
        category: EventCategory.leadership,
        posterId: 'u4',
        posterName: 'Samuel Diallo',
        posterVerifiedOrg: 'Academic Success Team',
        dateTime: at(-1, 15, 0),
        location: 'Seminar Room 3',
        imageColor: AppColors.accentPalette[3],
        checkInCode: 'SPEAK5',
        rsvpUserIds: ['u3', 'u1'],
        attendeeUserIds: const ['u3'],
      ),
      Event(
        id: 'e6',
        title: 'Robotics Club Open Demo Day',
        description:
            'Come see what the Robotics Club has been building this term — line '
            'followers, a salvaged-parts arm, and our entry for the regional '
            'competition. Open to all, no experience needed.',
        category: EventCategory.event,
        posterId: 'u2',
        posterName: 'David Okafor',
        posterVerifiedOrg: 'Robotics Club',
        dateTime: at(3, 16, 0),
        location: 'Engineering Lab A',
        imageColor: AppColors.accentPalette[5],
        checkInCode: 'DEMO6Q',
        rsvpUserIds: ['u6'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e7',
        title: 'Internship Prep: CV & Interview Clinic',
        description:
            'Drop in for a one-on-one CV review and a mock interview with staff '
            'from the Academic Success Team. Limited slots — first come, first '
            'served, but we will keep a waitlist.',
        category: EventCategory.internship,
        posterId: 'u4',
        posterName: 'Samuel Diallo',
        posterVerifiedOrg: 'Academic Success Team',
        dateTime: at(7, 10, 30),
        location: 'Career Services Office',
        imageColor: AppColors.accentPalette[1],
        checkInCode: 'CVPREP',
        rsvpUserIds: const [],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e8',
        title: 'Women in Tech Mixer',
        description:
            'An evening of conversation, lightning talks, and networking for women '
            'studying or working in tech on campus. All genders welcome as allies '
            'and guests.',
        category: EventCategory.event,
        posterId: 'u5',
        posterName: 'Fatima Yusuf',
        posterVerifiedOrg: 'Founders Hub',
        dateTime: at(1, 18, 0),
        location: 'Rooftop Terrace',
        imageColor: AppColors.accentPalette[0],
        checkInCode: 'WIT8MX',
        rsvpUserIds: ['u3', 'u1'],
        attendeeUserIds: const [],
      ),
      Event(
        id: 'e9',
        title: 'Campus Startup Bootcamp',
        description:
            'A weekend intensive covering idea validation, lean business models, '
            'and pitch fundamentals — capped with a demo session in front of local '
            'investors. Open to all years.',
        category: EventCategory.startup,
        posterId: 'u5',
        posterName: 'Fatima Yusuf',
        posterVerifiedOrg: 'Founders Hub',
        dateTime: at(-3, 9, 0),
        location: 'Innovation Hub, Main Hall',
        imageColor: AppColors.accentPalette[2],
        checkInCode: 'BOOT9Z',
        rsvpUserIds: ['u1'],
        attendeeUserIds: const ['u1'],
      ),
      Event(
        id: 'e10',
        title: 'Intro to UI/UX Design Workshop',
        description:
            'Get hands-on with Figma fundamentals: wireframes, components, and a '
            'simple prototype you can show in your portfolio by the end of the day. '
            'No design background required.',
        category: EventCategory.workshop,
        posterId: 'u2',
        posterName: 'David Okafor',
        posterVerifiedOrg: 'Robotics Club',
        dateTime: at(4, 13, 0),
        location: 'Design Studio',
        imageColor: AppColors.accentPalette[4],
        checkInCode: 'UIUX10',
        rsvpUserIds: const [],
        attendeeUserIds: const [],
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Communities (topic-based chat spaces)
  // ---------------------------------------------------------------------

  static const List<Community> communities = [
    Community(
      id: 'c1',
      name: 'Robotics Club',
      description: 'Builders, tinkerers, and competition crews.',
      icon: Icons.precision_manufacturing_outlined,
      color: AppColors.secondary,
      memberCount: 48,
    ),
    Community(
      id: 'c2',
      name: 'Founders Hub',
      description: 'For students building their own ventures.',
      icon: Icons.rocket_launch_outlined,
      color: AppColors.primary,
      memberCount: 76,
    ),
    Community(
      id: 'c3',
      name: 'Academic Success Team',
      description: 'Study groups, internship prep, and peer mentoring.',
      icon: Icons.school_outlined,
      color: AppColors.verified,
      memberCount: 112,
    ),
    Community(
      id: 'c4',
      name: 'Women in Tech',
      description: 'A community for women in tech and their allies.',
      icon: Icons.diversity_3_outlined,
      color: Color(0xFFE8A33D),
      memberCount: 64,
    ),
  ];

  // ---------------------------------------------------------------------
  // Seed chat messages — keyed by spaceId (community id or event id)
  // ---------------------------------------------------------------------

  static List<Message> messages() {
    final now = DateTime.now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

    return [
      // Robotics Club community chat
      Message(
        id: 'm1',
        spaceId: 'c1',
        senderId: 'u2',
        senderName: 'David Okafor',
        text: 'Reminder: demo day run-through is this Thursday at 5pm in Lab A.',
        timestamp: ago(180),
      ),
      Message(
        id: 'm2',
        spaceId: 'c1',
        senderId: 'u6',
        senderName: 'Brian Tumusiime',
        text: 'Will the line follower be ready by then? Last I checked it kept drifting left 😅',
        timestamp: ago(160),
      ),
      Message(
        id: 'm3',
        spaceId: 'c1',
        senderId: 'u2',
        senderName: 'David Okafor',
        text: 'Recalibrated the sensors last night, should be solid now. Bring your laptop if you can.',
        timestamp: ago(140),
      ),

      // Founders Hub community chat
      Message(
        id: 'm4',
        spaceId: 'c2',
        senderId: 'u5',
        senderName: 'Fatima Yusuf',
        text: 'Pitch night sign-ups close Friday at noon — get your slides in early so we can give feedback.',
        timestamp: ago(220),
      ),
      Message(
        id: 'm5',
        spaceId: 'c2',
        senderId: 'u1',
        senderName: 'Amara Chen',
        text: 'Just submitted mine! Nervous but excited 🚀',
        timestamp: ago(200),
      ),

      // Academic Success Team community chat
      Message(
        id: 'm6',
        spaceId: 'c3',
        senderId: 'u4',
        senderName: 'Samuel Diallo',
        text: 'CV clinic slots are filling up fast — book yours this week if you want a review before applications open.',
        timestamp: ago(300),
      ),
      Message(
        id: 'm7',
        spaceId: 'c3',
        senderId: 'u3',
        senderName: 'Grace Mwangi',
        text: 'Booked mine for Tuesday. Does anyone have notes from last term\'s mock interviews?',
        timestamp: ago(260),
      ),

      // Women in Tech community chat
      Message(
        id: 'm8',
        spaceId: 'c4',
        senderId: 'u5',
        senderName: 'Fatima Yusuf',
        text: 'Lightning talk speakers for the mixer are confirmed — three students and one alumna joining remotely.',
        timestamp: ago(90),
      ),
      Message(
        id: 'm9',
        spaceId: 'c4',
        senderId: 'u3',
        senderName: 'Grace Mwangi',
        text: 'Can\'t wait! Is there a sign-up sheet for lightning talk slots still open?',
        timestamp: ago(70),
      ),

      // Event chat — Founders' Friday Pitch Night
      Message(
        id: 'm10',
        spaceId: 'e1',
        senderId: 'u1',
        senderName: 'Amara Chen',
        text: 'Anyone know if we can bring a co-presenter on stage?',
        timestamp: ago(50),
      ),
      Message(
        id: 'm11',
        spaceId: 'e1',
        senderId: 'u5',
        senderName: 'Fatima Yusuf',
        text: 'Yes — up to two people per pitch. Just let me know your team size in advance.',
        timestamp: ago(40),
      ),
    ];
  }
}
