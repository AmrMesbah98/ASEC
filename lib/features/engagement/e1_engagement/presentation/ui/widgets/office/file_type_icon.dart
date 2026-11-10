/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: file_type_icon.dart
/// Purpose: Declares `FileTypeIcon` — a small "document" tile that says
///          what a file is at a glance: green X for Excel, blue W for Word,
///          orange P for PowerPoint, red PDF, purple picture for images, …
///          Used by the file cards, the file rows and the file viewer.
/// Author: ASEC team
/// Created: 08/11/2026

import 'package:flutter/material.dart';

import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';

class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.extension, this.size = 40});

  /// "xlsx", "pdf", … (lower case, no dot).
  final String extension;

  /// The tile's width; its height is 1.2 × that (a page).
  final double size;

  /// The letters on the tile; empty = an icon instead.
  static String labelOf(String extension) {
    switch (extension) {
      case 'xls':
      case 'xlsx':
      case 'xlsm':
      case 'csv':
        return 'X';
      case 'doc':
      case 'docx':
        return 'W';
      case 'ppt':
      case 'pptx':
        return 'P';
      case 'pdf':
        return 'PDF';
      case 'dwg':
      case 'dxf':
        return 'CAD';
      case 'zip':
      case 'rar':
        return 'ZIP';
      case 'txt':
      case 'md':
        return 'TXT';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = fileColors(extension);
    final String label = labelOf(extension);
    final double w = size;
    final double h = size * 1.2;
    final double fold = size * 0.3;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: <Widget>[
          // The page, with its top corner cut for the fold.
          Positioned.fill(
            child: ClipPath(
              clipper: _FoldedPage(fold),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(size * 0.14),
                ),
              ),
            ),
          ),
          // The fold itself.
          Positioned(
            top: 0,
            right: 0,
            child: ClipPath(
              clipper: _FoldCorner(),
              child: Container(
                width: fold,
                height: fold,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(size * 0.08)),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: fold * 0.6,
            child: Center(
              child: label.isEmpty
                  ? Icon(fileIcon(extension), size: size * 0.5, color: Colors.white)
                  : Text(
                      label,
                      maxLines: 1,
                      style: StyleText.fontSize14Weight700.copyWith(
                        color: Colors.white,
                        fontSize: size * (label.length == 1 ? 0.5 : 0.28),
                        height: 1,
                        letterSpacing: label.length == 1 ? 0 : 0.4,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page whose top-right corner is cut off diagonally.
class _FoldedPage extends CustomClipper<Path> {
  const _FoldedPage(this.fold);

  final double fold;

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width - fold, 0)
    ..lineTo(s.width, fold)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant _FoldedPage old) => old.fold != fold;
}

/// The triangle that sits in the cut corner.
class _FoldCorner extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
