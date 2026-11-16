/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_seed.dart
/// Purpose: Declares `DemoSeed` — the sample content the demo button writes.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// WHY A DATA FILE AND NOT A LOOP THAT GENERATES NOISE:
/// random names and random scores fill the screens, but they do not TEST
/// them. A hand-written set can aim at the cases a screenshot never shows by
/// accident — a member who is switched off, a quiz that has already closed, a
/// draft that must stay hidden from members, an attempt that ran out of time,
/// a CV that was rejected. Everything below is chosen so that every branch of
/// every view has something to draw.
///
/// Nothing here is written as-is: the seeder stamps `demo: true` on every
/// document it makes, and that flag is what the remove button deletes by.

/// One demo member. [slug] is the internal handle the quizzes, attempts and
/// CVs below refer to — it never reaches Firestore.
class DemoMember {
  final String slug;
  final String fullName;
  final String email;
  final String phone;
  final bool active;
  final bool canCreateCv;

  /// How far back `created_at` is dated, so "member since" and the dashboard's
  /// growth chart are not all one day.
  final int joinedDaysAgo;

  const DemoMember({
    required this.slug,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.joinedDaysAgo,
    this.active = true,
    this.canCreateCv = false,
  });
}

class DemoVideo {
  final String slug;
  final String title;
  final String description;

  /// A public sample file. The demo writes NO Cloud Storage object, so the
  /// `storage_path` stays empty and deleting a demo video deletes only the
  /// Firestore document.
  final String url;

  final bool published;
  final int sizeBytes;
  final int addedDaysAgo;

  const DemoVideo({
    required this.slug,
    required this.title,
    required this.description,
    required this.url,
    required this.sizeBytes,
    required this.addedDaysAgo,
    this.published = true,
  });
}

class DemoQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  final int points;

  const DemoQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    this.points = 1,
  });
}

class DemoQuiz {
  final String slug;
  final String title;
  final String description;

  /// Zero means untimed.
  final int durationMinutes;

  /// Relative to "now", in hours. Null on either side means no bound that way.
  /// Negative is the past: `opensInHours: -48` opened two days ago.
  final int? opensInHours;
  final int? closesInHours;

  final bool published;
  final int addedDaysAgo;
  final List<DemoQuestion> questions;

  const DemoQuiz({
    required this.slug,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.addedDaysAgo,
    required this.questions,
    this.opensInHours,
    this.closesInHours,
    this.published = true,
  });
}

/// One sitting. [choices] is index-for-index with the quiz's questions, and
/// `-1` is a question that was left blank — the results screen shows blanks
/// apart from wrong answers, so at least one attempt has to have some.
class DemoAttempt {
  final String memberSlug;
  final String quizSlug;
  final List<int> choices;
  final int startedHoursAgo;
  final int tookMinutes;
  final bool autoSubmitted;

  const DemoAttempt({
    required this.memberSlug,
    required this.quizSlug,
    required this.choices,
    required this.startedHoursAgo,
    required this.tookMinutes,
    this.autoSubmitted = false,
  });
}

class DemoCv {
  final String memberSlug;
  final String location;
  final String militaryStatus;
  final String graduationYear;
  final String specialization;
  final String role;
  final List<String> proSkills;
  final List<String> softSkills;
  final List<String> languages;
  final String bio;
  final String facebookLink;
  final String linkedinLink;
  final String portfolioLink;

  /// The attached CV document. A public sample PDF — the demo uploads nothing
  /// to Cloud Storage, so the path stays empty and removing a demo CV removes
  /// only its document.
  final String cvFileUrl;
  final String cvFileName;
  final int cvFileSize;

  /// A `CvStatus` key: Pending, Approved or Rejected.
  final String statusKey;

  const DemoCv({
    required this.memberSlug,
    required this.location,
    required this.militaryStatus,
    required this.graduationYear,
    required this.specialization,
    required this.role,
    required this.proSkills,
    required this.softSkills,
    required this.languages,
    required this.bio,
    required this.statusKey,
    this.facebookLink = '',
    this.linkedinLink = '',
    this.portfolioLink = '',
    this.cvFileUrl = '',
    this.cvFileName = '',
    this.cvFileSize = 0,
  });
}

