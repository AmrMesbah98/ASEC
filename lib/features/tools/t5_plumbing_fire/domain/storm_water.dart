/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: storm_water.dart
/// Purpose: Storm (rain) water sizing — vertical and horizontal leaders,
///          gutter size and count, from roof area, rainfall rate and the
///          horizontal slope. As per NSPC tables 13.6.1 / 13.6.2.
/// Author: ASEC team
/// Created: 22/10/2026
///
/// Pure Dart, works offline. Tables recovered from the "Plumbing & Fire
/// Calculator" (DPME) and checked against its screen. Areas are m² of
/// projected roof; sizes are inches. Like the original, a 5" result is
/// given as 6" and a 7" as 8" (sizes not stocked).
///
/// Fixed against the original: its 1.5 in/h leader tables were the 1 in/h
/// table × 0.75 instead of ÷ 1.5 (every other rate follows 1/rate); one
/// gutter limit was a typo (154 where the 5" capacity is 116); and "number
/// of gutters for a chosen diameter" used the next-smaller gutter.
library;

import 'dart:math' as math;

/// One step of a sizing table: roof areas up to [maxArea] m² need [size]".
class StormStep {
  const StormStep(this.maxArea, this.size);

  final double maxArea;
  final double size;
}

/// Rainfall rates offered, in/h (index = table index).
const List<double> kRainfallRatesInH = <double>[1, 1.5, 2, 4, 5, 6];

/// Horizontal leader slopes (index = table index).
/// 09/11/2026: shown in % only — no "per ft".
const List<String> kStormSlopes = <String>['0.5 %', '1 %', '2 %', '4 %'];

/// Gutter sizes matching [kGutterCapacities] columns, in.
const List<double> kGutterSizes = <double>[3, 4, 5, 6, 7, 8, 10];

// vertical leaders, by rainfall rate index (1, 1.5, 2, 4, 5, 6 in/h)
const List<List<StormStep>> kVerticalLeaderTables = <List<StormStep>>[
  <StormStep>[StormStep(202.0, 2), StormStep(366.0, 2.5), StormStep(598.0, 3), StormStep(1285.0, 4), StormStep(2333.0, 5), StormStep(3790.0, 6), StormStep(double.infinity, 8)],
  <StormStep>[StormStep(134.667, 2), StormStep(244.0, 2.5), StormStep(398.667, 3), StormStep(856.667, 4), StormStep(1555.333, 5), StormStep(2526.667, 6), StormStep(double.infinity, 8)],
  <StormStep>[StormStep(101.0, 2), StormStep(183.0, 2.5), StormStep(299.0, 3), StormStep(642.0, 4), StormStep(1166.0, 5), StormStep(1895.0, 6), StormStep(double.infinity, 8)],
  <StormStep>[StormStep(50.0, 2), StormStep(91.0, 2.5), StormStep(149.0, 3), StormStep(321.0, 4), StormStep(583.0, 5), StormStep(947.0, 6), StormStep(double.infinity, 8)],
  <StormStep>[StormStep(40.0, 2), StormStep(73.0, 2.5), StormStep(119.0, 3), StormStep(257.0, 4), StormStep(466.0, 5), StormStep(758.0, 6), StormStep(double.infinity, 8)],
  <StormStep>[StormStep(33.0, 2), StormStep(61.0, 2.5), StormStep(99.0, 3), StormStep(214.0, 4), StormStep(388.0, 5), StormStep(631.0, 6), StormStep(double.infinity, 8)],
];

