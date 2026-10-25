/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: fire_gas.dart
/// Purpose: Clean-agent fire suppression — FM-200 (Kidde pre-engineered
///          systems).
/// Author: ASEC team
/// Created: 22/10/2026
///
/// Pure Dart, works offline. Recovered from the "Plumbing & Fire
/// Calculator" (DPME) and checked against its screen.
///
/// FM-200:  W (kg) = V / S × C/(100 − C),  C = 7 %,  S = 0.1269 + 0.0005·T
///          (specific vapour volume, m³/kg, T in °C). The cylinder is the
///          smallest Kidde size that holds ⌈W⌉; each cylinder lists the
///          nozzle and the pipe limits for 1, 2 or 4 nozzles (Kidde tables
///          3.13.2-1 / 3.13.3-1 / 3.13.4-1, pages 129–131).
///          Fixed against the original: a layout that does not exist for a
///          cylinder is "not available" (the original left the previous
///          table on screen), and its 4-nozzle row for the 20 lb cylinder
///          — a copy of the 200 lb row — is dropped.
/// CO₂, Novec and aerosol: clean_agents.dart (25/10/2026).
library;

// ── FM-200 ────────────────────────────────────────────────────────────────

/// One pipe section of a Kidde layout.
class Fm200Section {
  const Fm200Section(this.name, this.pipeSize, this.maxLengthFt, this.maxElbows,
      [this.maxHeightFt = 12]);

  final String name;

  /// in
  final double pipeSize;
  final double maxLengthFt;
  final int maxElbows;
  final double maxHeightFt;
}

/// A nozzle layout of a cylinder.
class Fm200Layout {
  const Fm200Layout({required this.nozzleSize, required this.sections});

  /// in
  final double nozzleSize;
  final List<Fm200Section> sections;
}

enum Fm200Nozzles {
  one('One nozzle', 129, '3.13.2-1', 'Figure 3.13.2 – Single nozzle systems'),
  two('Two nozzles', 130, '3.13.3-1', 'Figure 3.13.3 – Two nozzle systems'),
  four('Four nozzles', 131, '3.13.4-1', 'Figure 3.13.4 – Four nozzle systems');

  const Fm200Nozzles(this.label, this.page, this.table, this.figure);

  final String label;
  final int page;
  final String table;
  final String figure;
}

class Fm200Cylinder {
  const Fm200Cylinder({
    required this.sizeLb,
    required this.maxAgentKg,
    required this.partNumber,
    this.one,
    this.two,
    this.four,
  });

  final int sizeLb;
  final double maxAgentKg;
  final String partNumber;
  final Fm200Layout? one;
  final Fm200Layout? two;
  final Fm200Layout? four;

  Fm200Layout? layout(Fm200Nozzles n) => switch (n) {
        Fm200Nozzles.one => one,
        Fm200Nozzles.two => two,
        Fm200Nozzles.four => four,
      };
}

const List<Fm200Cylinder> kFm200Cylinders = <Fm200Cylinder>[
  Fm200Cylinder(sizeLb: 10, maxAgentKg: 5, partNumber: '90-100010-001',
      one: Fm200Layout(nozzleSize: 0.5, sections: <Fm200Section>[Fm200Section('A', 0.5, 20, 8)])),
  Fm200Cylinder(sizeLb: 20, maxAgentKg: 9, partNumber: '90-100020-001',
      one: Fm200Layout(nozzleSize: 0.5, sections: <Fm200Section>[Fm200Section('A', 0.5, 20, 8)])),
  Fm200Cylinder(sizeLb: 40, maxAgentKg: 18, partNumber: '90-100040-001',
      one: Fm200Layout(nozzleSize: 1, sections: <Fm200Section>[Fm200Section('A', 1, 32, 8)]),
      two: Fm200Layout(nozzleSize: 1, sections: <Fm200Section>[Fm200Section('A', 1, 20, 8), Fm200Section('B', 1, 12, 4)])),
  Fm200Cylinder(sizeLb: 70, maxAgentKg: 32, partNumber: '90-100070-001',
      one: Fm200Layout(nozzleSize: 1, sections: <Fm200Section>[Fm200Section('A', 1, 32, 8)]),
      two: Fm200Layout(nozzleSize: 1, sections: <Fm200Section>[Fm200Section('A', 1.5, 20, 8), Fm200Section('B', 1, 12, 4)])),
  Fm200Cylinder(sizeLb: 125, maxAgentKg: 57, partNumber: '90-100125-001',
      one: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 2, 36, 8)]),
      two: Fm200Layout(nozzleSize: 1.5, sections: <Fm200Section>[Fm200Section('A', 1.5, 20, 8), Fm200Section('B', 1.5, 12, 4)])),
  Fm200Cylinder(sizeLb: 200, maxAgentKg: 91, partNumber: '90-100200-001',
      one: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 2.5, 36, 8)]),
      two: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 2.5, 16, 8), Fm200Section('B', 2, 10, 4)]),
      four: Fm200Layout(nozzleSize: 1.5, sections: <Fm200Section>[Fm200Section('A', 2.5, 16, 6), Fm200Section('B', 2, 10, 2), Fm200Section('C', 1.5, 8, 2)])),
  Fm200Cylinder(sizeLb: 350, maxAgentKg: 159, partNumber: '90-100350-001',
      two: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 3, 14, 4), Fm200Section('B', 2.5, 10, 3)]),
      four: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 3, 14, 2), Fm200Section('B', 2.5, 10, 2), Fm200Section('C', 2, 8, 2)])),
  Fm200Cylinder(sizeLb: 600, maxAgentKg: 227, partNumber: '90-100600-001',
      four: Fm200Layout(nozzleSize: 2, sections: <Fm200Section>[Fm200Section('A', 4, 14, 2), Fm200Section('B', 3, 12, 2), Fm200Section('C', 2.5, 10, 2)])),
];

class Fm200Result {
  const Fm200Result({
    required this.volume,
    required this.specificVolume,
    required this.agentWeight,
    required this.takeWeight,
    required this.cylinder,
  });

  /// m³
  final double volume;

  /// m³/kg at the ambient temperature
  final double specificVolume;

  /// kg (exact)
  final double agentWeight;

  /// kg, rounded up
  final double takeWeight;

  /// Null when more than the biggest cylinder (227 kg) is needed.
  final Fm200Cylinder? cylinder;
}

class Fm200 {
  const Fm200._();

  /// Design concentration, %.
  static const double concentration = 7;

  static double specificVolume(double ambientC) => 0.1269 + 0.0005 * ambientC;

  static Fm200Result calculate({
    required double areaM2,
    required double heightM,
    required double ambientC,
  }) {
    final double v = areaM2 * heightM;
    final double s = specificVolume(ambientC);
    final double w = v / s * concentration / (100 - concentration);
    final double take = w.ceilToDouble();
    Fm200Cylinder? cyl;
    for (final Fm200Cylinder c in kFm200Cylinders) {
      if (take <= c.maxAgentKg) {
        cyl = c;
        break;
      }
    }
    return Fm200Result(
      volume: v,
      specificVolume: s,
      agentWeight: w,
      takeWeight: take,
      cylinder: cyl,
    );
  }
}
