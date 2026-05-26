import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../core/services/photos_service.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/utils/app_logger.dart';
import '../profile/post_to_gallery_screen.dart';

/// Enhanced photos gallery with before/after comparison.
class EnhanceGalleryScreen extends StatefulWidget {
  const EnhanceGalleryScreen({
    super.key,
    this.photos,
    this.referencePhotoBase64,
    this.enhancedPhotoIds,
    this.loadFromApi = false,
    this.initialIndex = 0,
  });

  /// List of enhanced photo URLs (CDN or Replicate URLs).
  final List<String>? photos;

  /// Original reference photo as base64 data URI.
  final String? referencePhotoBase64;

  /// Enhanced photo IDs from API (for posting to gallery).
  final List<int>? enhancedPhotoIds;

  /// If true, load enhanced photos from API (for reopening after app close).
  final bool loadFromApi;

  /// Photo index to focus when opening the gallery from a saved-library entry.
  final int initialIndex;

  @override
  State<EnhanceGalleryScreen> createState() => _EnhanceGalleryScreenState();
}

class _EnhanceGalleryScreenState extends State<EnhanceGalleryScreen> {
  int _selectedIndex = 0;
  List<String> _loadedPhotos = [];
  List<int> _loadedPhotoIds = [];
  bool _isLoadingFromApi = false;
  bool _isSharingPhoto = false;

  List<String> get _photoUrls =>
      _loadedPhotos.isNotEmpty ? _loadedPhotos : (widget.photos ?? []);

  List<int> get _photoIds => _loadedPhotoIds.isNotEmpty
      ? _loadedPhotoIds
      : (widget.enhancedPhotoIds ?? []);

