/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: bulk_upload_page.dart
/// Purpose: Declares `BulkUploadPage` — the admin's full-screen "Upload
///          lessons": browse or drag many videos at once, rename each, pick
///          one folder and publishing for all, and watch them go up into
///          the lessons folder one after another — every file with its own
///          animated card, plus the overall progress, speed, time left and
///          the internet. Ported from ENGX (09/11/2026) in ASEC's design:
///          the overall panel is the brand gradient instead of ENGX's
///          circuit board.
/// Author: ASEC team
/// Created: 09/11/2026

import 'dart:math' as math;
import 'dart:ui' show FontFeature, PathMetric;

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/custom/58-default_switch_button.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/upload/drive_uploader.dart';
import 'package:asec/features/video/v1_videos/presentation/controller/bulk_upload_cubit.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/upload/drive_folder_dialogs.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/upload/upload_kit.dart';

/// The overall panel's colours — on the brand gradient, everything is white.
abstract final class _Board {
  static const Color text = Colors.white;
  static const Color subtext = Colors.white70;
  static const Color trace = Colors.white24;
  static const Color current = Colors.white;
}

/// The overall panel: ASEC's brand gradient (primary → secondary primary).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: child,
      );
}

class BulkUploadPage extends StatelessWidget {
  const BulkUploadPage({super.key, required this.adminUid, this.category = ''});

  final String adminUid;
  final String category;