// horizontal leaders: [slope index 0.5 %, 1 %, 2 %, 4 %][rate index]
const List<List<List<StormStep>>> kHorizontalLeaderTables = <List<List<StormStep>>>[
  <List<StormStep>>[
    <StormStep>[StormStep(891.869, 5), StormStep(1434.42, 6), StormStep(3039.79, 8), StormStep(3686.39, 10), StormStep(double.infinity, 12)],
    <StormStep>[StormStep(594.579, 5), StormStep(956.28, 6), StormStep(2026.527, 8), StormStep(2457.593, 10), StormStep(double.infinity, 12)],
    <StormStep>[StormStep(445.935, 5), StormStep(717.211, 6), StormStep(1519.89, 8), StormStep(2772.23, 10), StormStep(double.infinity, 12)],
    <StormStep>[StormStep(222.967, 5), StormStep(358.606, 6), StormStep(759.947, 8), StormStep(1386.11, 10), StormStep(double.infinity, 12)],
    <StormStep>[StormStep(178.374, 5), StormStep(286.885, 6), StormStep(607.958, 8), StormStep(1108.89, 10), StormStep(double.infinity, 12)],
    <StormStep>[StormStep(148.645, 5), StormStep(239.225, 6), StormStep(506.322, 8), StormStep(924.385, 10), StormStep(double.infinity, 12)],
  ],
  <List<StormStep>>[
    <StormStep>[StormStep(305.0, 3), StormStep(698.0, 4), StormStep(1241.0, 5), StormStep(1988.0, 6), StormStep(4273.0, 8), StormStep(7692.0, 10), StormStep(12374.0, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(203.333, 3), StormStep(465.333, 4), StormStep(827.333, 5), StormStep(1325.333, 6), StormStep(2848.667, 8), StormStep(5128.0, 10), StormStep(8249.333, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(152.0, 3), StormStep(349.0, 4), StormStep(620.0, 5), StormStep(994.0, 6), StormStep(2136.0, 8), StormStep(3846.0, 10), StormStep(6187.0, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(76.0, 3), StormStep(174.0, 4), StormStep(310.0, 5), StormStep(497.0, 6), StormStep(1068.0, 8), StormStep(1923.0, 10), StormStep(3093.0, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(61.0, 3), StormStep(139.0, 4), StormStep(248.0, 5), StormStep(397.0, 6), StormStep(854.0, 8), StormStep(1538.0, 10), StormStep(2474.0, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(51.0, 3), StormStep(116.0, 4), StormStep(207.0, 5), StormStep(331.0, 6), StormStep(712.0, 8), StormStep(1282.0, 10), StormStep(2062.0, 12), StormStep(double.infinity, 15)],
  ],
  <List<StormStep>>[
    <StormStep>[StormStep(151.618, 2), StormStep(431.07, 3), StormStep(984.772, 4), StormStep(1754.01, 5), StormStep(2805.67, 6), StormStep(6057.28, 8), StormStep(10851.1, 10), StormStep(17465.8, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(101.079, 2), StormStep(287.38, 3), StormStep(656.515, 4), StormStep(1169.34, 5), StormStep(1870.447, 6), StormStep(4038.187, 8), StormStep(7234.067, 10), StormStep(11643.867, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(75.8089, 2), StormStep(215.535, 3), StormStep(492.386, 4), StormStep(877.005, 5), StormStep(1402.84, 6), StormStep(3028.64, 8), StormStep(5425.54, 10), StormStep(8732.89, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(37.9044, 2), StormStep(107.768, 3), StormStep(246.193, 4), StormStep(438.502, 5), StormStep(701.418, 6), StormStep(1514.32, 8), StormStep(2712.77, 10), StormStep(4366.44, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(30.2864, 2), StormStep(86.214, 3), StormStep(196.954, 4), StormStep(350.802, 5), StormStep(561.134, 6), StormStep(1211.46, 8), StormStep(2170.22, 10), StormStep(3493.15, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(25.2696, 2), StormStep(71.9999, 3), StormStep(164.438, 4), StormStep(292.645, 5), StormStep(467.767, 6), StormStep(1009.86, 8), StormStep(1808.82, 10), StormStep(2911.12, 12), StormStep(double.infinity, 15)],
  ],
  <List<StormStep>>[
    <StormStep>[StormStep(214.049, 2), StormStep(611.302, 3), StormStep(1397.26, 4), StormStep(2482.37, 5), StormStep(3976.25, 6), StormStep(8547.08, 8), StormStep(15384.7, 10), StormStep(24749.4, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(142.699, 2), StormStep(407.535, 3), StormStep(931.507, 4), StormStep(1654.913, 5), StormStep(2650.833, 6), StormStep(5698.053, 8), StormStep(10256.467, 10), StormStep(16499.6, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(107.024, 2), StormStep(305.651, 3), StormStep(698.631, 4), StormStep(1241.18, 5), StormStep(1988.12, 6), StormStep(4273.54, 8), StormStep(7692.37, 10), StormStep(12374.7, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(53.5121, 2), StormStep(152.733, 3), StormStep(349.315, 4), StormStep(620.592, 5), StormStep(994.062, 6), StormStep(2136.77, 8), StormStep(3846.19, 10), StormStep(6187.34, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(42.8283, 2), StormStep(122.26, 3), StormStep(279.452, 4), StormStep(496.474, 5), StormStep(795.25, 6), StormStep(1709.42, 8), StormStep(3076.95, 10), StormStep(4949.87, 12), StormStep(double.infinity, 15)],
    <StormStep>[StormStep(35.6748, 2), StormStep(102.193, 3), StormStep(233.187, 4), StormStep(413.419, 5), StormStep(662.399, 6), StormStep(1424.2, 8), StormStep(2564.12, 10), StormStep(4124.9, 12), StormStep(double.infinity, 15)],
  ],
];

// gutter capacity (m² of roof) for sizes 3, 4, 5, 6, 7, 8, 10 in, by rate index
const List<List<double>> kGutterCapacities = <List<double>>[
  <double>[63, 133, 232, 356, 512, 739, 1337],
  <double>[42, 89, 154, 237, 341, 492, 891],
  <double>[31, 66, 116, 178, 256, 369, 668],
  <double>[15, 33, 58, 89, 128, 184, 334],
  <double>[12, 26, 46, 71, 102, 147, 267],
  <double>[10, 22, 38, 59, 85, 123, 222],
];

class StormResult {
  const StormResult({
    required this.verticalLeader,
    required this.horizontalLeader,
    required this.gutterSize,
    required this.gutterRatio,
    required this.gutterCount,
  });

  /// in
  final double verticalLeader;
  final double horizontalLeader;
  final double gutterSize;

  /// Roof area ÷ the capacity of the gutter picked.
  final double gutterRatio;
  final int gutterCount;
}

class StormWater {
  const StormWater._();

  static const double ft2ToM2 = 0.09290304;

  /// 5" → 6" and 7" → 8", like the original.
  static double stocked(double size) => size == 5 ? 6 : (size == 7 ? 8 : size);

  static double _lookup(List<StormStep> table, double area) {
    for (final StormStep s in table) {
      if (area <= s.maxArea) return s.size;
    }
    return table.last.size;
  }

  /// Index into [kGutterSizes] for [area] at [rateIndex]: the smallest
  /// gutter that holds it, else the biggest (10").
  static int _gutterIndex(double area, int rateIndex) {
    final List<double> caps = kGutterCapacities[rateIndex];
    for (int i = 0; i < caps.length - 1; i++) {
      if (area <= caps[i]) return i;
    }
    return caps.length - 1;
  }

  static StormResult calculate({
    required double roofAreaM2,
    required int rateIndex,
    required int slopeIndex,
  }) {
    final double a = roofAreaM2;
    final int g = _gutterIndex(a, rateIndex);
    final double ratio = a / kGutterCapacities[rateIndex][g];
    return StormResult(
      verticalLeader: stocked(_lookup(kVerticalLeaderTables[rateIndex], a)),
      horizontalLeader:
          stocked(_lookup(kHorizontalLeaderTables[slopeIndex][rateIndex], a)),
      gutterSize: stocked(kGutterSizes[g]),
      gutterRatio: ratio,
      gutterCount: math.max(1, ratio.ceil()),
    );
  }

  /// "Actual gutter" by number: the size each of [count] gutters needs.
  static double gutterSizeForCount({
    required double roofAreaM2,
    required int rateIndex,
    required int count,
  }) {
    final double each = roofAreaM2 / math.max(1, count);
    return stocked(kGutterSizes[_gutterIndex(each, rateIndex)]);
  }

  /// True when even 10" gutters cannot take the area at [count] gutters.
  static bool gutterCountTooSmall({
    required double roofAreaM2,
    required int rateIndex,
    required int count,
  }) =>
      roofAreaM2 / math.max(1, count) > kGutterCapacities[rateIndex].last;

  /// "Actual gutter" by diameter: how many [diameter]" gutters are needed.
  static int gutterCountForSize({
    required double roofAreaM2,
    required int rateIndex,
    required double diameter,
  }) {
    final int i = kGutterSizes.indexOf(diameter);
    final double cap = kGutterCapacities[rateIndex][i < 0 ? 0 : i];
    return math.max(1, (roofAreaM2 / cap).ceil());
  }
}
