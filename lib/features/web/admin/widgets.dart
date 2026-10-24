/// Panel helpers: page frame, confirm dialog, error handling.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

/// Title row + scrollable content, the same on every panel page.
class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.scroll = true,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.sizeOf(context).width < 720;
    final Widget head = Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 12,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: WebColors.red.withValues(alpha: 0.1),
                child: AppIcon(icon, color: WebColors.red),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(FormatHelper.capitalize(title), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: WebColors.navy)),
                  if (subtitle != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: narrow ? 260 : 620),
                      child: Text(FormatHelper.capitalize(subtitle!), style: TextStyle(color: WebColors.muted, fontSize: 13)),
                    ),
                ],
              ),
            ],
          ),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
    final EdgeInsets pad = EdgeInsets.all(narrow ? 14 : 28);
    if (!scroll) {
      return Padding(
        padding: pad,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[head, Expanded(child: child)]),
      );
    }
    return SingleChildScrollView(
      padding: pad,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[head, child]),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String? action}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext c) => Directionality(
      textDirection: AppLang.direction,
      child: AlertDialog(
        title: Text(FormatHelper.capitalize(title)),
        content: Text(FormatHelper.capitalize(body)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(FormatHelper.capitalize(const L('إلغاء', 'Cancel').t))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WebColors.red),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(FormatHelper.capitalize(action ?? const L('تأكيد', 'Confirm').t)),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

String describeError(Object? e) {
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return const L(
        'غير مسموح. تأكد أن حسابك له صلاحية "الموقع" وأن قواعد Firestore/Storage الجديدة منشورة (firebase deploy --only firestore:rules,storage).',
        'Not allowed. Check the account has the "website" permission and the new Firestore/Storage rules are deployed.',
      ).t;
    }
    return '${e.code}: ${e.message ?? ''}';
  }
  return '$e';
}

/// Runs a write, shows a snackbar on failure. Returns whether it worked.
Future<bool> guarded(BuildContext context, Future<Object?> Function() run, {String? done}) async {
  final AppMessenger m = AppMessenger.of(context);
  try {
    await run();
    m.show(AppMessage(
      content: Text(FormatHelper.capitalize(done ?? const L('تم الحفظ', 'Saved').t)),
      duration: const Duration(seconds: 2),
      backgroundColor: WebColors.success,
    ));
    return true;
  } catch (e) {
    m.show(AppMessage(content: Text(FormatHelper.capitalize(describeError(e))), backgroundColor: WebColors.red, duration: const Duration(seconds: 6)));
    return false;
  }
}

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.error, {super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WebColors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebColors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: <Widget>[
            const AppIcon(Icons.error_outline_rounded, color: WebColors.red),
            const SizedBox(width: 10),
            Expanded(child: SelectableText(describeError(error))),
          ],
        ),
      );
}

/// A number tile for the dashboard.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color, this.onTap});

  final String label;
  final String value;
  final IconData icon;

  /// Defaults to the heading colour (navy on light).
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = this.color ?? WebColors.navy;
    return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: AppIcon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(FormatHelper.capitalize(value), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      Text(FormatHelper.capitalize(label), style: TextStyle(color: WebColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
