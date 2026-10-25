/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: agent_fields.dart
/// Purpose: Shared pieces of the Novec / Aerosol / CO₂ tabs — a State base
///          that owns its number fields, the enclosure inputs (L, W, H,
///          voids, excluded), a section heading and the "preliminary"
///          note from the ASEC gas calculator workbook.
/// Author: ASEC team
/// Created: 25/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';

/// A tab State that creates, reads and disposes its number fields by key.
abstract class AgentTabState<T extends StatefulWidget> extends State<T> {
  final Map<String, TextEditingController> _fields = <String, TextEditingController>{};

  /// The field [key], created with [initial] the first time.
  TextEditingController field(String key, num initial) => _fields.putIfAbsent(
        key,
        () => TextEditingController(
          text: initial == initial.roundToDouble() ? initial.toStringAsFixed(0) : '$initial',
        ),
      );

  /// The number in field [key], or null when empty / invalid.
  double? value(String key) => parseNumber(_fields[key]?.text ?? '');

  void changed(String _) => setState(() {});

  /// A number field bound to [key].
  Widget number(String key, num initial, String label, [String? unit]) =>
      NumberField(controller: field(key, initial), label: label, unit: unit, onChanged: changed);

  /// Length, width, height, voids and excluded volume — the workbook's
  /// 5 × 5 × 5 m example room.
  List<Widget> enclosureFields() => <Widget>[
        number('l', 5, 'Length', 'm'),
        number('w', 5, 'Width', 'm'),
        number('h', 5, 'Height', 'm'),
        number('voids', 0, 'Additional voids', 'm³'),
        number('excluded', 0, 'Excluded volume', 'm³'),
      ];

  /// The net protected volume, or null until L, W and H are valid.
  double? netVolumeFromFields() {
    final double? l = value('l');
    final double? w = value('w');
    final double? h = value('h');
    if (l == null || w == null || h == null || l <= 0 || w <= 0 || h <= 0) return null;
    return netVolume(
      length: l,
      width: w,
      height: h,
      voids: value('voids') ?? 0,
      excluded: value('excluded') ?? 0,
    );
  }

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class AgentHeading extends StatelessWidget {
  const AgentHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(text, style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text)),
      );
}

/// The workbook's warning, shown under every result.
class PreliminaryNote extends StatelessWidget {
  const PreliminaryNote(this.detail, {super.key});

  final String detail;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.containerR,
        ),
        child: Text(
          'PRELIMINARY SIZING ONLY — verify hazard, approved manufacturer listing, '
          'hydraulic calculations & AHJ requirements.\n$detail',
          style: StyleText.fontSize12Weight500.copyWith(color: AppColors.secondaryText),
        ),
      );
}
