import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/photos_service.dart';
import '../buttons/primary_button.dart';
import 'app_bottom_sheet.dart';

/// Report content bottom sheet
enum ReportContentType {
  photo,
  comment,
}

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.contentType,
    required this.contentId,
    this.onReportSubmitted,
  });

  final ReportContentType contentType;
  final String contentId;
  final VoidCallback? onReportSubmitted;

  static Future<void> show({
    required BuildContext context,
    required ReportContentType contentType,
    required String contentId,
    VoidCallback? onReportSubmitted,
  }) {
    return AppBottomSheet.show(
      context: context,
      showHandle: true,
      child: ReportSheet(
        contentType: contentType,
        contentId: contentId,
        onReportSubmitted: onReportSubmitted,
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    'inappropriate_content',
    'spam',
    'harassment',
    'fake_profile',
    'copyright',
    'other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    final contentId = int.tryParse(widget.contentId) ?? 0;
    final description = _detailsController.text.trim().isNotEmpty
        ? _detailsController.text.trim()
        : null;

    final bool success;
    switch (widget.contentType) {
      case ReportContentType.comment:
        success = await PhotosService.instance.reportComment(
          contentId,
          _selectedReason!,
          description: description,
        );
        break;
      case ReportContentType.photo:
        success = await PhotosService.instance.reportPhoto(
          contentId,
          _selectedReason!,
          description: description,
        );
        break;
    }

    if (!mounted) return;

    if (success) {
      VHaptics.success();
      widget.onReportSubmitted?.call();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('report.submitted'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.success,
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('report.failed'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'report.title'.tr(),
          style: VType.h2.copyWith(color: VColors.text(context)),
        ),
        VSpace.v2,
        Text(
          'report.description'.tr(),
          style: VType.body.copyWith(color: VColors.textSec(context)),
        ),
        VSpace.v4,
        // Reason options
        ..._reasons.map((reason) => _ReasonOption(
              label: 'report.reason_$reason'.tr(),
              isSelected: _selectedReason == reason,
              onTap: () {
                VHaptics.light();
                setState(() => _selectedReason = reason);
              },
            )),
        VSpace.v4,
        // Additional details
        if (_selectedReason == 'other') ...[
          Text(
            'report.details_label'.tr(),
            style: VType.label.copyWith(color: VColors.text(context)),
          ),
          VSpace.v2,
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'report.details_hint'.tr(),
              hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
              filled: true,
              fillColor: VColors.bgSec(context),
              border: OutlineInputBorder(
                borderRadius: VRadii.lgRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          VSpace.v4,
        ],
        // Submit button
        PrimaryButton(
          label: 'report.submit'.tr(),
          onPressed: _selectedReason != null ? _submitReport : null,
          isLoading: _isSubmitting,
        ),
        VSpace.v2,
      ],
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: VColors.border(context)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? VColors.accentPrimary : VColors.borderStrong,
                  width: 2,
                ),
                color: isSelected ? VColors.accentPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            VSpace.h3,
            Expanded(
              child: Text(
                label,
                style: VType.body.copyWith(color: VColors.text(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
