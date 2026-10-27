/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: member_access_page.dart
/// Purpose: Declares `MemberAccessPage` — what ONE member may use: which
///          courses, on which devices, for how long, and the pause button.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// Courses are the video categories (Drive sub-folders). Devices are
/// Android, iPhone/iPad, Mac and Windows. The period is permanent or
/// from–to. PAUSE is an immediate action, separate from Save: it locks the
/// member out now, and Resume adds the paused days to the end date.
///
/// The member's app applies all of it live (UserShell → AccessGate), and
/// firestore.rules lets only an admin with the Members permission write
/// these fields.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/23-custom_check_box.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/58-default_switch_button.dart';
import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/admin/a2_members/data/device_security.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/course_access.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/date_time_field.dart';
import 'package:asec/features/video/v1_videos/data/device/video_device_lock.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';
import 'package:asec/features/quiz/q2_certificates/data/issued_certificates.dart';
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_page.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/network/shared_stream.dart';

class MemberAccessPage extends StatefulWidget {
  const MemberAccessPage({super.key, required this.member});

  final AppUser member;

  @override
  State<MemberAccessPage> createState() => _MemberAccessPageState();
}

class _MemberAccessPageState extends State<MemberAccessPage> {
  final UsersBaseRepository _users = UsersRepository();
  late final Stream<AppUser?> _live = shared(() => _users.watchUser(widget.member.uid));
  late final Stream<List<VideoItem>> _videos = shared(() => VideoRepository().watchAll());
  late final Stream<List<VideoItem>> _certVideos = shared(() => VideoRepository().watchAll());
  late final Stream<List<IssuedCertificate>> _issued = shared(() => IssuedCertificates.watchFor(widget.member.uid));
  final Set<String> _issuing = <String>{};

