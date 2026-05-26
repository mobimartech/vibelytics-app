import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/services/photos_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/utils/haptics.dart';
import '../../components/feedback/rating_stars.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../components/modals/reaction_picker.dart';
import '../../components/modals/app_bottom_sheet.dart';
import '../../components/modals/report_sheet.dart';
import '../../main_shell.dart';
import '../home/comments_screen.dart';

/// Full screen photo detail with ratings and comments
class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    required this.imageUrl,
    this.username,
    this.userAvatarUrl,
    this.currentRating,
    this.totalRatings,
  });

  final String photoId;
  final String imageUrl;
  final String? username;
  final String? userAvatarUrl;
  final double? currentRating;
  final int? totalRatings;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  int? _userRating;
  bool _showRatingPicker = false;
  bool _isSubmitting = false;
  int _totalRatings = 0;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _totalRatings = widget.totalRatings ?? 0;
    _avgRating = widget.currentRating ?? 0.0;
  }

  Future<void> _submitRating(int rating) async {
    setState(() {
      _userRating = rating;
      _showRatingPicker = false;
      _isSubmitting = true;
    });
    VHaptics.success();

    final photoId = int.tryParse(widget.photoId);
    if (photoId == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final result = await PhotosService.instance.ratePhoto(photoId, rating);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      CreditsService.instance.addCredits(result.creditsEarned);
      MainShell.refreshCredits(force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'activity.earned_credits'.tr(args: ['${result.creditsEarned}']),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.success,
        ),
      );
    } else {
      final errorKey = result.errorKey ?? 'photo.rate_failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorKey.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.error,
        ),
      );
      if (errorKey == 'photo.already_rated') {
        // keep the rating shown
      } else {
        setState(() => _userRating = null);
      }
    }
  }

  void _showOptions() {
    ActionSheet.show(
      context: context,
      actions: [
        ActionSheetItem(
          label: 'photo.comments'.tr(),
          icon: VIcons.comment,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommentsScreen(photoId: widget.photoId),
              ),
            );
          },
        ),
        ActionSheetItem(
          label: 'photo.share'.tr(),
          icon: VIcons.share,
          onTap: () {
            print("shre photo: ${widget.imageUrl}");
            SharePlus.instance.share(
              ShareParams(
                text: widget.imageUrl,
                subject: "Check out this image from vibelytics",
              ),
            );
          },
        ),
        ActionSheetItem(
          label: 'photo.report'.tr(),
          icon: VIcons.flag,
          isDestructive: true,
          onTap: () {
            _showReportSheet();
          },
        ),
      ],
    );
  }

  void _showReportSheet() {
    ReportSheet.show(
      context: context,
      contentType: ReportContentType.photo,
      contentId: widget.photoId,
      onReportSubmitted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('photo.reported'.tr()),
              behavior: SnackBarBehavior.floating,
              backgroundColor: VColors.success,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = VColors.adaptive(
      context,
      light: VColors.bgSec(context),
      dark: VColors.bgPrimaryDark,
    );
    final overlayBaseColor = isDark ? Colors.black : VColors.bgPrimary;
    final overlayTextColor = VColors.adaptive(
      context,
      light: VColors.text(context),
      dark: Colors.white,
    );
    final overlaySecondaryTextColor = VColors.adaptive(
      context,
      light: VColors.textSec(context),
      dark: Colors.white.withValues(alpha: 0.72),
    );
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: VColors.bgPrimaryDark,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: VColors.bgPrimary,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            GestureDetector(
              onTap: () {
                if (_showRatingPicker) {
                  setState(() => _showRatingPicker = false);
                }
              },
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const ShimmerSkeleton(),
                    errorWidget: (context, url, error) => Icon(
                      VIcons.image,
                      color: VColors.textTer(context),
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      overlayBaseColor.withValues(alpha: isDark ? 0.72 : 0.88),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(VSpace.space2),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(VIcons.back, color: overlayTextColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(VIcons.comment, color: overlayTextColor),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CommentsScreen(photoId: widget.photoId),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(VIcons.more, color: overlayTextColor),
                        onPressed: _showOptions,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom info bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.paddingOf(context).bottom +
                      VSpace.bottomBarVertical,
                  top: VSpace.screenSectionGap,
                  left: VSpace.bottomBarHorizontal,
                  right: VSpace.bottomBarHorizontal,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      overlayBaseColor.withValues(alpha: isDark ? 0.84 : 0.92),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info
                    if (widget.username != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: VColors.bgSec(context),
                            backgroundImage: widget.userAvatarUrl != null
                                ? CachedNetworkImageProvider(
                                    widget.userAvatarUrl!,
                                  )
                                : null,
                            child: widget.userAvatarUrl == null
                                ? Icon(
                                    VIcons.user,
                                    size: 20,
                                    color: VColors.textTer(context),
                                  )
                                : null,
                          ),
                          VSpace.h3,
                          Flexible(
                            child: Text(
                              '@${widget.username}',
                              style: VType.label.copyWith(
                                color: overlayTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    VSpace.v4,

                    // Rating section
                    if (_isSubmitting)
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            overlayTextColor,
                          ),
                        ),
                      )
                    else if (_userRating == null)
                      _RateButton(
                        onTap: () {
                          setState(() => _showRatingPicker = true);
                        },
                      )
                    else
                      _RatedDisplay(
                        rating: _userRating!,
                        onTapChange: () {
                          setState(() => _showRatingPicker = true);
                        },
                      ),

                    // Current rating display
                    if (_avgRating > 0) ...[
                      VSpace.v3,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RatingStars(
                            rating: _avgRating,
                            maxRating: 5,
                            size: 16,
                          ),
                          VSpace.h2,
                          Text(
                            _avgRating.toStringAsFixed(1),
                            style: VType.label.copyWith(
                              color: overlayTextColor,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          Text(
                            ' · ${'home.ratings_count'.tr(args: ['$_totalRatings'])}',
                            style: VType.caption.copyWith(
                              color: overlaySecondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Rating picker overlay
            if (_showRatingPicker)
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 120,
                left: VSpace.bottomBarHorizontal,
                right: VSpace.bottomBarHorizontal,
                child: ReactionPicker(
                  onRatingSelected: _submitRating,
                  initialRating: _userRating,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: VColors.accentPrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(VIcons.star, size: 20, color: Colors.white),
            VSpace.h2,
            Text(
              'photo.rate_this'.tr(),
              style: VType.label.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatedDisplay extends StatelessWidget {
  const _RatedDisplay({required this.rating, required this.onTapChange});

  final int rating;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: VColors.success.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VColors.success),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(VIcons.check, size: 16, color: VColors.success),
              VSpace.h2,
              Text(
                'photo.you_rated'.tr(args: ['$rating']),
                style: VType.label.copyWith(color: VColors.success),
              ),
            ],
          ),
        ),
        VSpace.h3,
        GestureDetector(
          onTap: onTapChange,
          child: Text(
            'photo.change'.tr(),
            style: VType.label.copyWith(
              color: VColors.adaptive(
                context,
                light: VColors.textSec(context),
                dark: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
