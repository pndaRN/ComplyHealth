import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/education_content.dart';

class VideoSection extends StatelessWidget {
  final List<Video> videos;

  const VideoSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (videos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No videos available yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Educational Videos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...videos.map((video) => _buildVideoCard(context, video)),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(context, video.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: video.thumbnail != null
                    ? Image.network(
                        video.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildVideoPlaceholder(theme);
                        },
                      )
                    : _buildVideoPlaceholder(theme),
              ),
            ),
            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.play_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ),
                  if (video.duration != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video.duration!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 64,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }
}
