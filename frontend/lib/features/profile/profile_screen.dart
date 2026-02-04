import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/state/profile_provider.dart';
import '../../core/widgets/app_bar_widgets.dart';
import '../dashboard/widgets/adherence_metrics_widget.dart';
import '../settings/settings_screen.dart';
import 'dialogs/feedback_dialog.dart';
import 'widgets/notebook_widget.dart';

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
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  TextField(
                    controller: _firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dobCtrl,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          hintText: 'Tap to select date',
                          prefixIcon: const Icon(Icons.cake),
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _allergyCtrl,
                    decoration: InputDecoration(
                      labelText: 'Allergies',
                      prefixIcon: const Icon(Icons.warning_amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelEdit(profile),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _saveProfile(profile),
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.badge,
                    label: 'Full Name',
                    value:
                        (profile.firstName.isEmpty && profile.lastName.isEmpty)
                        ? 'Tap Edit to add your name'
                        : '${profile.firstName} ${profile.lastName}'.trim(),
                    isEmpty:
                        profile.firstName.isEmpty && profile.lastName.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    icon: Icons.cake,
                    label: 'Date of Birth',
                    value: profile.dob.isEmpty
                        ? 'Tap Edit to add your birthday'
                        : profile.dob,
                    isEmpty: profile.dob.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    icon: Icons.warning_amber,
                    label: 'Allergies',
                    value: profile.allergies.isEmpty
                        ? 'None listed'
                        : profile.allergies,
                    isEmpty: profile.allergies.isEmpty,
                  ),
                ],
              ],
            ),
          ),
        ),
        const AdherenceMetricsWidget(),
        const NotebookWidget(),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Feedback & Support',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'We value your feedback! Help us improve ComplyHealth by sharing your thoughts, reporting bugs, or requesting new features.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const FeedbackDialog(),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Submit Feedback'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isEmpty = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isEmpty
                        ? theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          )
                        : theme.colorScheme.onSurface,
                    fontStyle: isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
