/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: admin_permission.dart
/// Purpose: Declares `AdminPermission` (a tab an admin may open) and
///          `AdminAction` (what they may DO inside that tab). Both are
///          stored as strings in the `permissions` list on `users/{uid}`;
///          firestore.rules checks the same strings.
///
///            'videos'          → the Videos tab
///            'videos.delete'   → may delete videos inside it
///            'v2'              → this admin was saved with sub-permissions
///
/// LEGACY ADMINS (saved before sub-permissions, no 'v2' in the list) keep
/// every action of the tabs they have, and Engagement follows their Videos
/// permission (its Partners follow Website) — exactly as before. Saving
/// them once in Settings → Admins turns them into v2 admins.
/// Author: ASEC team
/// Created: 25/9/2026
/// Updated: 20/10/2026 - sub-permissions per tab, new Engagement tab.
///
/// The SUPER admin (AppConstants.adminEmail) has every permission and is the
/// only one who can create admins, change their permissions, use the
/// control centre and the demo data.

import 'package:flutter/material.dart';

import 'package:asec/generated/l10n.dart';

enum AdminPermission {
  dashboard('dashboard', Icons.insights_rounded),
  videos('videos', Icons.video_library_rounded),
  quizzes('quizzes', Icons.quiz_outlined),
  results('results', Icons.insights_outlined),
  members('members', Icons.groups_2_rounded),
  cvs('cvs', Icons.assignment_outlined),

  /// Notifications, tips, the library, stars and partners.
  engagement('engagement', Icons.campaign_rounded),

  /// Opens the asecbim website control panel — the "Website" drawer tab
  /// (lib/features/web) and /admin on the site. Checked by firestore.rules
  /// `can('website')` on every site_* collection.
  website('website', Icons.language_rounded);

  const AdminPermission(this.key, this.icon);

  final String key;
  final IconData icon;

  /// The actions inside this tab (empty = the tab is view-only).
  List<AdminAction> get actions => <AdminAction>[
        for (final AdminAction a in AdminAction.values)
          if (a.module == this) a,
      ];

  static List<AdminPermission> fromKeys(Iterable<String> keys) => <AdminPermission>[
        for (final AdminPermission p in AdminPermission.values)
          if (keys.contains(p.key)) p,
      ];

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AdminPermission.dashboard:
        return s.dashboard;
      case AdminPermission.videos:
        return s.permVideos;
      case AdminPermission.quizzes:
        return s.permQuizzes;
      case AdminPermission.results:
        return s.permResults;
      case AdminPermission.members:
        return s.permMembers;
      case AdminPermission.cvs:
        return s.permCvs;
      case AdminPermission.engagement:
        return s.permEngagement;
      case AdminPermission.website:
        return s.permWebsite;
    }
  }
}

/// One thing an admin may do inside a tab. Key = '<tab>.<action>'.
enum AdminAction {
  dashboardCharts(AdminPermission.dashboard, 'charts'),
  dashboardTable(AdminPermission.dashboard, 'table'),

  videosAdd(AdminPermission.videos, 'add'),
  videosEdit(AdminPermission.videos, 'edit'),
  videosDelete(AdminPermission.videos, 'delete'),
  videosPublish(AdminPermission.videos, 'publish'),
  videosAccess(AdminPermission.videos, 'access'),

  quizzesCreate(AdminPermission.quizzes, 'create'),
  quizzesEdit(AdminPermission.quizzes, 'edit'),
  quizzesDelete(AdminPermission.quizzes, 'delete'),
  quizzesOpen(AdminPermission.quizzes, 'open'),
  quizzesCertificates(AdminPermission.quizzes, 'certificates'),

  membersBlock(AdminPermission.members, 'block'),
  membersAccess(AdminPermission.members, 'access'),
  membersDevice(AdminPermission.members, 'device'),

  cvsReview(AdminPermission.cvs, 'review'),
  cvsDelete(AdminPermission.cvs, 'delete'),
  cvsGrant(AdminPermission.cvs, 'grant'),

  engagementNotifications(AdminPermission.engagement, 'notifications'),
  engagementTips(AdminPermission.engagement, 'tips'),
  engagementLibrary(AdminPermission.engagement, 'library'),
  engagementStars(AdminPermission.engagement, 'stars'),
  engagementPartners(AdminPermission.engagement, 'partners'),
  // 03/11/2026: answer members' questions (home page Q&A).
  engagementQuestions(AdminPermission.engagement, 'questions'),

