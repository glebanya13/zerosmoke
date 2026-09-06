import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../data/app_state.dart';
import '../../data/repositories/users_repository.dart';
import '../auth/avatar_picker_sheet.dart';

/// Редактировать профиль.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int _selectedAvatar = 0;
  late bool _isMale;
  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _phone;
  late TextEditingController _email;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final user = state.isParent ? state.parentUser : state.childUser;
    _isMale = !user.isFemale;
    _selectedAvatar = user.avatarIndex;
    _name = TextEditingController(text: user.name);
    _age = TextEditingController(text: '${user.age}');
    _phone = TextEditingController(text: user.phone);
    _email = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    if (name.isEmpty || age == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните имя и возраст')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await context.read<UsersRepository>().updateMe(
        name: name,
        age: age,
        isFemale: !_isMale,
        avatarIndex: _selectedAvatar,
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      context.read<AppState>().applyAuthenticatedUser(user);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          MediaQuery.of(context).padding.top + 16,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          const ScreenHeader(title: 'Редактировать профиль'),
          const SizedBox(height: 24),
          const Text('Аватар', style: AppTextStyles.label),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AvatarCircle(
                    size: 100,
                    child: const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w200,
                          height: 1,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AvatarPickerSheet(),
                    ),
                  ),
                ),
                for (int i = 0; i < avatarAssets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AvatarCircle(
                      size: 100,
                      avatarIndex: i,
                      selected: _selectedAvatar == i,
                      onTap: () => setState(() => _selectedAvatar = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Имя', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(controller: _name),
          const SizedBox(height: AppSpacing.md),
          const Text('Возраст', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(controller: _age, keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          const Text('Пол', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          SegmentedToggle(
            leftLabel: 'Ж',
            rightLabel: 'М',
            isRightSelected: _isMale,
            onChanged: (v) => setState(() => _isMale = v),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Телефон', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(controller: _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: AppSpacing.md),
          const Text('Электронная почта', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(controller: _email, keyboardType: TextInputType.emailAddress, enabled: false),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isLoading ? 'Сохранение...' : 'Сохранить',
            onPressed: _isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
