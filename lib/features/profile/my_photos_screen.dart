import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/photos_service.dart';
import '../../components/navigation/tab_bar_segment.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../photo/photo_detail_screen.dart';
import 'post_to_gallery_screen.dart';

/// My photos screen showing user's uploaded photos
class MyPhotosScreen extends StatefulWidget {
  const MyPhotosScreen({super.key});

  @override
  State<MyPhotosScreen> createState() => _MyPhotosScreenState();
}

class _MyPhotosScreenState extends State<MyPhotosScreen> {
  int _selectedTab = 0;
  bool _isSelectionMode = false;
  final Set<int> _selectedPhotoIds = {};

  List<FeedPhoto> _allPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final result = await PhotosService.instance.getMyPhotos();

    if (mounted) {
      setState(() {
        _allPhotos = result.photos;
        _isLoading = false;
      });
    }
  }

  List<FeedPhoto> get _filteredPhotos {
    // Tab 0 = All, Tab 1 = Published (public), Tab 2 = Drafts (private)
    return _allPhotos;
  }

  void _toggleSelection(int photoId) {
    VHaptics.light();
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
        if (_selectedPhotoIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPhotoIds.add(photoId);
      }
    });
  }

  void _enterSelectionMode(int photoId) {
    VHaptics.medium();
    setState(() {
      _isSelectionMode = true;
      _selectedPhotoIds.add(photoId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPhotoIds.clear();
    });
  }

  void _deleteSelected() {
    VHaptics.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.delete_photos'.tr()),
        content: Text(
          'profile.delete_photos_confirm'.tr(args: [_selectedPhotoIds.length.toString()]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (final id in _selectedPhotoIds) {
                await PhotosService.instance.deletePhoto(id);
              }
              _exitSelectionMode();
              _loadPhotos();
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: VColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(VIcons.back, color: VColors.text(context)),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: Icon(VIcons.back, color: VColors.text(context)),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: _isSelectionMode
            ? '${_selectedPhotoIds.length} ${'common.selected'.tr()}'
            : 'profile.my_photos'.tr(),
        showBackButton: false,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(VIcons.delete, color: VColors.error),
              onPressed: _selectedPhotoIds.isNotEmpty ? _deleteSelected : null,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TabBarPills(
              tabs: [
                'profile.all'.tr(),
                'profile.published'.tr(),
                'profile.drafts'.tr(),
              ],
              selectedIndex: _selectedTab,
              onTabChanged: (index) {
                setState(() => _selectedTab = index);
              },
            ),
          ),
          // Photo grid
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredPhotos.isEmpty
                    ? _buildEmptyState()
                    : MasonryGridView.count(
                        padding: VSpace.screenH,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: _filteredPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = _filteredPhotos[index];
                          final isSelected = _selectedPhotoIds.contains(photo.id);

                          return _PhotoGridItem(
                            photo: photo,
                            isSelected: isSelected,
                            isSelectionMode: _isSelectionMode,
                            index: index,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(photo.id);
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PhotoDetailScreen(
                                      photoId: photo.id.toString(),
                                      imageUrl: photo.photoUrl,
                                      currentRating: photo.averageRating > 0
                                          ? photo.averageRating
                                          : null,
                                      totalRatings: photo.totalRatings,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _enterSelectionMode(photo.id);
                              }
                            },
                            onPublish: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PostToGalleryScreen(
                                    photoId: photo.id.toString(),
                                    previewImageUrl: photo.photoUrl,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return MasonryGridView.count(
      padding: VSpace.screenH,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 4,
      itemBuilder: (_, index) {
        final height = 150.0 + (index % 3) * 50;
        return ShimmerSkeleton(
          height: height,
          borderRadius: VRadii.lgRadius,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VIcons.image,
            size: 64,
            color: VColors.textTer(context),
          ),
          VSpace.v4,
          Text(
            'profile.no_photos_title'.tr(),
            style: VType.screenSectionTitle.copyWith(
              color: VColors.text(context),
            ),
          ),
          VSpace.v2,
          Text(
            'profile.no_photos_desc'.tr(),
            style: VType.body.copyWith(color: VColors.textSec(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  const _PhotoGridItem({
    required this.photo,
    required this.isSelected,
    required this.isSelectionMode,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onPublish,
  });

  final FeedPhoto photo;
  final bool isSelected;
  final bool isSelectionMode;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final height = 150.0 + (index % 3) * 50;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          borderRadius: VRadii.lgRadius,
          border: isSelected
              ? Border.all(color: VColors.accentPrimary, width: 3)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo.photoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerSkeleton(),
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    VIcons.image,
                    size: 32,
                    color: VColors.textTer(context),
                  ),
                ),
              )
            else
              Center(
                child: Icon(
                  VIcons.image,
                  size: 32,
                  color: VColors.textTer(context),
                ),
              ),
            // Selection checkbox
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? VColors.accentPrimary : Colors.white,
                    border: Border.all(
                      color: isSelected ? VColors.accentPrimary : VColors.borderStrong,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(VIcons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            // Rating badge
            if (photo.totalRatings > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(VIcons.star, size: 12, color: VColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        photo.averageRating.toStringAsFixed(1),
                        style: VType.caption.copyWith(color: Colors.white),
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
}
