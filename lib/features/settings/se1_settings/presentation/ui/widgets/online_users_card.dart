/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: online_users_card.dart
/// Purpose: Declares `OnlineUsersCard` — for admins with the Members
///          permission: who has the app open right now (live). Tap a member
///          to open all their controls; "View all" opens the full list with
///          everyone active in the last 24 hours.
/// Author: ASEC team
/// Created: 27/10/2026

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';
import 'package:asec/core/settings/presence.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a2_members/presentation/ui/pages/online_users_page.dart';
import 'package:asec/generated/l10n.dart';

class OnlineUsersCard extends StatefulWidget {
  const OnlineUsersCard({super.key});

  @override
  State<OnlineUsersCard> createState() => _OnlineUsersCardState();
}

class _OnlineUsersCardState extends State<OnlineUsersCard> {
  late final Stream<List<PresenceEntry>> _people =
      shared(() => Presence.watchRecent());

  /// Rows shown here before "View all".
  static const int _preview = 5;

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "Online" ends by time (no beat for 3 minutes), not only by data.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _openAll() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const OnlineUsersPage()),
      );

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<PresenceEntry>>(
      stream: _people,
      builder: (BuildContext context, AsyncSnapshot<List<PresenceEntry>> snap) {
        final List<PresenceEntry> online = (snap.data ?? const <PresenceEntry>[])
            .where((PresenceEntry e) => e.isOnline)
            .toList();
        return AppCard(
          title: '${FormatHelper.capitalize(s.onlineTitle)} (${online.length})',
          caption: s.onlineCaption,
          actions: <Widget>[
            TextButton(
              onPressed: _openAll,
              child: Text(FormatHelper.capitalize(s.onlineViewAll)),
            ),
          ],
          child: snap.hasError
              ? Text(
                  // Most likely the rules were not deployed yet.
                  FormatHelper.capitalize(s.errRulesDenied),
                  style: StyleText.fontSize13Weight500.copyWith(color: AppColors.red),
                )
              : online.isEmpty
                  ? Text(
                      FormatHelper.capitalize(s.onlineNone),
                      style: StyleText.fontSize13Weight500
                          .copyWith(color: AppColors.secondaryText),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final PresenceEntry e in online.take(_preview))
                          PresenceRow(entry: e),
                        if (online.length > _preview)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _openAll,
                              child: Text(
                                '${FormatHelper.capitalize(s.onlineViewAll)} (${online.length})',
                              ),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}