abstract final class DemoSeed {
  const DemoSeed._();

  /// Every demo account signs in with this. It is deliberately printed in the
  /// UI: these accounts hold nothing, and being able to sign in AS a member is
  /// the only way to see the member side of the app without leaving the admin
  /// account.
  static const String password = 'Asec12345';

  /// A real, permanently hosted PDF, so the download button on a demo CV
  /// actually downloads something. Two of the four demo CVs carry it and two
  /// do not — a CV with no file attached is a case the directory has to show
  /// as well.
  static const String _samplePdf =
      'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/'
      'compressed.tracemonkey-pldi-09.pdf';

  /// A domain nobody can receive mail at, so a demo account can never be
  /// mistaken for a real one and no password reset ever reaches anybody.
  static const String emailDomain = 'demo.asec.app';

  /// The member shown in the "demo data is ready" message.
  static String get sampleEmail => members.first.email;

  static const List<DemoMember> members = <DemoMember>[
    DemoMember(
      slug: 'sara',
      fullName: 'Sara Hassan',
      email: 'sara@demo.asec.app',
      phone: '01001234567',
      joinedDaysAgo: 96,
      canCreateCv: true,
    ),
    DemoMember(
      slug: 'omar',
      fullName: 'Omar Khaled',
      email: 'omar@demo.asec.app',
      phone: '01112345678',
      joinedDaysAgo: 74,
      canCreateCv: true,
    ),
    DemoMember(
      slug: 'mona',
      fullName: 'Mona Adel',
      email: 'mona@demo.asec.app',
      phone: '01223456789',
      joinedDaysAgo: 51,
      canCreateCv: true,
    ),
    DemoMember(
      slug: 'youssef',
      fullName: 'Youssef Ali',
      email: 'youssef@demo.asec.app',
      phone: '01034567890',
      joinedDaysAgo: 33,
      canCreateCv: true,
    ),
    // Active, but the CV form is still closed for him — the members table has
    // to show both sides of that dropdown.
    DemoMember(
      slug: 'nour',
      fullName: 'Nour Ibrahim',
      email: 'nour@demo.asec.app',
      phone: '01145678901',
      joinedDaysAgo: 19,
    ),
    // Switched off. He still appears in the table, greyed, and the "Inactive"
    // filter would be empty without him.
    DemoMember(
      slug: 'kareem',
      fullName: 'Kareem Samir',
      email: 'kareem@demo.asec.app',
      phone: '01256789012',
      joinedDaysAgo: 8,
      active: false,
    ),
  ];