  @override
  void initState() {
    super.initState();
    if (widget.loadFromApi && (widget.photos == null || widget.photos!.isEmpty)) {
      _loadFromApi();
    } else if ((widget.photos ?? const []).isNotEmpty) {
      _selectedIndex = widget.initialIndex.clamp(0, widget.photos!.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefetchAdjacent();
      });
    }
  }

  Future<void> _loadFromApi() async {
    setState(() => _isLoadingFromApi = true);
    try {
      final result = await PhotosService.instance.getEnhancedPhotos();
      if (mounted) {
        setState(() {
          _loadedPhotos = result.photos.map((p) => p.photoUrl).toList();
          _loadedPhotoIds = result.photos.map((p) => p.id).toList();
          _selectedIndex = widget.initialIndex.clamp(
            0,
            result.photos.isEmpty ? 0 : result.photos.length - 1,
          );
          _isLoadingFromApi = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _prefetchAdjacent();
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load enhanced photos from API', error: e);
      if (mounted) {
        setState(() => _isLoadingFromApi = false);
      }
    }
  }

  void _selectPhoto(int index) {
    if (_photoUrls.isEmpty) return;
    VHaptics.light();
    setState(() {
      _selectedIndex = index.clamp(0, _photoUrls.length - 1);
    });
    _prefetchAdjacent();
  }

  /// Warm the cached_network_image cache for the photos on either side of
  /// the selected index so the next swipe doesn't show a placeholder flash.
  void _prefetchAdjacent() {
    final urls = _photoUrls;
    if (urls.length < 2) return;
    for (final offset in const [-1, 1, 2]) {
      final i = _selectedIndex + offset;
      if (i < 0 || i >= urls.length) continue;
      final url = urls[i];
      if (url.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  Future<File> _downloadPhoto(String url, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await Dio().download(url, file.path);
    return file;
  }

  Future<void> _saveToGallery(List<String> urls) async {
    if (urls.isEmpty) return;

    try {
      final permissionInfo =
          await PermissionCoordinator.instance.ensureGallerySaveAccess(
        context,
      );
      if (!mounted) return;
      if (!permissionInfo.isAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permissions.gallery_save_required'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
        return;
      }

      for (var i = 0; i < urls.length; i++) {
        final url = urls[i];
        if (url.isEmpty) continue;
        final file = await _downloadPhoto(
          url,
          'vibelytics_enhanced_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        await Gal.putImage(file.path, album: 'Vibelytics');
      }

      if (!mounted) return;
      VHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            urls.length == 1
                ? 'enhance.photo_saved'.tr()
                : 'enhance.all_saved'.tr(args: ['${urls.length}']),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.success,
        ),
      );
    } on GalException catch (e) {
      AppLogger.e('Failed to save enhanced photo to gallery', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.error,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to download enhanced photo', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.error,
        ),
      );
    }
  }

  Future<void> _savePhoto() async {
    if (_photoUrls.isEmpty) return;
    final idx = _selectedIndex.clamp(0, _photoUrls.length - 1);
    await _saveToGallery([_photoUrls[idx]]);
  }

  Future<void> _saveAll() async {
    await _saveToGallery(_photoUrls.where((url) => url.isNotEmpty).toList());
  }

  Future<void> _sharePhoto() async {
    VHaptics.light();
    if (_photoUrls.isEmpty || _isSharingPhoto) return;

    try {
      setState(() => _isSharingPhoto = true);
      final url = _photoUrls[_selectedIndex.clamp(0, _photoUrls.length - 1)];
      final file = await _downloadPhoto(
        url,
        'vibelytics_share_${DateTime.now().millisecondsSinceEpoch}_$_selectedIndex.jpg',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'enhance.share_message'.tr(args: ['Vibelytics']),
        ),
      );
    } catch (e) {
      AppLogger.e('Share photo error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingPhoto = false);
      }
    }
  }

  void _postToGallery() {
    if (_photoUrls.isEmpty) return;
    VHaptics.light();
    final idx = _selectedIndex.clamp(0, _photoUrls.length - 1);
    final photoId = idx < _photoIds.length ? _photoIds[idx] : idx;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostToGalleryScreen(
          photoId: '$photoId',
          previewImageUrl: _photoUrls[idx],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingFromApi) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasPhotos = _photoUrls.isNotEmpty;

    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.enhanced_photos'.tr(),
        actions: hasPhotos
            ? [
                TextButton(
                  onPressed: _saveAll,
                  child: Text(
                    'enhance.save_all'.tr(),
                    style: VType.label.copyWith(color: VColors.accentPrimary),
                  ),
                ),
              ]
            : null,
      ),
      body: !hasPhotos
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(VIcons.image, size: 64, color: VColors.textTer(context)),
                  VSpace.v4,
                  Text(
                    'enhance.no_photos'.tr(),
                    style: VType.body.copyWith(color: VColors.textSec(context)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 55,
                  child: _BeforeAfterViewer(
                    key: ValueKey('beforeAfter-$_selectedIndex'),
                    photoUrl: _photoUrls[_selectedIndex],
                    referencePhotoBase64: widget.referencePhotoBase64,
                  ),
                ),
                Padding(
                  padding: VSpace.screenH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VSpace.v4,
                      Text(
                        'enhance.ai_enhanced'.tr(
                          args: ['${_selectedIndex + 1}/${_photoUrls.length}'],
                        ),
                        style: VType.h3.copyWith(color: VColors.text(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      VSpace.v1,
                      Text(
                        'enhance.generated_from_analysis'.tr(),
                        style: VType.body.copyWith(
                          color: VColors.textSec(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                VSpace.v4,
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: VSpace.screenH,
                    itemCount: _photoUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      return GestureDetector(
                        onTap: () => _selectPhoto(index),
                        child: Container(
                          width: 64,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: VColors.adaptive(
                              context,
                              light: VColors.bgSec(context),
                              dark: VColors.bgSecondaryDark,
                            ),
                            borderRadius: VRadii.mdRadius,
                            border: isSelected
                                ? Border.all(
                                    color: VColors.accentPrimary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _photoUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ShimmerSkeleton(),
                            errorWidget: (_, _, _) => Center(
                              child: Icon(
                                VIcons.image,
                                size: 24,
                                color: isSelected
                                    ? VColors.accentPrimary
                                    : VColors.textTer(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                VSpace.v4,
                BottomActionBarSurface(
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: VIcons.save,
                        onTap: _savePhoto,
                      ),
                      VSpace.h3,
                      Expanded(
                        child: PrimaryButton(
                          label: 'enhance.post_to_gallery'.tr(),
                          onPressed: _postToGallery,
                        ),
                      ),
                      VSpace.h3,
                      _ActionButton(
                        icon: VIcons.share,
                        isLoading: _isSharingPhoto,
                        onTap: _sharePhoto,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _BeforeAfterViewer extends StatefulWidget {
  const _BeforeAfterViewer({
    super.key,
    required this.photoUrl,
    this.referencePhotoBase64,
  });

  final String photoUrl;
  final String? referencePhotoBase64;

  @override
  State<_BeforeAfterViewer> createState() => _BeforeAfterViewerState();
}

class _BeforeAfterViewerState extends State<_BeforeAfterViewer> {
  /// Slider position in [0.0, 1.0]. Backed by a notifier so drag updates
  /// only repaint the clipper + handle, not the underlying images.
  final ValueNotifier<double> _position = ValueNotifier<double>(0.5);

  /// Decoded once in [initState]; re-used across rebuilds and drags.
  Uint8List? _referenceBytes;

  @override
  void initState() {
    super.initState();
    _decodeReference();
  }

  @override
  void didUpdateWidget(covariant _BeforeAfterViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referencePhotoBase64 != widget.referencePhotoBase64) {
      _decodeReference();
    }
  }

  void _decodeReference() {
    final raw = widget.referencePhotoBase64;
    if (raw == null || raw.isEmpty) {
      _referenceBytes = null;
      return;
    }
    try {
      _referenceBytes = _decodeBase64(raw);
    } catch (_) {
      _referenceBytes = null;
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _setPosition(double value, double width) {
    final next = value.clamp(0.0, 1.0);
    if ((next - _position.value).abs() < 1 / width) return;
    // Edge haptic when slammed to 0 or 1
    if ((next == 0 || next == 1) && next != _position.value) {
      VHaptics.light();
    }
    _position.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final hasReference = _referenceBytes != null;

    if (!hasReference) {
      return Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _EnhancedPhotoSurface(photoUrl: widget.photoUrl),
            ),
          ),
          _afterPill(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The slider geometry is logical-LTR (drag right reveals after) so
        // the comparison feels identical across LTR and RTL locales. Force
        // LTR for this subtree even when the app is in RTL.
        return Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Semantics(
            slider: true,
            label: 'enhance.compare'.tr(),
            value: '${(_position.value * 100).round()}%',
            onIncrease: () => _setPosition(_position.value + 0.05, width),
            onDecrease: () => _setPosition(_position.value - 0.05, width),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _setPosition(d.localPosition.dx / width, width),
              onHorizontalDragStart: (d) =>
                  _setPosition(d.localPosition.dx / width, width),
              onHorizontalDragUpdate: (d) =>
                  _setPosition(d.localPosition.dx / width, width),
              child: Stack(
            children: [
              // Reference (before) — decoded once, never re-decoded
              Positioned.fill(
                child: RepaintBoundary(
                  child: Image.memory(
                    _referenceBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: VColors.bgTer(context)),
                  ),
                ),
              ),
              // Enhanced (after) — clipped via ValueListenable so only
              // the clipper repaints when the slider moves.
              Positioned.fill(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _position,
                    builder: (_, pos, child) => ClipRect(
                      clipper: _HorizontalClipper(pos),
                      child: child,
                    ),
                    child: _EnhancedPhotoSurface(photoUrl: widget.photoUrl),
                  ),
                ),
              ),
              // Divider line + handle — only this layer rebuilds on drag.
              ValueListenableBuilder<double>(
                valueListenable: _position,
                builder: (_, pos, _) {
                  final handleX = (width * pos).clamp(0.0, width);
                  return Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: handleX - 1.5,
                        child: const _DividerLine(),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: handleX - 22,
                        child: const Center(child: _DragHandle()),
                      ),
                    ],
                  );
                },
              ),
              _beforePill(),
              _afterPill(),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _beforePill() => Positioned(
        bottom: 16,
        left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'enhance.before'.tr(),
            style: VType.labelSm.copyWith(color: Colors.white),
          ),
        ),
      );

  Widget _afterPill() => Positioned(
        bottom: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: VColors.aiGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'enhance.after'.tr(),
            style: VType.labelSm.copyWith(color: Colors.white),
          ),
        ),
      );
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(VIcons.back, size: 14, color: VColors.text(context)),
          Icon(VIcons.forward, size: 14, color: VColors.text(context)),
        ],
      ),
    );
  }
}

/// Surface that renders the AI-enhanced (after) photo.
///
/// Robust caching strategy:
/// - [CachedNetworkImage] caches both in-memory and on disk.
/// - `memCacheWidth` is set to the laid-out width × device pixel ratio so the
///   image decodes at display size instead of full resolution (typically a
///   10× memory reduction for 4K outputs on a phone).
/// - `maxWidthDiskCache` caps the disk-cached file to a sensible upper bound.
/// - `useOldImageOnUrlChange: true` avoids a placeholder flash when the
///   surrounding widget rebuilds with a new URL.
/// - On error, a tappable "retry" widget bumps `_retryCount`, which feeds into
///   the `cacheKey` so the framework discards the failed entry and refetches.
class _EnhancedPhotoSurface extends StatefulWidget {
  const _EnhancedPhotoSurface({required this.photoUrl});

  final String photoUrl;

  @override
  State<_EnhancedPhotoSurface> createState() => _EnhancedPhotoSurfaceState();
}

class _EnhancedPhotoSurfaceState extends State<_EnhancedPhotoSurface> {
  int _retryCount = 0;

  void _retry() {
    VHaptics.light();
    setState(() => _retryCount++);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl;
    if (url.isEmpty) return _EmptyAfter();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at the display size in physical pixels — drops decoded bytes
        // from e.g. 60 MB (4K RGBA) to ~3 MB for a 1080p-equivalent phone.
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final memWidth = (constraints.maxWidth * dpr).round().clamp(1, 4096);

        return CachedNetworkImage(
          imageUrl: url,
          cacheKey: _retryCount == 0 ? null : '$url#retry=$_retryCount',
          fit: BoxFit.cover,
          memCacheWidth: memWidth,
          maxWidthDiskCache: 2048,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 80),
          useOldImageOnUrlChange: true,
          placeholder: (_, _) => const _LoadingSurface(),
          errorWidget: (_, _, _) => _ErrorSurface(onRetry: _retry),
        );
      },
    );
  }
}

class _EmptyAfter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.adaptive(
        context,
        light: VColors.bgSec(context),
        dark: VColors.bgSecondaryDark,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  VColors.aiGradient.createShader(bounds),
              child: Icon(VIcons.ai, size: 64, color: Colors.white),
            ),
            VSpace.v2,
            ShaderMask(
              shaderCallback: (bounds) =>
                  VColors.aiGradient.createShader(bounds),
              child: Text(
                'enhance.after'.tr(),
                style: VType.label.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSurface extends StatelessWidget {
  const _LoadingSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.adaptive(
        context,
        light: VColors.bgSec(context),
        dark: VColors.bgSecondaryDark,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.adaptive(
        context,
        light: VColors.bgSec(context),
        dark: VColors.bgSecondaryDark,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              VIcons.image,
              size: 56,
              color: VColors.textTer(context),
            ),
            VSpace.v3,
            Text(
              'enhance.failed'.tr(),
              style: VType.bodySm.copyWith(color: VColors.textSec(context)),
              textAlign: TextAlign.center,
            ),
            VSpace.v3,
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(VIcons.refresh, size: 18),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decode a base64 data URI (`data:image/jpeg;base64,...`) to bytes.
///
/// Tolerates: missing `data:` prefix (raw base64), whitespace inside the
/// payload, and base64url variants. Throws [FormatException] only when the
/// payload truly cannot be decoded.
Uint8List _decodeBase64(String dataUri) {
  if (dataUri.isEmpty) {
    throw const FormatException('empty data URI');
  }
  final commaIndex = dataUri.indexOf(',');
  var b64 = commaIndex >= 0 ? dataUri.substring(commaIndex + 1) : dataUri;
  // Strip whitespace/newlines that some encoders insert every 76 chars.
  b64 = b64.replaceAll(RegExp(r'\s'), '');
  // base64url → base64
  b64 = b64.replaceAll('-', '+').replaceAll('_', '/');
  // Pad to multiple of 4
  final padding = b64.length % 4;
  if (padding > 0) b64 = b64.padRight(b64.length + (4 - padding), '=');
  return base64Decode(b64);
}

class _HorizontalClipper extends CustomClipper<Rect> {
  _HorizontalClipper(this.position);

  final double position;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      size.width * position,
      0,
      size.width * (1 - position),
      size.height,
    );
  }

  @override
  bool shouldReclip(_HorizontalClipper oldClipper) =>
      position != oldClipper.position;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: VColors.borderStrong),
          borderRadius: VRadii.lgRadius,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: VColors.accentPrimary,
                  ),
                )
              : Icon(
                  icon,
                  color: VColors.text(context),
                ),
        ),
      ),
    );
  }
}
