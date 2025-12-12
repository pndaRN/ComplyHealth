import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: 'Information We Collect',
              content: '''ComplyHealth collects the following information that you provide:

• Personal information (name, date of birth)
• Health information (medical conditions, allergies)
• Medication information (names, dosages, schedules)
• Medication adherence data (dose logs, timestamps)

This information is stored locally on your device and is not transmitted to external servers except for optional feedback submissions.''',
            ),

            _buildSection(
              context,
              title: 'How We Use Your Information',
              content: '''Your health data is used to:

• Track your medical conditions and medications
• Send medication reminder notifications
• Generate adherence reports and statistics
• Create PDF exports for sharing with healthcare providers

We do not sell, rent, or share your personal health information with third parties.''',
            ),

            _buildSection(
              context,
              title: 'Data Storage',
              content: '''All your health data is stored locally on your device using encrypted storage. Your data remains on your device unless you:

• Export a PDF report
• Submit feedback (which may include app diagnostic information)

You can delete all your data at any time through the Settings screen.''',
            ),

            _buildSection(
              context,
              title: 'Feedback & Crash Reports',
              content: '''When you submit feedback or when the app experiences an error, we may collect:

• Feedback content you provide
• App version and device information
• Crash logs and error details

This information helps us improve the app and fix issues. Crash reports are processed through Firebase Crashlytics.''',
            ),

            _buildSection(
              context,
              title: 'Your Rights',
              content: '''You have the right to:

• Access your data (all data is visible in the app)
• Export your data (via PDF export feature)
• Delete your data (via Settings > Clear All Data)
• Disable notifications (via device settings)''',
            ),

            _buildSection(
              context,
              title: 'Children\'s Privacy',
              content: '''ComplyHealth is not intended for use by children under 13 years of age. We do not knowingly collect personal information from children under 13.''',
            ),

            _buildSection(
              context,
              title: 'Changes to This Policy',
              content: '''We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app with an updated date.''',
            ),

            _buildSection(
              context,
              title: 'Contact Us',
              content: '''If you have questions about this privacy policy or your data, please use the Send Feedback feature in the app.''',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