  static const List<DemoVideo> videos = <DemoVideo>[
    DemoVideo(
      slug: 'safety',
      title: 'Site safety induction',
      description:
          'What every engineer does in their first hour on a site: the walk, '
          'the permits, the personal protective equipment and who to report to.',
      url:
          'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4',
      sizeBytes: 1978137,
      addedDaysAgo: 41,
    ),
    DemoVideo(
      slug: 'boq',
      title: 'Reading a BOQ line by line',
      description:
          'A bill of quantities is a contract, not a spreadsheet. This lesson '
          'takes one page apart: item, unit, quantity, rate and what each of '
          'them binds you to.',
      url:
          'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_2MB.mp4',
      sizeBytes: 2096842,
      addedDaysAgo: 27,
    ),
    DemoVideo(
      slug: 'shopdrawings',
      title: 'Shop drawings that come back approved',
      description:
          'The four things a consultant checks first, and the comments you can '
          'answer before they are ever written.',
      url:
          'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4',
      sizeBytes: 2094185,
      addedDaysAgo: 14,
    ),
    DemoVideo(
      slug: 'primavera',
      title: 'Primavera P6: your first baseline',
      description:
          'Activities, relationships, calendars and the one mistake that makes '
          'every later update lie to you.',
      url:
          'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_10MB.mp4',
      sizeBytes: 10218838,
      addedDaysAgo: 6,
    ),
    DemoVideo(
      slug: 'concrete',
      title: 'Concrete pouring and curing',
      description:
          'Slump test, vibration, cold joints and the seven days after the '
          'pour that decide how strong the slab really is.',
      url:
          'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4',
      sizeBytes: 1047967,
      addedDaysAgo: 38,
    ),
    DemoVideo(
      slug: 'rebar',
      title: 'Checking rebar before the pour',
      description:
          'Cover, spacing, laps and chairs: the inspection you sign for, and '
          'the photos that prove you did it.',
      url:
          'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4',
      sizeBytes: 1047954,
      addedDaysAgo: 33,
    ),
    DemoVideo(
      slug: 'surveying',
      title: 'Site surveying and setting out',
      description:
          'Benchmarks, grid lines and levels — how a building gets from the '
          'drawing onto the ground in the right place.',
      url:
          'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_5MB.mp4',
      sizeBytes: 4999379,
      addedDaysAgo: 21,
    ),
    DemoVideo(
      slug: 'variations',
      title: 'Variation orders without the argument',
      description:
          'What counts as a variation, how to price it, and the notice letter '
          'that protects your entitlement to time and money.',
      url:
          'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_5MB.mp4',
      sizeBytes: 5241877,
      addedDaysAgo: 17,
    ),
    DemoVideo(
      slug: 'qaqc',
      title: 'QA/QC: inspection requests that pass',
      description:
          'Writing an inspection request, the checklist the consultant uses, '
          'and closing a non-conformance report properly.',
      url:
          'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_5MB.mp4',
      sizeBytes: 5242780,
      addedDaysAgo: 10,
    ),
    DemoVideo(
      slug: 'reporting',
      title: 'Daily and weekly site reports',
      description:
          'Manpower, equipment, progress and delays — a report the project '
          'manager can read in two minutes and trust.',
      url:
          'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_10MB.mp4',
      sizeBytes: 10485794,
      addedDaysAgo: 4,
    ),
    // Unpublished on purpose: members must NOT see this one, and the admin's
    // list must show it as a draft.
    DemoVideo(
      slug: 'interview',
      title: 'Interview preparation (draft)',
      description:
          'Not finished yet — it is here so the admin list has a draft in it '
          'and the member list can be checked for hiding it.',
      url:
          'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
      sizeBytes: 969201,
      addedDaysAgo: 2,
      published: false,
    ),
  ];

