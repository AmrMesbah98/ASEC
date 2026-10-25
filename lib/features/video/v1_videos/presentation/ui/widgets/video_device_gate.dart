/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_device_gate.dart
/// Purpose: Declares `VideoDeviceGate` — stands in front of the Videos tab
///          and the player. A member's videos play on ONE device per
///          platform (see `VideoDeviceLock`); the rest of the app works on
///          every device. The first device to get here on a platform takes
///          the slot; any other device of that platform sees which device
///          holds it and is asked to have the admin remove it.
/// Author: ASEC team
/// Created: 25/10/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/data/device/video_device_lock.dart';
import 'package:asec/generated/l10n.dart';

class VideoDeviceGate extends StatefulWidget {
  const VideoDeviceGate({super.key, required this.child, this.fullPage = false});

  final Widget child;

  /// A pushed page (the player): the messages get a Scaffold with a back
  /// button. The Videos tab already sits inside the shell's Scaffold.
  final bool fullPage;

  @override
  State<VideoDeviceGate> createState() => _VideoDeviceGateState();
}

class _VideoDeviceGateState extends State<VideoDeviceGate> {
  StreamSubscription<Map<String, VideoDevice>>? _sub;
  Map<String, VideoDevice>? _slots;
  bool _offline = false;
  bool _claiming = false;

  /// The claim was refused while the slot was still empty — the rules are
  /// not deployed yet.
  bool _claimRefused = false;

  late final String _uid = SessionController.to.uid;
  final String _platform = MemberAccess.currentPlatform;

  /// Admins (and a missing session) are never limited.
  bool get _free => _uid.isEmpty || SessionController.to.isAdmin;

  @override
  void initState() {
    super.initState();
    if (!_free) _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = VideoDeviceLock.watch(_uid).listen(_onSlots, onError: (Object _) {
      if (mounted) setState(() => _offline = true);
    });
  }

  void _onSlots(Map<String, VideoDevice> slots) {
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _offline = false;
    });
    final VideoDevice? mine = slots[_platform];
    if (mine == null) {
      _claim();
    } else {
      VideoDeviceLock.remember(_uid, mine.isThisDevice);
    }
  }

  Future<void> _claim() async {
    if (_claiming) return;
    _claiming = true;
    try {
      await VideoDeviceLock.claim(_uid);
      _claimRefused = false;
    } on FirebaseException catch (e) {
      // Refused because another device just took the slot → the stream
      // shows that device. Refused with the slot still empty → rules.
      _claimRefused = e.code == 'permission-denied' && _slots?[_platform] == null;
    } catch (_) {
    } finally {
      _claiming = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _wrap(Widget body) => widget.fullPage
      ? Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          body: body,
        )
      : body;

  @override
  Widget build(BuildContext context) {
    if (_free) return widget.child;
    final S s = S.of(context);

    final Map<String, VideoDevice>? slots = _slots;
    if (slots == null) {
      if (_offline) {
        // No profile to read (offline): the last confirmed answer decides,
        // so downloaded lessons still play on the member's own device.
        return VideoDeviceLock.rememberedOwner(_uid)
            ? widget.child
            : _wrap(AppErrorView(message: s.errNetwork, onRetry: _listen));
      }
      return _wrap(const AppLoading());
    }

    final VideoDevice? holder = slots[_platform];
    if (holder == null) {
      return _wrap(_claimRefused
          ? AppErrorView(message: s.errRulesDenied, onRetry: _claim)
          : const AppLoading());
    }
    if (holder.isThisDevice) return widget.child;
    return _wrap(_LockedView(
      platform: MemberAccess.platformLabel(_platform),
      device: holder.name.isEmpty ? s.accessDeviceUnknown : holder.name,
    ));
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.platform, required this.device});

  final String platform;
  final String device;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.phonelink_lock_rounded, size: 28, color: AppColors.red),
                ),
                const SizedBox(height: 18),
                Text(
                  FormatHelper.capitalize(s.videoLockTitle),
                  style: StyleText.fontSize18Weight700.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  s.videoLockBody(platform, device),
                  style: StyleText.fontSize14Weight400
                      .copyWith(color: AppColors.secondaryText, height: 1.6),
                ),
                SizedBox(height: 18.h),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.devices_rounded, size: 20, color: AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          device,
                          style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
