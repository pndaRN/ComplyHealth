import 'package:flutter/material.dart';
import 'dialogs/feedback_dialog.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help and Feedback'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'How can we help?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re always looking to improve your experience with ComplyHealth.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Feedback options
          _buildOptionCard(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            description: 'Let us know if something isn\'t working correctly',
            onTap: () => _showFeedbackDialog(context, 'Bug Report'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.lightbulb_outlined,
            title: 'Request a Feature',
            description: 'Share your ideas for new features or improvements',
            onTap: () => _showFeedbackDialog(context, 'Feature Request'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.medical_services_outlined,
            title: 'Request Condition Addition',
            description: 'Ask us to add a chronic condition to our database',
            onTap: () => _showFeedbackDialog(context, 'Request Condition Addition'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.chat_outlined,
            title: 'General Feedback',
            description: 'Share your thoughts about the app',
            onTap: () => _showFeedbackDialog(context, 'General Feedback'),
          ),
          const SizedBox(height: 32),
          // Send feedback button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showFeedbackDialog(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Send Feedback'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, [String? initialType]) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(initialType: initialType),
    );
  }
}
