import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/profile_provider.dart';

class ProfileSetupForm extends ConsumerStatefulWidget {
  const ProfileSetupForm({super.key});

  @override
  ConsumerState<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends ConsumerState<ProfileSetupForm> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with current profile data if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        _firstNameCtrl.text = profile.firstName;
        _lastNameCtrl.text = profile.lastName;
        _dobCtrl.text = profile.dob;
        _allergyCtrl.text = profile.allergies;
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final updated = profile.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      allergies: _allergyCtrl.text.trim(),
    );
    await ref.read(profileProvider.notifier).save(updated);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _firstNameCtrl,
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: _dobCtrl,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _allergyCtrl,
          decoration: const InputDecoration(
            labelText: 'Allergies',
            hintText: 'e.g. Peanuts, Penicillin',
            prefixIcon: Icon(Icons.warning_amber_rounded),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (_) => _save(),
        ),
      ],
    );
  }
}
