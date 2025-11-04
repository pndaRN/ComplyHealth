import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/state/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    final nameCtrl = TextEditingController(text: profile.name);
    final dobCtrl = TextEditingController(text: profile.dob);
    final allergyCtrl = TextEditingController(text: profile.allergies);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dobCtrl,
              decoration: const InputDecoration(labelText: 'Date of Birth'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: allergyCtrl,
              decoration: const InputDecoration(labelText: 'Allergies'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                final p = Profile(
                  name: nameCtrl.text,
                  dob: dobCtrl.text,
                  allergies: allergyCtrl.text,
                  xp: profile.xp,
                  streak: profile.streak,
                  levelProgress: profile.levelProgress,
                );
                notifier.save(p);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
              },
              child: const Text('Save'),
            ),
            const Divider(height: 30),

            Text(
              '⭐ Level ${notifier.getCurrentLevel(profile.xp)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🏆 Total XP: ${profile.xp}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '🔥 Level Streak: ${profile.streak}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to Level ${notifier.getCurrentLevel(profile.xp) + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${(profile.levelProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: profile.levelProgress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 4),
            Text(
              'Next level: ${notifier.getXpForNextLevel(notifier.getCurrentLevel(profile.xp))} XP',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const Text(
              'Badges & Achievement (Coming Soon)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Icon(Icons.emoji_events, size: 50, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
