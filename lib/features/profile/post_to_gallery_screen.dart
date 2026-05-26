import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/photos_service.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/inputs/tag_chip.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Post photo to community gallery screen
class PostToGalleryScreen extends StatefulWidget {
  const PostToGalleryScreen({
    super.key,
    required this.photoId,
    this.previewImageUrl,
  });

  final String photoId;
  final String? previewImageUrl;

  @override
  State<PostToGalleryScreen> createState() => _PostToGalleryScreenState();
}

class _PostToGalleryScreenState extends State<PostToGalleryScreen> {
  final _captionController = TextEditingController();
  final Set<int> _selectedTagIds = {};
  bool _isPosting = false;
  List<PhotoTag> _tags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await PhotosService.instance.getTags();
    if (mounted) {
      setState(() {
        _tags = tags;
        _isLoadingTags = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _postToGallery() async {
    if (_selectedTagIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('gallery.select_tag'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.warning,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final result = await PhotosService.instance.postToGallery(
      aiPhotoId: int.tryParse(widget.photoId) ?? 0,
      tagIds: _selectedTagIds.toList(),
      isPublic: true,
      caption: _captionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isPosting = false);

      if (result.isSuccess) {
        VHaptics.success();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('gallery.posted_success'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result.errorKey ?? 'common.error').tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'gallery.post_title'.tr(),
      ),
      body: SingleChildScrollView(
        padding: VSpace.screenH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSpace.v4,
            // Photo preview
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: VRadii.xlRadius,
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.previewImageUrl != null &&
                        widget.previewImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.previewImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ShimmerSkeleton(),
                        errorWidget: (_, _, _) => Center(
                          child: Icon(
                            VIcons.image,
                            size: 64,
                            color: VColors.textTer(context),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          VIcons.image,
                          size: 64,
                          color: VColors.textTer(context),
                        ),
                      ),
              ),
            ),
            VSpace.v6,
            // Caption
            Text(
              'gallery.caption'.tr(),
              style: VType.label.copyWith(color: VColors.text(context)),
            ),
            VSpace.v2,
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'gallery.caption_hint'.tr(),
                hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
                filled: true,
                fillColor: VColors.bgSec(context),
                border: OutlineInputBorder(
                  borderRadius: VRadii.lgRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: VType.body.copyWith(color: VColors.text(context)),
            ),
            VSpace.v6,
            // Tags
            Text(
              'gallery.select_category'.tr(),
              style: VType.label.copyWith(color: VColors.text(context)),
            ),
            VSpace.v1,
            Text(
              'gallery.category_hint'.tr(),
              style: VType.bodySm.copyWith(color: VColors.textSec(context)),
            ),
            VSpace.v3,
            if (_isLoadingTags)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  4,
                  (_) => ShimmerSkeleton(
                    width: 80,
                    height: 32,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return TagChip(
                    label: tag.name,
                    isSelected: isSelected,
                    onTap: () {
                      VHaptics.light();
                      setState(() {
                        if (isSelected) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            VSpace.v6,
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VColors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: VRadii.lgRadius,
              ),
              child: Row(
                children: [
                  Icon(
                    VIcons.info,
                    size: 20,
                    color: VColors.accentPrimary,
                  ),
                  VSpace.h3,
                  Expanded(
                    child: Text(
                      'gallery.info_text'.tr(),
                      style: VType.bodySm.copyWith(color: VColors.accentPrimary),
                    ),
                  ),
                ],
              ),
            ),
            VSpace.v8,
            // Post button
            PrimaryButton(
              label: 'gallery.post_button'.tr(),
              onPressed: _postToGallery,
              isLoading: _isPosting,
            ),
            VSpace.v4,
          ],
        ),
      ),
    );
  }
}
