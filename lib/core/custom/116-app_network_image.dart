/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 116-app_network_image.dart
/// Purpose: `AppNetworkImage` — every picture from the internet, CACHED
///          (16/11/2026): downloaded once, then read from the device. A drop-
///          in for `Image.network` (same arguments).
///
/// Phones and desktop keep the file on disk (cached_network_image). The
/// website leaves it to the browser's own cache, as `Image.network` did —
/// cross-site pictures still show there through [webHtmlElementStrategy].

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.loadingBuilder,
    this.frameBuilder,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.cacheWidth,
    this.cacheHeight,
    this.webHtmlElementStrategy = WebHtmlElementStrategy.never,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageFrameBuilder? frameBuilder;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final int? cacheWidth;
  final int? cacheHeight;
  final WebHtmlElementStrategy webHtmlElementStrategy;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _cacheBroken) return _plain();
    return Image(
      image: ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, CachedNetworkImageProvider(url)),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      loadingBuilder: loadingBuilder,
      frameBuilder: frameBuilder,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      // NEVER LOSE A PICTURE (16/11/2026): if the on-device cache cannot be
      // used (e.g. its storage plugin is not built into the app yet), the
      // picture is fetched the old way instead of disappearing — and every
      // picture after it skips the cache for the rest of the run.
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        if (_isCacheProblem(error)) _cacheBroken = true;
        return _plain();
      },
    );
  }

  /// Set once the cache itself failed (not just one missing picture).
  static bool _cacheBroken = false;

  static bool _isCacheProblem(Object e) {
    final String t = '$e';
    return t.contains('MissingPluginException') ||
        t.contains('sqflite') ||
        t.contains('DatabaseException') ||
        t.contains('FileSystemException');
  }

  Widget _plain() {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
        frameBuilder: frameBuilder,
        filterQuality: filterQuality,
        gaplessPlayback: gaplessPlayback,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        webHtmlElementStrategy: webHtmlElementStrategy,
      );
  }
}