  websiteContent(AdminPermission.website, 'content'),
  websiteInbox(AdminPermission.website, 'inbox'),
  websiteSettings(AdminPermission.website, 'settings');

  const AdminAction(this.module, this.id);

  final AdminPermission module;
  final String id;

  String get key => '${module.key}.$id';

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AdminAction.dashboardCharts:
        return s.permDashboardCharts;
      case AdminAction.dashboardTable:
        return s.permDashboardTable;
      case AdminAction.videosAdd:
        return s.permVideosAdd;
      case AdminAction.videosEdit:
        return s.permVideosEdit;
      case AdminAction.videosDelete:
        return s.permVideosDelete;
      case AdminAction.videosPublish:
        return s.permVideosPublish;
      case AdminAction.videosAccess:
        return s.permVideosAccess;
      case AdminAction.quizzesCreate:
        return s.permQuizzesCreate;
      case AdminAction.quizzesEdit:
        return s.permQuizzesEdit;
      case AdminAction.quizzesDelete:
        return s.permQuizzesDelete;
      case AdminAction.quizzesOpen:
        return s.permQuizzesOpen;
      case AdminAction.quizzesCertificates:
        return s.permQuizzesCertificates;
      case AdminAction.membersBlock:
        return s.permMembersBlock;
      case AdminAction.membersAccess:
        return s.permMembersAccess;
      case AdminAction.membersDevice:
        return s.permMembersDevice;
      case AdminAction.cvsReview:
        return s.permCvsReview;
      case AdminAction.cvsDelete:
        return s.permCvsDelete;
      case AdminAction.cvsGrant:
        return s.permCvsGrant;
      case AdminAction.engagementNotifications:
        return s.permEngNotifications;
      case AdminAction.engagementTips:
        return s.permEngTips;
      case AdminAction.engagementLibrary:
        return s.permEngLibrary;
      case AdminAction.engagementStars:
        return s.permEngStars;
      case AdminAction.engagementPartners:
        return s.permEngPartners;
      case AdminAction.engagementQuestions:
        return s.permEngQuestions;
      case AdminAction.websiteContent:
        return s.permWebContent;
      case AdminAction.websiteInbox:
        return s.permWebInbox;
      case AdminAction.websiteSettings:
        return s.permWebSettings;
    }
  }
}

/// The rules shared by the app and the website panel — keep in step with
/// firestore.rules `can()` / `canDo()`.
abstract final class AdminPerms {
  const AdminPerms._();

  /// In the list = saved with sub-permissions.
  static const String v2Marker = 'v2';

  static bool isLegacy(Set<String> keys) => !keys.contains(v2Marker);

  /// May open [p]'s tab.
  static bool can(Set<String> keys, AdminPermission p) {
    if (keys.contains(p.key)) return true;
    // Legacy: Engagement came with Videos (and its Partners with Website).
    return p == AdminPermission.engagement &&
        isLegacy(keys) &&
        (keys.contains(AdminPermission.videos.key) ||
            keys.contains(AdminPermission.website.key));
  }

  /// May do [a].
  static bool canDo(Set<String> keys, AdminAction a) {
    if (isLegacy(keys)) {
      if (a.module == AdminPermission.engagement) {
        return keys.contains(a == AdminAction.engagementPartners
            ? AdminPermission.website.key
            : AdminPermission.videos.key);
      }
      return keys.contains(a.module.key);
    }
    return keys.contains(a.module.key) && keys.contains(a.key);
  }

  /// A legacy list written out as the v2 list that means the same.
  static Set<String> upgrade(Set<String> keys) {
    if (!isLegacy(keys)) return keys;
    return <String>{
      v2Marker,
      for (final AdminPermission p in AdminPermission.values)
        if (can(keys, p)) p.key,
      for (final AdminAction a in AdminAction.values)
        if (canDo(keys, a)) a.key,
    };
  }

  /// Every tab and every action — what a new admin starts from when a tab
  /// is ticked.
  static Set<String> fullTab(AdminPermission p) =>
      <String>{p.key, for (final AdminAction a in p.actions) a.key};
}