  static const List<DemoQuiz> quizzes = <DemoQuiz>[
    DemoQuiz(
      slug: 'safety',
      title: 'Site safety basics',
      description: 'Five questions on the induction lesson. Twenty minutes.',
      durationMinutes: 20,
      addedDaysAgo: 40,
      questions: <DemoQuestion>[
        DemoQuestion(
          text: 'What is the first thing you do when you reach a new site?',
          options: <String>[
            'Start measuring the work',
            'Report to the site office and sign in',
            'Take photographs of the progress',
            'Call the consultant',
          ],
          correctIndex: 1,
        ),
        DemoQuestion(
          text: 'A permit to work is required before:',
          options: <String>[
            'Any hot work such as welding or cutting',
            'Entering the site canteen',
            'Reading the drawings',
            'Sending the daily report',
          ],
          correctIndex: 0,
        ),
        DemoQuestion(
          text: 'Which of these is NOT personal protective equipment?',
          options: <String>[
            'Safety helmet',
            'High-visibility vest',
            'Total station',
            'Safety boots',
          ],
          correctIndex: 2,
          points: 2,
        ),
        DemoQuestion(
          text: 'Scaffolding may be used when:',
          options: <String>[
            'It looks stable enough',
            'The foreman says so',
            'It carries a valid green inspection tag',
            'It was inspected last month',
          ],
          correctIndex: 2,
        ),
        DemoQuestion(
          text: 'A near miss should be:',
          options: <String>[
            'Ignored — nobody was hurt',
            'Reported the same day',
            'Reported only if it happens twice',
            'Discussed at the end of the project',
          ],
          correctIndex: 1,
        ),
      ],
    ),
    DemoQuiz(
      slug: 'boq',
      title: 'Quantities and BOQ',
      description:
          'Open for a week. Thirty minutes once you start, and the closing '
          'time still cuts the countdown short.',
      durationMinutes: 30,
      opensInHours: -72,
      closesInHours: 96,
      addedDaysAgo: 26,
      questions: <DemoQuestion>[
        DemoQuestion(
          text: 'In a BOQ, the RATE is:',
          options: <String>[
            'The total cost of the item',
            'The price of one unit of the item',
            'The contractor profit',
            'The quantity measured on site',
          ],
          correctIndex: 1,
        ),
        DemoQuestion(
          text: 'Concrete in a BOQ is normally measured in:',
          options: <String>['m', 'm2', 'm3', 'ton'],
          correctIndex: 2,
        ),
        DemoQuestion(
          text: 'A provisional sum is:',
          options: <String>[
            'An amount kept for work not yet fully defined',
            'The retention held from every invoice',
            'The contractor overhead',
            'A penalty for late delivery',
          ],
          correctIndex: 0,
          points: 2,
        ),
        DemoQuestion(
          text: 'Steel reinforcement is usually billed by:',
          options: <String>['Length', 'Weight', 'Area', 'Number of bars'],
          correctIndex: 1,
        ),
      ],
    ),
    DemoQuiz(
      slug: 'office',
      title: 'Technical office essentials',
      description:
          'No countdown and no closing date — take it whenever you like.',
      durationMinutes: 0,
      addedDaysAgo: 18,
      questions: <DemoQuestion>[
        DemoQuestion(
          text: 'An RFI is raised when:',
          options: <String>[
            'The drawings are unclear or contradict each other',
            'A payment is late',
            'A worker is absent',
            'The site is closed for a holiday',
          ],
          correctIndex: 0,
        ),
        DemoQuestion(
          text: 'As-built drawings record:',
          options: <String>[
            'What was designed',
            'What was tendered',
            'What was actually executed',
            'What was budgeted',
          ],
          correctIndex: 2,
        ),
        DemoQuestion(
          text: 'A material submittal is approved by:',
          options: <String>[
            'The contractor',
            'The consultant or engineer',
            'The supplier',
            'The safety officer',
          ],
          correctIndex: 1,
        ),
        DemoQuestion(
          text: 'Shop drawings are prepared by:',
          options: <String>[
            'The designer only',
            'The contractor technical office',
            'The client',
            'The government authority',
          ],
          correctIndex: 1,
        ),
      ],
    ),
    // Already closed: members must see it as finished, and an attempt on it
    // must still show in the results.
    DemoQuiz(
      slug: 'tender',
      title: 'Tendering and contracts (closed)',
      description:
          'This one closed yesterday. It is here so a finished quiz can be '
          'seen in both lists.',
      durationMinutes: 15,
      opensInHours: -240,
      closesInHours: -24,
      addedDaysAgo: 11,
      questions: <DemoQuestion>[
        DemoQuestion(
          text: 'A bid bond guarantees that:',
          options: <String>[
            'The bidder will not withdraw before award',
            'The work will finish on time',
            'The materials are of good quality',
            'The workers are insured',
          ],
          correctIndex: 0,
        ),
        DemoQuestion(
          text: 'In a lump sum contract, the risk of quantity variation is:',
          options: <String>[
            'On the client',
            'On the contractor',
            'Shared equally',
            'On the consultant',
          ],
          correctIndex: 1,
          points: 2,
        ),
        DemoQuestion(
          text: 'Value engineering aims to:',
          options: <String>[
            'Increase the contract price',
            'Keep the function at a lower cost',
            'Delay the programme',
            'Reduce the scope of work',
          ],
          correctIndex: 1,
        ),
      ],
    ),
    // A draft. Members must not see it at all.
    DemoQuiz(
      slug: 'draft',
      title: 'Procurement (draft — not published)',
      description:
          'Written but not published. The member list must not show it; the '
          'admin list must show it as a draft.',
      durationMinutes: 25,
      addedDaysAgo: 3,
      published: false,
      questions: <DemoQuestion>[
        DemoQuestion(
          text: 'A purchase order becomes binding when:',
          options: <String>[
            'It is printed',
            'It is accepted by the supplier',
            'The material arrives',
            'The invoice is paid',
          ],
          correctIndex: 1,
        ),
        DemoQuestion(
          text: 'Lead time is:',
          options: <String>[
            'The time from order to delivery',
            'The time to unload a truck',
            'The payment period',
            'The warranty period',
          ],
          correctIndex: 0,
        ),
      ],
    ),
  ];

