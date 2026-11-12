/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: activity_charts.dart
/// Purpose: Declares `ActivityCharts` — two dashboard charts (12/11/2026,
///          ported from ENGX): members active in the app hour by hour today,
///          and day by day over the last 14 days.
///          Built from `app_activity/{UTC day}` (Presence) and, so it is
///          not empty before members update, from every other trace of a
///          member in the app: their last beat in `presence` and quiz
///          attempts. Admins are not counted.
/// Author: Amr Mesbah
/// Created: 12/11/2026

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/24-custom_chart_card.dart';
import 'package:asec/core/custom/26-custom_bar_chart_card.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/core/settings/presence.dart';
import 'package:asec/core/theme/app_colors.dart';

class ActivityCharts extends StatefulWidget {
  const ActivityCharts({super.key});

  @override
  State<ActivityCharts> createState() => _ActivityChartsState();
}

class _ActivityChartsState extends State<ActivityCharts> {
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs =
      <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  List<Map<String, dynamic>> _activity = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _presence = const <Map<String, dynamic>>[];

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    final DateTime from = DateTime.now().toUtc().subtract(const Duration(days: 16));
    final String fromId = '${from.year}-${_two(from.month)}-${_two(from.day)}';
    _subs.add(AppFirebase.db
        .collection(Presence.activityCollection)
        .where('date', isGreaterThanOrEqualTo: fromId)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> q) {
      if (mounted) setState(() => _activity = <Map<String, dynamic>>[for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs) d.data()]);
    }, onError: (Object _) {}));
    _subs.add(AppFirebase.db
        .collection(Presence.collection)
        .where('last_seen', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 16))))
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> q) {
      if (mounted) {
        setState(() => _presence = <Map<String, dynamic>>[
              for (final QueryDocumentSnapshot<Map<String, dynamic>> d in q.docs) <String, dynamic>{...d.data(), '__id': d.id},
            ]);
      }
    }, onError: (Object _) {}));
  }

  @override
  void dispose() {
    for (final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  /// Local hour → (who, minutes).
  Map<DateTime, (Set<String>, int)> get _hourly {
    final Map<DateTime, (Set<String>, int)> out = <DateTime, (Set<String>, int)>{};
    void add(DateTime local, Iterable<String> who, int minutes) {
      final DateTime key = DateTime(local.year, local.month, local.day, local.hour);
      final (Set<String>, int) old = out[key] ?? (<String>{}, 0);
      out[key] = (<String>{...old.$1, ...who}, old.$2 + minutes);
    }
    for (final Map<String, dynamic> d in _activity) {
      final DateTime? day = DateTime.tryParse('${d['date'] ?? ''}');
      if (day == null) continue;
      for (int h = 0; h < 24; h++) {
        final Object? u = d['u$h'];
        final Object? m = d['m$h'];
        if (u is! List && m is! num) continue;
        add(DateTime.utc(day.year, day.month, day.day, h).toLocal(),
            <String>[if (u is List) for (final Object? x in u) '$x'], m is num ? m.toInt() : 0);
      }
    }
    // Members' last beat (before everybody has the version that keeps history).
    for (final Map<String, dynamic> d in _presence) {
      final String role = '${d['role'] ?? ''}'.toLowerCase();
      if (role.contains('admin')) continue;
      final Object? t = d['last_seen'];
      if (t is Timestamp) add(t.toDate().toLocal(), <String>['${d['__id']}'], 0);
    }
    return out;
  }

  static String _hourLabel(int h) => h == 0 ? '12a' : h < 12 ? '${h}a' : h == 12 ? '12p' : '${h - 12}p';

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String en, String arabic) => ar ? arabic : en;
    final Map<DateTime, (Set<String>, int)> hourly = _hourly;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Today, hour by hour.
    final Set<String> todayWho = <String>{};
    int todayMinutes = 0;
    final List<ChartData> hours = <ChartData>[];
    for (int h = 0; h < 24; h++) {
      final (Set<String>, int)? e = hourly[today.add(Duration(hours: h))];
      todayWho.addAll(e?.$1 ?? const <String>{});
      todayMinutes += e?.$2 ?? 0;
      hours.add(ChartData(label: h % 3 == 0 ? _hourLabel(h) : '', value: (e?.$1.length ?? 0).toDouble()));
    }

    // Last 14 days.
    final Set<String> periodWho = <String>{};
    int periodMinutes = 0;
    final List<ChartData> days = <ChartData>[];
    for (int i = 13; i >= 0; i--) {
      final DateTime day = today.subtract(Duration(days: i));
      final Set<String> who = <String>{};
      for (int h = 0; h < 24; h++) {
        final (Set<String>, int)? e = hourly[day.add(Duration(hours: h))];
        who.addAll(e?.$1 ?? const <String>{});
        periodMinutes += e?.$2 ?? 0;
      }
      periodWho.addAll(who);
      days.add(ChartData(label: i.isEven ? '${day.day}/${day.month}' : '', value: who.length.toDouble()));
    }

    String hoursText(int minutes) => minutes <= 0
        ? ''
        : t(' · ${(minutes / 60).toStringAsFixed(minutes < 600 ? 1 : 0)} h in the app',
            ' · ${(minutes / 60).toStringAsFixed(minutes < 600 ? 1 : 0)} ساعة في التطبيق');
    final double h = MediaQuery.sizeOf(context).width < 600 ? 220 : 300;

    final Widget byHour = BarChartCard(
      title: t('Active by hour', 'النشاط حسب الساعة'),
      caption: t('Today · ${todayWho.length} members', 'اليوم · ${todayWho.length} عضو') + hoursText(todayMinutes),
      height: h.h,
      expandChild: true,
      barWidth: 8,
      barColor: AppColors.green,
      emptyMessage: t('Nothing to show yet', 'لا يوجد شيء بعد'),
      bars: hours,
    );
    final Widget byDay = BarChartCard(
      title: t('Active by day', 'النشاط حسب اليوم'),
      caption: t('Last 14 days · ${periodWho.length} members', 'آخر 14 يوم · ${periodWho.length} عضو') + hoursText(periodMinutes),
      height: h.h,
      expandChild: true,
      barWidth: 14,
      barColor: AppColors.primary,
      emptyMessage: t('Nothing to show yet', 'لا يوجد شيء بعد'),
      bars: days,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => c.maxWidth < 1000
          ? Column(children: <Widget>[byHour, SizedBox(height: 16.h), byDay])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: byHour),
                SizedBox(width: 16.w),
                Expanded(child: byDay),
              ],
            ),
    );
  }
}
