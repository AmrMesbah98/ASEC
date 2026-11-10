/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_options.dart
/// Purpose: Declares `CvOptions` — every closed list a CV field picks from.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// The lists are ENGX's, field for field, so a CV written here holds the same
/// data an ENGX CV does. Only the wording of the UI around them is ours.
///
/// WHY CLOSED LISTS AT ALL: free text in `specialization` gives you "Civil",
/// "civil eng.", "Civil Engineering" and a directory nobody can filter. A
/// fixed list is what makes the CV browsable.

abstract final class CvOptions {
  const CvOptions._();

  static const List<String> governorates = <String>[
    'Cairo', 'Giza', 'Alexandria', 'Dakahlia', 'Red Sea', 'Beheira',
    'Fayoum', 'Gharbia', 'Ismailia', 'Menofia', 'Minya', 'Qalyubia',
    'New Valley', 'North Sinai', 'Port Said', 'Sharqia', 'South Sinai',
    'Suez', 'Aswan', 'Assiut', 'Beni Suef', 'Kafr El Sheikh', 'Luxor',
    'Matruh', 'Qena', 'Sohag',
  ];

  static const List<String> militaryStatus = <String>[
    'Exempted',
    'Completed',
    'Postponed',
    'Not Applicable',
  ];

  /// 2015 up to and including the current year, newest first — the year a
  /// list like this is scrolled to most often is the recent end.
  static List<String> graduationYears() {
    final int thisYear = DateTime.now().year;
    return <String>[
      for (int y = thisYear; y >= 2015; y--) '$y',
    ];
  }

  /// ASEC is a mechanical academy, so Mechanical Engineering is the only
  /// specialization and every new CV starts with it already picked.
  static const String defaultSpecialization = 'Mechanical Engineering';

  static const List<String> specializations = <String>[
    defaultSpecialization,
  ];

  /// The three positions the CV directory is split into, in the order its
  /// tabs show them (Eng. Ahmed Shuhayb's review, 9 Nov 2026).
  static const List<String> roles = <String>[
    'Site Engineer',
    'Technical Office Engineer',
    'Design Engineer',
  ];

  static const List<String> languages = <String>[
    'Arabic',
    'English',
    'French',
  ];

  /// 09/11/2026: these six.
  static const List<String> softSkills = <String>[
    'Communication Skills',
    'Teamwork',
    'Time Management',
    'Problem Solving',
    'Leadership',
    'Critical Thinking',
  ];

  /// 09/11/2026: ONE list of professional skills for every role — only
  /// these.
  static const List<String> proSkills = <String>[
    'AutoCAD',
    'Revit',
    'Shop Drawings',
    'BOQ',
    'MS Office',
    'HVAC Design',
    'Plumbing Design',
    'Fire Fighting Design',
    'Navisworks',
    'Coordination',
  ];

  /// The skills to offer — the same for every role (kept as a function so
  /// the form and the cubit need no change).
  static List<String> skillsFor(String role) => proSkills;
}