  /// Fourteen sittings. Full marks, a near miss, a poor one, one that ran out
  /// of time, and two with blanks — enough for the dashboard's average and the
  /// results table's every colour.
  static const List<DemoAttempt> attempts = <DemoAttempt>[
    // Site safety basics — five questions.
    DemoAttempt(
      memberSlug: 'sara',
      quizSlug: 'safety',
      choices: <int>[1, 0, 2, 2, 1],
      startedHoursAgo: 210,
      tookMinutes: 12,
    ),
    DemoAttempt(
      memberSlug: 'omar',
      quizSlug: 'safety',
      choices: <int>[1, 0, 2, 3, 1],
      startedHoursAgo: 190,
      tookMinutes: 17,
    ),
    DemoAttempt(
      memberSlug: 'mona',
      quizSlug: 'safety',
      choices: <int>[0, 0, 2, 2, -1],
      startedHoursAgo: 150,
      tookMinutes: 20,
      autoSubmitted: true,
    ),
    DemoAttempt(
      memberSlug: 'youssef',
      quizSlug: 'safety',
      choices: <int>[1, 1, 0, 2, 1],
      startedHoursAgo: 96,
      tookMinutes: 9,
    ),
    DemoAttempt(
      memberSlug: 'nour',
      quizSlug: 'safety',
      choices: <int>[2, 3, 0, 0, 2],
      startedHoursAgo: 72,
      tookMinutes: 6,
    ),
    // Quantities and BOQ — four questions.
    DemoAttempt(
      memberSlug: 'sara',
      quizSlug: 'boq',
      choices: <int>[1, 2, 0, 1],
      startedHoursAgo: 60,
      tookMinutes: 21,
    ),
    DemoAttempt(
      memberSlug: 'omar',
      quizSlug: 'boq',
      choices: <int>[1, 2, 1, 1],
      startedHoursAgo: 52,
      tookMinutes: 30,
      autoSubmitted: true,
    ),
    DemoAttempt(
      memberSlug: 'mona',
      quizSlug: 'boq',
      choices: <int>[1, 2, 0, -1],
      startedHoursAgo: 44,
      tookMinutes: 14,
    ),
    DemoAttempt(
      memberSlug: 'youssef',
      quizSlug: 'boq',
      choices: <int>[0, 1, 3, 2],
      startedHoursAgo: 30,
      tookMinutes: 11,
    ),
    // Technical office essentials — four questions, untimed.
    DemoAttempt(
      memberSlug: 'sara',
      quizSlug: 'office',
      choices: <int>[0, 2, 1, 1],
      startedHoursAgo: 26,
      tookMinutes: 8,
    ),
    DemoAttempt(
      memberSlug: 'omar',
      quizSlug: 'office',
      choices: <int>[0, 2, 1, 0],
      startedHoursAgo: 20,
      tookMinutes: 13,
    ),
    DemoAttempt(
      memberSlug: 'nour',
      quizSlug: 'office',
      choices: <int>[3, 0, 2, 0],
      startedHoursAgo: 14,
      tookMinutes: 5,
    ),
    // Tendering — the closed quiz, three questions.
    DemoAttempt(
      memberSlug: 'sara',
      quizSlug: 'tender',
      choices: <int>[0, 1, 1],
      startedHoursAgo: 40,
      tookMinutes: 10,
    ),
    DemoAttempt(
      memberSlug: 'youssef',
      quizSlug: 'tender',
      choices: <int>[0, 0, 1],
      startedHoursAgo: 36,
      tookMinutes: 15,
      autoSubmitted: true,
    ),
  ];

