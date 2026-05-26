import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/photos_service.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../enhance/enhance_gallery_screen.dart';

/// Enhanced photos library screen
class EnhancedLibraryScreen extends StatefulWidget {
  const EnhancedLibraryScreen({super.key});

  @override
  State<EnhancedLibraryScreen> createState() => _EnhancedLibraryScreenState();
}

class _EnhancedLibraryScreenState extends State<EnhancedLibraryScreen> {
  List<EnhancedPhoto> _photos = [];
  bool _isLoading = true;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final result = await PhotosService.instance.getEnhancedPhotos();

    if (mounted) {
      setState(() {
        _photos = result.photos;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await PhotosService.instance.getEnhancedPhotos(
      offset: _photos.length,
    );

    if (mounted) {
      setState(() {
        _photos.addAll(result.photos);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    }
  }

  bool _isDeleting = false;

  Future<void> _deletePhoto(EnhancedPhoto photo, int index) async {
    if (_isDeleting || index >= _photos.length) return;
    _isDeleting = true;

    final success = await PhotosService.instance.deleteEnhancedPhoto(photo.id);
    _isDeleting = false;
    if (success && mounted && index < _photos.length) {
      setState(() => _photos.removeAt(index));
      VHaptics.success();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'profile.enhanced_library'.tr(),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _photos.isEmpty
              ? _buildEmptyState()
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 200) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: VSpace.screenH.add(const EdgeInsets.only(top: 16)),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _photos.length + (_isLoadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _photos.length) {
                        return ShimmerSkeleton(borderRadius: VRadii.xlRadius);
                      }
                      return _EnhancedPhotoCard(
                        photo: _photos[index],
                        onTap: () => _openComparison(index),
                        onDelete: () => _deletePhoto(_photos[index], index),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: VSpace.screenH.add(const EdgeInsets.only(top: 16)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => ShimmerSkeleton(borderRadius: VRadii.xlRadius),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: VSpace.screenH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: VColors.aiGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                VIcons.photoEnhance,
                size: 40,
                color: Colors.white,
              ),
            ),
            VSpace.v4,
            Text(
              'profile.no_enhanced_title'.tr(),
              style: VType.h3.copyWith(color: VColors.text(context)),
            ),
            VSpace.v2,
            Text(
              'profile.no_enhanced_desc'.tr(),
              style: VType.body.copyWith(color: VColors.textSec(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openComparison(int index) {
    VHaptics.light();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnhanceGalleryScreen(
          photos: _photos.map((photo) => photo.photoUrl).toList(),
          enhancedPhotoIds: _photos.map((photo) => photo.id).toList(),
          initialIndex: index,
        ),
      ),
    );
  }
}

class _EnhancedPhotoCard extends StatelessWidget {
  const _EnhancedPhotoCard({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final EnhancedPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photo
            ClipRRect(
              borderRadius: VRadii.xlRadius,
              child: photo.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photo.photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, _) => const ShimmerSkeleton(),
                      errorWidget: (_, _, _) => Container(
                        color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                        child: Center(
                          child: Icon(
                            VIcons.image,
                            size: 48,
                            color: VColors.textTer(context),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                      child: Center(
                        child: Icon(
                          VIcons.image,
                          size: 48,
                          color: VColors.textTer(context),
                        ),
                      ),
                    ),
            ),
            // Enhanced badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: VColors.aiGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(VIcons.ai, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: VType.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(photo.createdAt),
                      style: VType.caption.copyWith(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        VIcons.delete,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