  /// Gives (or takes back) [course]'s certificate right away — not on Save.
  Future<void> _toggleCertificate(String course, bool issued) async {
    final S s = S.of(context);
    setState(() => _issuing.add(course));
    try {
      if (issued) {
        await IssuedCertificates.revoke(widget.member.uid, course);
        if (mounted) _toast(s.certRevoked);
      } else {
        await IssuedCertificates.issue(
          widget.member,
          course,
          adminUid: SessionController.to.current.uid,
        );
        if (mounted) _toast(s.certIssuedToast);
      }
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message(context));
    }
    if (mounted) setState(() => _issuing.remove(course));
  }

  late bool _allCourses = widget.member.allCourses;
  late final Set<String> _courses = widget.member.courses.toSet();
  // DEFAULT: Android and iPhone / iPad only — Mac and Windows only when the
  // admin ticks them.
  late final Set<String> _platforms = widget.member.platforms.isEmpty
      ? MemberAccess.defaultPlatforms.toSet()
      : widget.member.platforms.toSet();

  /// Per course ticked: from–to and platforms. A course ticked for the first
  /// time starts open from now on, with no end, on Android and iPhone only.
  late final Map<String, CourseAccess> _courseAccess =
      Map<String, CourseAccess>.of(widget.member.courseAccess);

  CourseAccess _accessOf(String course) =>
      _courseAccess[course] ?? const CourseAccess();
  late bool _permanent = widget.member.isPermanent;
  late DateTime? _from = widget.member.accessFrom;
  late DateTime? _until = widget.member.accessUntil;

  bool _saving = false;
  bool _pausing = false;
  bool _removingDevice = false;
  late final Stream<List<BlockedDevice>> _blockedDevices = shared(() => DeviceBlocks.watchForMember(widget.member.uid));

  late final Stream<Map<String, VideoDevice>> _videoDevices = shared(() => VideoDeviceLock.watch(widget.member.uid));

  String _deviceLabel(S s, VideoDevice d) =>
      d.name.isEmpty ? s.accessDeviceUnknown : d.name;

  /// BLOCK, not just remove: the device goes on the blocked list (whoever
  /// signs in on it sees "This device is blocked") and its video slot is
  /// freed, so the member can watch on another device of that platform.
  Future<void> _blockVideoDevice(AppUser live, String platform, VideoDevice d) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.accessDeviceBlockQuestion,
      subtitle: s.accessDeviceBlockBody(_deviceLabel(s, d)),
      confirmLabel: s.accessDeviceBlock,
      cancelLabel: s.cancel,
      onConfirm: () async {
        setState(() => _removingDevice = true);
        try {
          await DeviceBlocks.blockVideoDevice(live, platform, d);
          if (mounted) _toast(s.accessDeviceBlocked);
        } catch (e) {
          if (mounted) _toast(AppFailure.from(e).message(context));
        }
        if (mounted) setState(() => _removingDevice = false);
      },
    );
  }

  Future<void> _unblockDevice(BlockedDevice d) async {
    final S s = S.of(context);
    try {
      await DeviceBlocks.unblock(d.deviceId);
      if (mounted) _toast(s.accessDeviceUnblocked);
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message(context));
    }
  }

  /// ONE VIDEO DEVICE PER PLATFORM. Frees [platform]'s slot right away
  /// (not on Save): videos stop on the old device at once, and the next
  /// device of that platform that opens Videos takes the slot.
  Future<void> _removeVideoDevice(String platform, VideoDevice d) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.accessDeviceRemoveQuestion,
      subtitle: s.accessVideoDeviceRemoveBody(
        _deviceLabel(s, d),
        MemberAccess.platformLabel(platform),
      ),
      confirmLabel: s.accessDeviceRemove,
      cancelLabel: s.cancel,
      onConfirm: () async {
        setState(() => _removingDevice = true);
        try {
          await VideoDeviceLock.release(widget.member.uid, platform);
          if (mounted) _toast(s.accessVideoDeviceRemoved);
        } catch (e) {
          if (mounted) _toast(AppFailure.from(e).message(context));
        }
        if (mounted) setState(() => _removingDevice = false);
      },
    );
  }

  String? _validate(S s) {
    if (!_allCourses && _courses.isEmpty) return s.accessPickCourse;
    if (_platforms.isEmpty) return s.accessPickPlatform;
    if (!_permanent && _from != null && _until != null && !_until!.isAfter(_from!)) {
      return s.accessDatesInvalid;
    }
    if (!_allCourses) {
      for (final String c in _courses) {
        final CourseAccess a = _accessOf(c);
        if (a.platforms.isEmpty) return s.accessCoursePickPlatform(c);
        if (a.from != null && a.until != null && !a.until!.isAfter(a.from!)) {
          return '${s.accessDatesInvalid} · $c';
        }
      }
    }
    return null;
  }

  void _toast(String text) => AppMessenger.of(context)
    ..hide()
    ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));

  bool get _canAccess =>
      SessionController.to.current.canDo(AdminAction.membersAccess);

  Future<void> _save() async {
    final S s = S.of(context);
    if (!_canAccess) return;
    final String? problem = _validate(s);
    if (problem != null) {
      _toast(problem);
      return;
    }
    setState(() => _saving = true);
    // Always the explicit list: an empty one now means "Android and iPhone
    // only" (the default), not "everywhere".
    final result = await _users.setAccess(
      widget.member.uid,
      UserModel.toAccessMap(
        allCourses: _allCourses,
        courseList: _allCourses ? const <String>[] : _courses.toList(),
        platformList: _platforms.toList(),
        from: _permanent ? null : _from,
        until: _permanent ? null : _until,
        perCourse: _allCourses
            ? const <String, CourseAccess>{}
            : <String, CourseAccess>{for (final String c in _courses) c: _accessOf(c)},
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (AppFailure f) => _toast(f.message(context)),
      (_) {
        final NavigatorState nav = Navigator.of(context);
        _toast(s.accessSaved);
        nav.pop();
      },
    );
  }

  Future<void> _togglePause(AppUser live) async {
    setState(() => _pausing = true);
    final result = live.isPaused
        ? await _users.resumeAccess(live)
        : await _users.pauseAccess(live.uid);
    if (!mounted) return;
    setState(() => _pausing = false);
    result.fold((AppFailure f) => _toast(f.message(context)), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          FormatHelper.capitalize('${s.editAccess} · ${widget.member.displayName}'),
          style: StyleText.fontSize18Weight600,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          // DESKTOP: two columns — what they may watch (courses) beside
          // where and when (devices, period, pause). Phone: one column.
          final bool wide = c.maxWidth >= 1000;
          final Widget coursesCard = AppCard(
                title: s.accessCourses,
                caption: s.accessCoursesCaption,
                child: StreamBuilder<List<VideoItem>>(
                  stream: _videos,
                  builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
                    final List<String> courses = _courseNames(snap.data ?? const <VideoItem>[]);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _SwitchRow(
                          label: s.accessAllCourses,
                          value: _allCourses,
                          onChanged: (bool v) => setState(() => _allCourses = v),
                        ),
                        if (!_allCourses) ...<Widget>[
                          SizedBox(height: 6.h),
                          for (final String c in courses) ...<Widget>[
                            _CheckRow(
                              label: c.isEmpty ? s.videoCategoryGeneral : c,
                              checked: _courses.contains(c),
                              onTap: () => setState(() {
                                _courses.contains(c) ? _courses.remove(c) : _courses.add(c);
                              }),
                            ),
                            // TICKED: the course's own dates and platforms.
                            if (_courses.contains(c))
                              _CourseAccessBox(
                                access: _accessOf(c),
                                onChanged: (CourseAccess a) =>
                                    setState(() => _courseAccess[c] = a),
                              ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              );
          final Widget devicesCard = AppCard(
                title: s.accessPlatforms,
                caption: s.accessPlatformsCaption,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _SwitchRow(
                      label: s.accessAllPlatforms,
                      value: MemberAccess.allPlatforms.every(_platforms.contains),
                      onChanged: (bool v) => setState(() {
                        _platforms.clear();
                        if (v) _platforms.addAll(MemberAccess.allPlatforms);
                      }),
                    ),
                    SizedBox(height: 6.h),
                    for (final String p in MemberAccess.allPlatforms)
                      _CheckRow(
                        label: MemberAccess.platformLabel(p),
                        icon: _platformIcon(p),
                        checked: _platforms.contains(p),
                        onTap: () => setState(() {
                          _platforms.contains(p) ? _platforms.remove(p) : _platforms.add(p);
                        }),
                      ),
                  ],
                ),
              );
          final Widget periodCard = AppCard(
                title: s.accessPeriod,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CustomDropdown<bool>(
                      value: _permanent,
                      items: <DropdownItem<bool>>[
                        DropdownItem<bool>(value: true, label: s.accessPermanent),
                        DropdownItem<bool>(value: false, label: s.accessDates),
                      ],
                      onChanged: (bool v) => setState(() => _permanent = v),
                    ),
                    if (!_permanent) ...<Widget>[
                      SizedBox(height: 12.h),
                      DateTimeField(
                        label: s.accessFrom,
                        value: _from,
                        icon: Icons.play_circle_outline_rounded,
                        onChanged: (DateTime? v) => setState(() => _from = v),
                      ),
                      SizedBox(height: 12.h),
                      DateTimeField(
                        label: s.accessUntil,
                        value: _until,
                        icon: Icons.event_busy_rounded,
                        onChanged: (DateTime? v) => setState(() => _until = v),
                      ),
                    ],
                  ],
                ),
              );
          final Widget pauseCard = StreamBuilder<AppUser?>(
                stream: _live,
                builder: (BuildContext context, AsyncSnapshot<AppUser?> snap) {
                  final AppUser live = snap.data ?? widget.member;
                  return AppCard(
                    title: live.isPaused ? s.accessPaused : s.accessPause,
                    caption: s.accessPauseCaption,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          live.isPaused ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: live.isPaused ? AppColors.statusPending : AppColors.green,
                          size: 26,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            FormatHelper.capitalize(live.isPaused
                                ? s.accessPausedSince(AppDates.day(context, live.pausedAt))
                                : (live.accessUntil == null
                                    ? s.accessPermanent
                                    : s.accessUntilShort(AppDates.day(context, live.accessUntil)))),
                            style: StyleText.fontSize13Weight500.copyWith(color: AppColors.text),
                          ),
                        ),
                        // Members → Edit access.
                        if (_canAccess)
                        _pausing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))
                            : customButton(
                                title: live.isPaused ? s.accessResume : s.accessPause,
                                function: () => _togglePause(live),
                                wrapContent: true,
                                color: live.isPaused ? AppColors.green : AppColors.statusPending,
                              ),
                      ],
                    ),
                  );
                },
              );
          final Widget deviceCard = StreamBuilder<AppUser?>(
                stream: _live,
                builder: (BuildContext context, AsyncSnapshot<AppUser?> snap) {
                  final AppUser live = snap.data ?? widget.member;
                  final bool canDevice =
                      SessionController.to.current.canDo(AdminAction.membersDevice);
                  return AppCard(
                    title: s.accessVideoDevices,
                    caption: s.accessVideoDevicesCaption,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                    // One row per platform: the device that plays this
                    // member's videos there, with Remove / Block.
                    StreamBuilder<Map<String, VideoDevice>>(
                      stream: _videoDevices,
                      builder: (BuildContext context, AsyncSnapshot<Map<String, VideoDevice>> v) {
                        final Map<String, VideoDevice> slots =
                            v.data ?? const <String, VideoDevice>{};
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (final String p in VideoDeviceLock.platforms)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      slots[p] == null
                                          ? Icons.devices_other_rounded
                                          : Icons.phonelink_lock_rounded,
                                      color: slots[p] == null
                                          ? AppColors.secondaryText
                                          : AppColors.primary,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            MemberAccess.platformLabel(p),
                                            style: StyleText.fontSize13Weight600
                                                .copyWith(color: AppColors.text),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            slots[p] == null
                                                ? FormatHelper.capitalize(s.accessVideoDeviceEmpty)
                                                : <String>[
                                                    _deviceLabel(s, slots[p]!),
                                                    if (slots[p]!.at != null)
                                                      s.accessDeviceSince(
                                                          AppDates.day(context, slots[p]!.at)),
                                                  ].join(' · '),
                                            style: StyleText.fontSize12Weight400
                                                .copyWith(color: AppColors.secondaryText),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (slots[p] != null && canDevice) ...<Widget>[
                                      TextButton(
                                        onPressed: _removingDevice
                                            ? null
                                            : () => _removeVideoDevice(p, slots[p]!),
                                        child: Text(FormatHelper.capitalize(s.accessDeviceRemove)),
                                      ),
                                      IconButton(
                                        tooltip: s.accessDeviceBlock,
                                        onPressed: _removingDevice
                                            ? null
                                            : () => _blockVideoDevice(live, p, slots[p]!),
                                        icon: Icon(Icons.block_rounded,
                                            color: AppColors.red, size: 20),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    // Devices blocked from this member, each with Unblock.
                    StreamBuilder<List<BlockedDevice>>(
                      stream: _blockedDevices,
                      builder: (BuildContext context, AsyncSnapshot<List<BlockedDevice>> b) {
                        final List<BlockedDevice> list = b.data ?? const <BlockedDevice>[];
                        if (list.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(height: 14.h),
                            Text(
                              FormatHelper.capitalize(s.accessBlockedDevices),
                              style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                            ),
                            for (final BlockedDevice d in list)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.block_rounded, color: AppColors.red, size: 20),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        FormatHelper.capitalize(
                                          '${d.deviceName.isEmpty ? s.accessDeviceUnknown : d.deviceName}'
                                          ' · ${AppDates.day(context, d.blockedAt)}',
                                        ),
                                        style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                                      ),
                                    ),
                                    if (canDevice)
                                      TextButton(
                                        onPressed: () => _unblockDevice(d),
                                        child: Text(FormatHelper.capitalize(s.accessDeviceUnblock)),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                      ],
                    ),
                  );
                },
              );
          // CERTIFICATES BY HAND: give the member a course's certificate
          // without the final exam (Quizzes → Certificate quizzes).
          final Widget certificatesCard = !SessionController.to.current
                  .canDo(AdminAction.quizzesCertificates)
              ? const SizedBox.shrink()
              : AppCard(
                  title: s.certIssueTitle,
                  caption: s.certIssueCaption,
                  child: StreamBuilder<List<VideoItem>>(
                    stream: _certVideos,
                    builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> v) {
                      final List<String> courses = _courseNames(v.data ?? const <VideoItem>[])
                          .where((String c) => c.isNotEmpty)
                          .toList();
                      return StreamBuilder<List<IssuedCertificate>>(
                        stream: _issued,
                        builder: (BuildContext context, AsyncSnapshot<List<IssuedCertificate>> c) {
                          final Set<String> issued = <String>{
                            for (final IssuedCertificate x in c.data ?? const <IssuedCertificate>[])
                              x.course.trim().toLowerCase(),
                          };
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (final String course in courses)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        issued.contains(course.toLowerCase())
                                            ? Icons.workspace_premium_rounded
                                            : Icons.school_outlined,
                                        size: 20,
                                        color: issued.contains(course.toLowerCase())
                                            ? AppColors.green
                                            : AppColors.secondaryText,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          FormatHelper.capitalize(course),
                                          style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text),
                                        ),
                                      ),
                                      if (_issuing.contains(course))
                                        const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                                      else if (issued.contains(course.toLowerCase())) ...<Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                            builder: (_) => CertificatePage.of(
                                              data: CertificateData.issued(
                                                name: widget.member.displayName,
                                                course: course,
                                                uid: widget.member.uid,
                                              ),
                                            ),
                                          )),
                                          child: Text(FormatHelper.capitalize(s.viewCertificate)),
                                        ),
                                        TextButton(
                                          onPressed: () => _toggleCertificate(course, true),
                                          child: Text(
                                            FormatHelper.capitalize(s.certRevoke),
                                            style: TextStyle(color: AppColors.red),
                                          ),
                                        ),
                                      ] else
                                        customButton(
                                          title: s.certIssue,
                                          function: () => _toggleCertificate(course, false),
                                          wrapContent: true,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
          final Widget saveCard = !_canAccess
              ? const SizedBox.shrink()
              : Center(
                child: _saving
                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : customButton(title: s.save, function: _save, fullWidth: true),
              );
          final Widget gap = SizedBox(height: 16.h, width: 16.w);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1200 : 760.w),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.h),
                children: <Widget>[
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: coursesCard),
                        gap,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[deviceCard, gap, devicesCard, gap, periodCard, gap, pauseCard, gap, certificatesCard],
                          ),
                        ),
                      ],
                    )
                  else ...<Widget>[
                    deviceCard, gap, coursesCard, gap, devicesCard, gap, periodCard, gap, pauseCard, gap, certificatesCard,
                  ],
                  SizedBox(height: 24.h),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 360 : double.infinity),
                      child: saveCard,
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Categories from every video, in folder order, plus any course already
  /// saved on the member that no longer has videos.
  List<String> _courseNames(List<VideoItem> videos) {
    final Map<String, int> order = <String, int>{};
    for (final VideoItem v in videos) {
      final String c = v.category.trim();
      final int o = c.isEmpty ? -1 : (v.categoryOrder > 0 ? v.categoryOrder : 1 << 20);
      if (!order.containsKey(c) || o < order[c]!) order[c] = o;
    }
    for (final String c in _courses) {
      order.putIfAbsent(c, () => 1 << 21);
    }
    return order.keys.toList()
      ..sort((String a, String b) {
        final int c = order[a]!.compareTo(order[b]!);
        return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
      });
  }

  static IconData _platformIcon(String p) {
    switch (p) {
      case 'android':
        return Icons.android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}

/// Under a ticked course: From / To and the platforms it opens on.
class _CourseAccessBox extends StatelessWidget {
  const _CourseAccessBox({required this.access, required this.onChanged});

  final CourseAccess access;
  final ValueChanged<CourseAccess> onChanged;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Container(
      margin: EdgeInsetsDirectional.only(start: 34.w, bottom: 10.h, end: 4.w),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.secondaryText.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DateTimeField(
            label: s.accessFrom,
            value: access.from,
            icon: Icons.play_circle_outline_rounded,
            onChanged: (DateTime? v) =>
                onChanged(access.copyWith(from: v, clearFrom: v == null)),
          ),
          SizedBox(height: 10.h),
          DateTimeField(
            label: s.accessUntil,
            value: access.until,
            icon: Icons.event_busy_rounded,
            onChanged: (DateTime? v) =>
                onChanged(access.copyWith(until: v, clearUntil: v == null)),
          ),
          SizedBox(height: 10.h),
          Text(
            FormatHelper.capitalize(s.accessCoursePlatforms),
            style: StyleText.fontSize12Weight600.copyWith(color: AppColors.secondaryText),
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: <Widget>[
              for (final String p in MemberAccess.allPlatforms)
                FilterChip(
                  label: Text(MemberAccess.platformLabel(p)),
                  avatar: Icon(_MemberAccessPageState._platformIcon(p), size: 16),
                  selected: access.platforms.contains(p),
                  onSelected: (bool on) {
                    final List<String> next = List<String>.of(access.platforms);
                    on ? next.add(p) : next.remove(p);
                    onChanged(access.copyWith(platforms: next));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(FormatHelper.capitalize(label), style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text)),
          ),
          DefaultSwitchButton(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.checked, required this.onTap, this.icon});

  final String label;
  final bool checked;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: <Widget>[
            CustomCheckBox(isSelected: checked),
            SizedBox(width: 10.w),
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: AppColors.secondaryText),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(FormatHelper.capitalize(label), style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
            ),
          ],
        ),
      ),
    );
  }
}
