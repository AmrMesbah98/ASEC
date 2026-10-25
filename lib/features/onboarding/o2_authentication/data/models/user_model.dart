/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: user_model.dart
/// Purpose: Declares `UserModel` — the `users/{uid}` document shape.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/course_access.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

/// Field names here MUST match the `onlyKeys` lists in firestore.rules — a
/// client that writes `full_name` against rules expecting `name` has every
/// save refused, and the error says nothing useful.
abstract final class UserModel {
  const UserModel._();

  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String permissions = 'permissions';

  // Member access — written by an admin with the 'members' permission.
  static const String coursesAll = 'courses_all';
  static const String courses = 'courses';

  /// Default courses (MemberAccess.defaultCourses) the admin switched OFF
  /// for this member. Every other default course is open to everyone.
  static const String closedCourses = 'closed_courses';
  static const String platforms = 'platforms';
  static const String courseAccess = 'course_access';
  static const String accessFrom = 'access_from';
  static const String accessUntil = 'access_until';
  static const String pausedAt = 'paused_at';
  static const String deviceId = 'device_id';
  static const String deviceName = 'device_name';
  static const String deviceBoundAt = 'device_bound_at';

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;
    final Set<String> keys = <String>{
      ...(doc.data()?[permissions] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>(),
    };

    return AppUser(
      uid: doc.id,
      email: data.str(email),
      fullName: data.str(fullName),
      phone: data.str(phone),
      role: UserRole.fromKey(data.str(FirebaseCollections.roleField)),
      active: data.boolean(FirebaseCollections.activeField, true),
      canCreateCv: data.boolean(FirebaseCollections.canCreateCvField),
      canUseCalcs: data.boolean(FirebaseCollections.canUseCalcsField),
      createdAt: data.date(FirebaseCollections.createdAtField),
      // THE DEFAULT COURSES (GENERAL NOTES, Reals = Tips & Tricks) are open
      // to every member, on top of the courses the admin gave them, until
      // the admin switches one off for that member (`closed_courses`).
      allCourses: data.boolean(coursesAll, false),
      courses: <String>{
        ...data.stringList(courses),
        for (final String c in MemberAccess.defaultCourses)
          if (!data.stringList(closedCourses).contains(c)) c,
      }.toList(),
      platforms: data.stringList(platforms),
      courseAccess: <String, CourseAccess>{
        for (final MapEntry<String, dynamic> e in data.nested(courseAccess).entries)
          e.key.trim(): CourseAccess.fromMap(e.value),
      },
      accessFrom: data.date(accessFrom),
      accessUntil: data.date(accessUntil),
      pausedAt: data.date(pausedAt),
      deviceId: data.str(deviceId),
      deviceName: data.str(deviceName),
      deviceBoundAt: data.date(deviceBoundAt),
      permissions: <AdminPermission>[
        for (final AdminPermission p in AdminPermission.values)
          if (AdminPerms.can(keys, p)) p,
      ],
      permissionKeys: keys,
    );
  }

  /// A new admin, written by the super admin. The only map that carries
  /// `permissions` — a member's own writes never can (see firestore.rules).
  static Map<String, dynamic> toAdminMap(AppUser admin) => <String, dynamic>{
        email: admin.email.trim().toLowerCase(),
        fullName: admin.fullName.trim(),
        phone: admin.phone.trim(),
        FirebaseCollections.roleField: 'admin',
        FirebaseCollections.activeField: true,
        FirebaseCollections.canCreateCvField: false,
        permissions: admin.permissionKeys.toList(),
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };

  /// The whole profile. Used on register, so no field is ever half-written.
  static Map<String, dynamic> toMap(AppUser user, {bool isCreate = false}) {
    return <String, dynamic>{
      email: user.email.trim().toLowerCase(),
      fullName: user.fullName.trim(),
      phone: user.phone.trim(),
      FirebaseCollections.roleField: user.role.key,
      FirebaseCollections.activeField: user.active,
      FirebaseCollections.canCreateCvField: user.canCreateCv,
      if (isCreate)
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    };
  }

  /// The admin's access settings for one member (not the pause — that has
  /// its own write, so saving the form never un-pauses anybody).
  static Map<String, dynamic> toAccessMap({
    required bool allCourses,
    required List<String> courseList,
    required List<String> platformList,
    required DateTime? from,
    required DateTime? until,
    Map<String, CourseAccess> perCourse = const <String, CourseAccess>{},
  }) =>
      <String, dynamic>{
        coursesAll: allCourses,
        courses: courseList,
        // A default course left unticked is switched off for this member.
        closedCourses: allCourses
            ? const <String>[]
            : <String>[
                for (final String c in MemberAccess.defaultCourses)
                  if (!courseList.contains(c)) c,
              ],
        platforms: platformList,
        courseAccess: <String, dynamic>{
          for (final MapEntry<String, CourseAccess> e in perCourse.entries)
            e.key: e.value.toMap(),
        },
        accessFrom: from == null ? null : Timestamp.fromDate(from),
        accessUntil: until == null ? null : Timestamp.fromDate(until),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };

  /// What a user may change about themselves: name and phone, nothing else.
  /// Not the role — that is the whole point of keeping this map small.
  static Map<String, dynamic> toSelfUpdateMap(AppUser user) =>
      <String, dynamic>{
        fullName: user.fullName.trim(),
        phone: user.phone.trim(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };
}