  /// Four CVs — one per review state, and four different roles so the
  /// directory's skill lists are not all the same.
  static const List<DemoCv> cvs = <DemoCv>[
    DemoCv(
      memberSlug: 'sara',
      location: 'Cairo',
      militaryStatus: 'Not Applicable',
      graduationYear: '2021',
      specialization: 'Civil Engineering',
      role: 'Technical Office Engineer',
      proSkills: <String>[
        'AutoCAD',
        'Revit',
        'Shop Drawings',
        'Quantity Surveying',
        'Technical Submittals',
        'MS Office',
      ],
      softSkills: <String>[
        'Attention to Detail',
        'Time Management',
        'Teamwork',
      ],
      languages: <String>['Arabic', 'English'],
      bio:
          'Technical office engineer with three years on residential and '
          'commercial towers. I prepare shop drawings and submittals, and I '
          'have taken a project from foundation drawings to as-built.',
      statusKey: 'Approved',
      linkedinLink: 'https://www.linkedin.com/in/demo-sara-hassan',
      cvFileUrl: _samplePdf,
      cvFileName: 'Sara-Hassan-CV.pdf',
      cvFileSize: 1016315,
    ),
    DemoCv(
      memberSlug: 'omar',
      location: 'Giza',
      militaryStatus: 'Completed',
      graduationYear: '2019',
      specialization: 'Civil Engineering',
      role: 'Site Engineer',
      proSkills: <String>[
        'Site Supervision',
        'Quality Control',
        'Setting Out',
        'Daily Reports',
        'Subcontractor Management',
        'Safety Management',
      ],
      softSkills: <String>[
        'Work Under Pressure',
        'Responsibility',
        'Problem Solving',
        'Communication Skills',
      ],
      languages: <String>['Arabic', 'English'],
      bio:
          'Site engineer on infrastructure and industrial projects. Used to '
          'running a shift, keeping the setting out honest and closing the '
          'day with a report the consultant can actually read.',
      statusKey: 'Pending',
      facebookLink: 'https://www.facebook.com/demo.omar.khaled',
      linkedinLink: 'https://www.linkedin.com/in/demo-omar-khaled',
      cvFileUrl: _samplePdf,
      cvFileName: 'Omar-Khaled-CV.pdf',
      cvFileSize: 842104,
    ),
    DemoCv(
      memberSlug: 'mona',
      location: 'Alexandria',
      militaryStatus: 'Not Applicable',
      graduationYear: '2023',
      specialization: 'Architecture Engineering',
      role: 'Sales Engineer',
      proSkills: <String>[
        'Technical Sales',
        'Client Relationship Management',
        'Presentations',
        'Proposal Writing',
        'CRM Software',
      ],
      softSkills: <String>[
        'Communication Skills',
        'Adaptability',
        'Self-Learning',
      ],
      languages: <String>['Arabic', 'English', 'French'],
      bio:
          'Architecture graduate who moved to technical sales for finishing '
          'materials. I am the person who can read the drawing and quote it in '
          'the same meeting.',
      statusKey: 'Pending',
      portfolioLink: 'https://www.behance.net/demo-mona-adel',
    ),
    DemoCv(
      memberSlug: 'youssef',
      location: 'Dakahlia',
      militaryStatus: 'Postponed',
      graduationYear: '2025',
      specialization: 'Mechanical Engineering',
      role: 'Procurement Engineer',
      proSkills: <String>[
        'Procurement Management',
        'Vendor Management',
        'Material Sourcing',
        'Negotiation',
        'MS Office',
      ],
      softSkills: <String>['Teamwork', 'Time Management'],
      languages: <String>['Arabic', 'English'],
      bio:
          'Fresh mechanical graduate, six months in a procurement department. '
          'Comfortable with sourcing, comparisons and chasing a delivery that '
          'is late.',
      statusKey: 'Rejected',
      linkedinLink: 'https://www.linkedin.com/in/demo-youssef-ali',
    ),
  ];
}
