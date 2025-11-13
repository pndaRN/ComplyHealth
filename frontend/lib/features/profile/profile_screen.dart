import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/state/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _allergyCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: profile.name);
    _dobCtrl = TextEditingController(text: profile.dob);
    _allergyCtrl = TextEditingController(text: profile.allergies);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    final profile = ref.read(profileProvider);
    _nameCtrl.text = profile.name;
    _dobCtrl.text = profile.dob;
    _allergyCtrl.text = profile.allergies;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    final profile = ref.read(profileProvider);
    _nameCtrl.text = profile.name;
    _dobCtrl.text = profile.dob;
    _allergyCtrl.text = profile.allergies;
    setState(() => _isEditing = false);
  }

  void _saveProfile() {
    final profile = ref.read(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final p = Profile(
      name: _nameCtrl.text,
      dob: _dobCtrl.text,
      allergies: _allergyCtrl.text,
      xp: profile.xp,
      streak: profile.streak,
      levelProgress: profile.levelProgress,
    );
    notifier.save(p);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Personal Information Card
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
                      Expanded(
                        child: Text(
                          'Personal Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: _enterEditMode,
                          tooltip: 'Edit profile',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing) ...[
                    // Edit Mode - Show text fields
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dobCtrl,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.cake),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                            onPressed: _cancelEdit,
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // View Mode - Show information boxes
                    _buildInfoRow(
                      context,
                      icon: Icons.badge,
                      label: 'Full Name',
                      value: profile.name.isEmpty ? 'Not set' : profile.name,
                      isEmpty: profile.name.isEmpty,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.cake,
                      label: 'Date of Birth',
                      value: profile.dob.isEmpty ? 'Not set' : profile.dob,
                      isEmpty: profile.dob.isEmpty,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.warning_amber,
                      label: 'Allergies',
                      value: profile.allergies.isEmpty ? 'None listed' : profile.allergies,
                      isEmpty: profile.allergies.isEmpty,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Gamification Card
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
                        Icons.stars,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Level section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.military_tech,
                          size: 28,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${notifier.getCurrentLevel(profile.xp)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // XP section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.emoji_events, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Experience',
                              style: theme.textTheme.labelSmall,
                            ),
                            Text(
                              '${profile.xp} XP',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Streak section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_fire_department, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Streak',
                              style: theme.textTheme.labelSmall,
                            ),
                            Text(
                              '${profile.streak} days',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Progress section
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Progress to Level ${notifier.getCurrentLevel(profile.xp) + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(profile.levelProgress * 100).toInt()}% complete',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${notifier.getXpForNextLevel(notifier.getCurrentLevel(profile.xp))} XP needed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: profile.levelProgress,
                            minHeight: 12,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Achievements Card
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
                        Icons.workspace_premium,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Badges & Achievements',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Coming Soon',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock achievements as you track your health',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              Text(
                label,
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isEmpty
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.6)
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