  @override
  Widget build(BuildContext context) => BlocProvider<BulkUploadCubit>(
        create: (_) => BulkUploadCubit(adminUid: adminUid, category: category),
        child: const _BulkView(),
      );
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _bytes(num b) {
  if (b >= 1024 * 1024 * 1024) return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  if (b >= 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${b.round()} B';
}

String _clock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final int h = d.inHours;
  final int m = d.inMinutes.remainder(60);
  final int s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

bool get _canDrop =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

Future<List<PlatformFile>> _fromDrop(List<XFile> files) async => <PlatformFile>[
      for (final XFile f in files)
        PlatformFile(
          name: f.name,
          size: await f.length(),
          path: kIsWeb ? null : f.path,
          bytes: kIsWeb ? await f.readAsBytes() : null,
        ),
    ];

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

// ── The page ────────────────────────────────────────────────────────────────

class _BulkView extends StatefulWidget {
  const _BulkView();

  @override
  State<_BulkView> createState() => _BulkViewState();
}

class _BulkViewState extends State<_BulkView> {
  late final BulkUploadCubit _cubit = context.read<BulkUploadCubit>();
  late final TextEditingController _category =
      TextEditingController(text: _cubit.state.category);

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  String? _stopMessage(UpS s, BulkStop? stop) {
    switch (stop) {
      case BulkStop.folderMissing:
        return s.upDriveNotSet;
      case BulkStop.signInMissing:
        return s.upDriveOauthMissing;
      case BulkStop.driveFull:
        return s.upDriveFull;
      case BulkStop.noInternet:
        return s.upNoInternet;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    return BlocConsumer<BulkUploadCubit, BulkState>(
      listenWhen: (BulkState a, BulkState b) =>
          a.stop != b.stop || a.rejected != b.rejected && b.rejected > 0,
      listener: (BuildContext context, BulkState st) {
        final String? msg = _stopMessage(s, st.stop) ??
            (st.rejected > 0 ? s.bulkRejected('${st.rejected}') : null);
        if (msg != null) {
          AppMessenger.of(context)
            ..hide()
            ..show(AppMessage(content: Text(FormatHelper.capitalize(msg))));
        }
      },
      builder: (BuildContext context, BulkState st) {
        final bool hasPending = st.items.any((BulkItem i) => i.status == BulkItemStatus.pending);
        return PopScope(
          canPop: !st.busy,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              AppMessenger.of(context)
                  .show(AppMessage(content: Text(FormatHelper.capitalize(s.bulkLeaveQ))));
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(FormatHelper.capitalize(s.bulkTitle), style: StyleText.fontSize18Weight600),
              actions: <Widget>[
                if (st.running) ...<Widget>[
                  AppButton(
                    label: st.paused ? s.upResume : s.upPause,
                    icon: st.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    kind: AppButtonKind.subtle,
                    dense: true,
                    onPressed: _cubit.togglePause,
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: s.uploadCancel,
                    icon: Icons.close_rounded,
                    kind: AppButtonKind.danger,
                    dense: true,
                    onPressed: _cubit.cancel,
                  ),
                ] else
                  AppButton(
                    label: s.bulkStart,
                    icon: Icons.rocket_launch_rounded,
                    dense: true,
                    loading: st.syncing,
                    onPressed: hasPending && !st.syncing ? _cubit.start : null,
                  ),
                const SizedBox(width: 16),
              ],
            ),
            body: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool wide = c.maxWidth >= 1000;
                final Widget side = _SidePanel(state: st, category: _category);
                final Widget main = _MainArea(state: st);
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(width: 360, child: SingleChildScrollView(child: side)),
                        const SizedBox(width: 20),
                        Expanded(child: main),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      side,
                      const SizedBox(height: 16),
                      Expanded(child: main),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Side: settings + overall progress ───────────────────────────────────────

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.state, required this.category});

  final BulkState state;
  final TextEditingController category;

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final BulkUploadCubit cubit = context.read<BulkUploadCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
            opacity: a,
            child: SizeTransition(sizeFactor: a, child: child),
          ),
          child: state.items.isEmpty
              ? const SizedBox.shrink(key: ValueKey<String>('none'))
              : Padding(
                  key: const ValueKey<String>('stats'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Overall(state: state),
                ),
        ),
        AppCard(
          title: s.bulkSettings,
          caption: s.bulkSettingsSub,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // WHERE THEY GO: a course or a section of the Drive folder.
              Text(FormatHelper.capitalize(s.videoCategory), style: StyleText.fontSize13Weight600),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: state.busy
                    ? null
                    : () async {
                        final DriveFolder? f = await pickDriveFolder(context, title: s.fldPickCategory);
                        if (f != null) cubit.setFolder(f);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: <Widget>[
                    AppIcon(Icons.folder_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.folderLabel.isNotEmpty
                            ? state.folderLabel
                            : (state.category.isNotEmpty ? state.category : s.fldRoot),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                      ),
                    ),
                    Text(
                      FormatHelper.capitalize(s.fldPickCategory),
                      style: StyleText.fontSize12Weight600.copyWith(color: AppColors.primary),
                    ),
                    AppIcon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ]),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: s.fldNew,
                  icon: Icons.create_new_folder_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: state.busy
                      ? null
                      : () => showNewFolderDialog(
                            context,
                            inCourse: state.folderLabel.contains(' › ') ? '' : state.category,
                            onDone: () {},
                          ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(FormatHelper.capitalize(s.published), style: StyleText.fontSize14Weight600),
                        Text(
                          FormatHelper.capitalize(s.publishedHint),
                          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    ignoring: state.busy,
                    child: Opacity(
                      opacity: state.busy ? 0.5 : 1,
                      child: DefaultSwitchButton(value: state.published, onChanged: cubit.setPublished),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: s.upSwitchAccount,
                  icon: Icons.switch_account_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: state.busy
                      ? null
                      : () async {
                          final AppMessenger m = AppMessenger.of(context);
                          await DriveUploader.signOut();
                          m.show(AppMessage(content: Text(FormatHelper.capitalize(s.upSwitched))));
                        },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: 'Server sign-in settings',
                  icon: Icons.settings_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: state.busy ? null : () => showServerSignInDialog(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The circuit panel with the overall ring, counts, speed, time left and the
/// internet — or the success / syncing state.
class _Overall extends StatelessWidget {
  const _Overall({required this.state});

  final BulkState state;

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final int pct = (state.progress * 100).floor();
    final bool stalled = state.paused || state.offline;
    final String left = state.paused
        ? s.upPaused
        : state.offline
            ? '—'
            : state.running
                ? (state.timeLeft == null ? s.upCalculating : _clock(state.timeLeft!))
                : '—';

    final Widget body;
    if (state.syncing) {
      body = _StatusLine(
        key: const ValueKey<String>('sync'),
        icon: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
        ),
        text: s.bulkSyncing,
      );
    } else if (state.finished) {
      body = _Finished(key: const ValueKey<String>('done'), state: state);
    } else {
      body = Column(
        key: const ValueKey<String>('run'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Ring(value: state.progress, stalled: stalled, label: '$pct%'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.bulkCount('${state.doneCount}', '${state.items.length}'),
                      style: StyleText.fontSize16Weight600.copyWith(color: _Board.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_bytes(state.sentBytes)} / ${_bytes(state.totalBytes)}',
                      style: StyleText.fontSize12Weight400.copyWith(
                        color: _Board.subtext,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  icon: Icons.speed_rounded,
                  label: s.upSpeed,
                  value: !state.running || stalled || state.speed <= 0 ? '—' : '${_bytes(state.speed)}/s',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.timer_outlined, label: s.upTimeLeft, value: left)),
            ],
          ),
          if (state.running) ...<Widget>[
            const SizedBox(height: 12),
            _Net(offline: state.offline),
          ],
        ],
      );
    }
    return _BrandPanel(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: body,
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.stalled, required this.label});

  final double value;
  final bool stalled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, _) => SizedBox(
        width: 74,
        height: 74,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CircularProgressIndicator(
              value: v,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: _Board.trace,
              valueColor: AlwaysStoppedAnimation<Color>(
                stalled ? AppColors.statusPending : _Board.current,
              ),
            ),
            Center(
              child: Text(
                label,
                style: StyleText.fontSize16Weight600.copyWith(
                  color: _Board.current,
                  fontFeatures: _tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Board.trace),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(children: <Widget>[
            AppIcon(icon, size: 14, color: _Board.current),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                FormatHelper.capitalize(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize11Weight400.copyWith(color: _Board.subtext),
              ),
            ),
          ]),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize14Weight600.copyWith(
              color: _Board.text,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _Net extends StatelessWidget {
  const _Net({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final Color c = offline ? AppColors.red : AppColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(children: <Widget>[
        AppIcon(offline ? Icons.wifi_off_rounded : Icons.wifi_rounded, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            FormatHelper.capitalize(offline ? s.upOffline : s.upOnline),
            style: StyleText.fontSize12Weight600.copyWith(color: c),
          ),
        ),
      ]),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({super.key, required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            FormatHelper.capitalize(text),
            style: StyleText.fontSize14Weight600.copyWith(color: _Board.text),
          ),
        ),
      ]);
}

class _Finished extends StatelessWidget {
  const _Finished({super.key, required this.state});

  final BulkState state;

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final bool allOk = state.failedCount == 0;
    return Row(
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (BuildContext context, double v, Widget? child) =>
              Transform.scale(scale: v, child: child),
          child: AppIcon(
            allOk ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 46,
            color: allOk ? AppColors.green : AppColors.statusPending,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            allOk
                ? s.bulkFinished('${state.doneCount}')
                : s.bulkFinishedSome('${state.doneCount}', '${state.failedCount}'),
            style: StyleText.fontSize14Weight600.copyWith(color: _Board.text),
          ),
        ),
      ],
    );
  }
}

// ── Main: drop zone or the list ─────────────────────────────────────────────

class _MainArea extends StatefulWidget {
  const _MainArea({required this.state});

  final BulkState state;

  @override
  State<_MainArea> createState() => _MainAreaState();
}

class _MainAreaState extends State<_MainArea> {
  bool _hover = false;

  Future<void> _onDrop(DropDoneDetails d) async {
    setState(() => _hover = false);
    if (d.files.isEmpty) return;
    final BulkUploadCubit cubit = context.read<BulkUploadCubit>();
    cubit.drop(await _fromDrop(d.files));
  }

  @override
  Widget build(BuildContext context) {
    final BulkState st = widget.state;
    final Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      child: st.items.isEmpty
          ? _BigDrop(key: const ValueKey<String>('drop'), hover: _hover)
          : _FileList(key: const ValueKey<String>('list'), state: st, hover: _hover),
    );
    if (!_canDrop) return content;
    return DropTarget(
      enable: !st.busy,
      onDragEntered: (_) => setState(() => _hover = true),
      onDragExited: (_) => setState(() => _hover = false),
      onDragDone: _onDrop,
      child: content,
    );
  }
}

/// The whole area as one drop zone: a faint live circuit, a pulsing cloud.
class _BigDrop extends StatefulWidget {
  const _BigDrop({super.key, required this.hover});

  final bool hover;

  @override
  State<_BigDrop> createState() => _BigDropState();
}

class _BigDropState extends State<_BigDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final Color accent = AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.hover ? accent.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        foregroundPainter: _Dashed(color: widget.hover ? accent : AppColors.border, radius: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: <Widget>[
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (BuildContext context, Widget? child) {
                          final double t = Curves.easeInOut.transform(_pulse.value);
                          return Transform.scale(
                            scale: widget.hover ? 1.12 : 0.94 + t * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.12),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: accent.withOpacity(0.18 + t * 0.25),
                                    blurRadius: 30 + t * 20,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: AppIcon(
                          widget.hover ? Icons.file_download_rounded : Icons.cloud_upload_rounded,
                          size: 58,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        FormatHelper.capitalize(widget.hover ? s.upDropRelease : s.bulkDropTitle),
                        textAlign: TextAlign.center,
                        style: StyleText.fontSize22Weight700.copyWith(color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Text(
                          FormatHelper.capitalize(s.bulkDropSub),
                          textAlign: TextAlign.center,
                          style: StyleText.fontSize14Weight400.copyWith(color: AppColors.secondaryText),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        label: s.upBrowse,
                        icon: Icons.folder_open_rounded,
                        onPressed: context.read<BulkUploadCubit>().pick,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.upFormats('$kMaxUploadMb'),
                        style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashed extends CustomPainter {
  _Dashed({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(1), Radius.circular(radius)));
    for (final PathMetric m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 9), p);
        d += 15;
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color;
}

class _FileList extends StatelessWidget {
  const _FileList({super.key, required this.state, required this.hover});

  final BulkState state;
  final bool hover;

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final BulkUploadCubit cubit = context.read<BulkUploadCubit>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: hover ? AppColors.primary.withOpacity(0.06) : AppColors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hover ? AppColors.primary : AppColors.transparent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              children: <Widget>[
                AppIcon(Icons.video_library_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.bulkVideos('${state.items.length}', _bytes(state.totalBytes)),
                    style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
                  ),
                ),
                AppButton(
                  label: s.bulkAddMore,
                  icon: Icons.add_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: state.busy ? null : cubit.pick,
                ),
                AppButton(
                  label: s.bulkClear,
                  icon: Icons.clear_all_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: state.busy ? null : cubit.clearAll,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) {
                final BulkItem item = state.items[i];
                return FadeSlideIn(
                  key: ValueKey<String>(item.key),
                  delay: Duration(milliseconds: math.min(i, 8) * 40),
                  child: _ItemCard(item: item, locked: state.busy),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  const _ItemCard({required this.item, required this.locked});

  final BulkItem item;
  final bool locked;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _title = TextEditingController(text: widget.item.title);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UpS s = UpS.of(context);
    final BulkUploadCubit cubit = context.read<BulkUploadCubit>();
    final BulkItem it = widget.item;
    final bool active = it.status == BulkItemStatus.uploading;
    final bool done = it.status == BulkItemStatus.done;
    final bool failed = it.status == BulkItemStatus.failed;
    final Color tone = done
        ? AppColors.green
        : failed
            ? AppColors.red
            : active
                ? AppColors.primary
                : AppColors.secondaryText;
    final String status = switch (it.status) {
      BulkItemStatus.pending => s.bulkPending,
      BulkItemStatus.uploading => '${s.bulkUploading} · ${(it.progress * 100).floor()}%',
      BulkItemStatus.done => s.bulkDone,
      BulkItemStatus.failed => s.bulkFailed,
    };
    final bool editable = it.status == BulkItemStatus.pending && !widget.locked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active || done || failed ? tone.withOpacity(0.55) : AppColors.border,
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[BoxShadow(color: tone.withOpacity(0.18), blurRadius: 18)]
            : const <BoxShadow>[],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              // The status icon swaps with a little pop.
              SizedBox(
                width: 46,
                height: 46,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (Widget c, Animation<double> a) =>
                      ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
                  child: Container(
                    key: ValueKey<BulkItemStatus>(it.status),
                    decoration: BoxDecoration(
                      color: tone.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: active
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              value: it.progress <= 0 ? null : it.progress,
                              valueColor: AlwaysStoppedAnimation<Color>(tone),
                            ),
                          )
                        : AppIcon(
                            done
                                ? Icons.check_rounded
                                : failed
                                    ? Icons.error_outline_rounded
                                    : Icons.movie_rounded,
                            color: tone,
                            size: 24,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (editable)
                      TextField(
                        controller: _title,
                        onChanged: (String v) => cubit.setTitle(it.key, v),
                        style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: s.bulkTitleField,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          suffixIcon: AppIcon(Icons.edit_rounded, size: 14, color: AppColors.secondaryText),
                          suffixIconConstraints: const BoxConstraints(minWidth: 20),
                        ),
                      )
                    else
                      Text(
                        it.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            '${it.file.name} · ${_bytes(it.file.size)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tone.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            FormatHelper.capitalize(status),
                            style: StyleText.fontSize11Weight600.copyWith(
                              color: tone,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (failed)
                AppButton(
                  label: s.bulkRetry,
                  icon: Icons.refresh_rounded,
                  kind: AppButtonKind.subtle,
                  onPressed: widget.locked ? null : () => cubit.retry(it.key),
                )
              else if (editable)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () => cubit.remove(it.key),
                  icon: AppIcon(Icons.close_rounded, color: AppColors.secondaryText, size: 20),
                ),
            ],
          ),
          // The bar slides to its value; a done card keeps it full and green.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: it.status == BulkItemStatus.pending
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: done ? 1 : it.progress),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double v, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: active && v <= 0 ? null : v,
                          minHeight: 7,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(tone),
                        ),
                      ),
                    ),
                  ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.upServerError,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize11Weight400.copyWith(color: AppColors.red),
              ),
            ),
        ],
      ),
    );
  }
}
