import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/permission_coordinator.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Edit profile screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _picker = ImagePicker();
  XFile? _newAvatar;
  bool _isSaving = false;
  UserProfile? _profile;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _profile = profile;
        _emailController.text = profile.email ?? '';
        _originalEmail = profile.email ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    VHaptics.light();
    final permissionInfo =
        await PermissionCoordinator.instance.ensurePhotoLibraryAccess(context);
    if (!mounted) return;
    if (!permissionInfo.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('permissions.photo_library_required'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      setState(() => _newAvatar = image);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newEmail = _emailController.text.trim();
    final isValidEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(newEmail);
    final emailChanged = newEmail != _originalEmail && isValidEmail;

    if (!emailChanged) {
      // Nothing to update — just pop with success
      VHaptics.success();
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = true);

    final success = await AuthService.instance.updateProfile(email: newEmail);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        VHaptics.success();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('profile.saved'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
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
        title: 'profile.edit_title'.tr(),
      ),
      bottomNavigationBar: BottomActionBarSurface(
        child: PrimaryButton(
          label: 'profile.save'.tr(),
          onPressed: _saveProfile,
          isLoading: _isSaving,
        ),
      ),
      body: SingleChildScrollView(
        padding: VSpace.screenH,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.v4,
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                      ),
                      child: _newAvatar != null
                          ? FutureBuilder<Widget>(
                              future: _buildAvatarImage(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) return snapshot.data!;
                                return Icon(
                                  VIcons.user,
                                  size: 48,
                                  color: VColors.textTer(context),
                                );
                              },
                            )
                          : _profile?.profilePhotoUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _profile!.profilePhotoUrl!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorWidget: (_, _, _) => Icon(
                                      VIcons.user,
                                      size: 48,
                                      color: VColors.textTer(context),
                                    ),
                                  ),
                                )
                              : Icon(
                                  VIcons.user,
                                  size: 48,
                                  color: VColors.textTer(context),
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: VColors.accentPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: VColors.bgPrimary, width: 3),
                          ),
                          child: Icon(
                            VIcons.camera,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              VSpace.v2,
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    'profile.change_photo'.tr(),
                    style: VType.label.copyWith(color: VColors.accentPrimary),
                  ),
                ),
              ),
              VSpace.v6,
              // Email
              Text(
                'settings.email'.tr(),
                style: VType.label.copyWith(color: VColors.text(context)),
              ),
              VSpace.v2,
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: VType.body.copyWith(color: VColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'email@example.com',
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
              SizedBox(height: VSpace.screenSectionGap),
            ],
          ),
        ),
      ),
    );
  }

  Future<Widget> _buildAvatarImage() async {
    final bytes = await _newAvatar!.readAsBytes();
    return ClipOval(
      child: Image.memory(
        bytes,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}
