import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/state/profile_provider.dart';
import '../../core/widgets/app_bar_widgets.dart';
import '../settings/about_screen.dart';
import '../settings/settings_screen.dart';
import 'adherence_screen.dart';
import 'help_feedback_screen.dart';
import 'notebook_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _allergyCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _allergyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode(Profile profile) {
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _dobCtrl.text = profile.dob;
    _allergyCtrl.text = profile.allergies;
    setState(() => _isEditing = true);
  }

  void _cancelEdit(Profile profile) {
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _dobCtrl.text = profile.dob;
    _allergyCtrl.text = profile.allergies;
    setState(() => _isEditing = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 30),
    );
    if (_dobCtrl.text.isNotEmpty) {
      final parts = _dobCtrl.text.split('/');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.tryParse(parts[2]) ?? 1990,
          int.tryParse(parts[0]) ?? 1,
          int.tryParse(parts[1]) ?? 1,
        );
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _saveProfile(Profile currentProfile) {
    final notifier = ref.read(profileProvider.notifier);
    final p = currentProfile.copyWith(
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      dob: _dobCtrl.text,
      allergies: _allergyCtrl.text,
    );
    notifier.save(p);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          profileAsync.when(
            data: (profile) => AppMoreMenu(
              additionalItems: [
                if (!_isEditing)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit profile'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _enterEditMode(profile);
                    break;
                  case 'settings':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    break;
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) => _buildProfileView(context, profile),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, Profile profile) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildHeader(context, profile),
        const SizedBox(height: 24),
        _buildPersonalSection(context, profile),
        const SizedBox(height: 8),
        _buildNavigationSection(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Profile profile) {
    final theme = Theme.of(context);
    final String fullName = '${profile.firstName} ${profile.lastName}'.trim();
    final String displayName = fullName.isEmpty ? 'Guest User' : fullName;
    final String initials = fullName.isEmpty
        ? 'GU'
        : '${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}${profile.lastName.isNotEmpty ? profile.lastName[0] : ''}'
              .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(BuildContext context, Profile profile) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: () => _enterEditMode(profile),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              _buildEditField(
                controller: _firstNameCtrl,
                label: 'First Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildEditField(
                controller: _lastNameCtrl,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildEditField(
                    controller: _dobCtrl,
                    label: 'Date of Birth',
                    icon: Icons.cake_outlined,
                    suffixIcon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildEditField(
                controller: _allergyCtrl,
                label: 'Allergies',
                icon: Icons.warning_amber_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelEdit(profile),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _saveProfile(profile),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildProfileTile(
                context,
                icon: Icons.badge_outlined,
                label: 'Full Name',
                value: (profile.firstName.isEmpty && profile.lastName.isEmpty)
                    ? 'Not set'
                    : '${profile.firstName} ${profile.lastName}'.trim(),
              ),
              const Divider(height: 32),
              _buildProfileTile(
                context,
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: profile.dob.isEmpty ? 'Not set' : profile.dob,
              ),
              const Divider(height: 32),
              _buildProfileTile(
                context,
                icon: Icons.warning_amber_rounded,
                label: 'Allergies',
                value: profile.allergies.isEmpty ? 'None' : profile.allergies,
                isCritical: profile.allergies.isNotEmpty,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isCritical = false,
  }) {
    final theme = Theme.of(context);
    final color = isCritical
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCritical
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildNavigationButton(
            context,
            icon: Icons.book_outlined,
            title: 'Notebook',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotebookScreen()),
            ),
          ),
          _buildNavigationButton(
            context,
            icon: Icons.analytics_outlined,
            title: 'Adherence Metrics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdherenceScreen()),
            ),
          ),
          _buildNavigationButton(
            context,
            icon: Icons.help_outline,
            title: 'Help and Feedback',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HelpFeedbackScreen()),
            ),
          ),
          _buildNavigationButton(
            context,
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
