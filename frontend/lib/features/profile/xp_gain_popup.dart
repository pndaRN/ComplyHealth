import 'package:flutter/material.dart';
import '../../core/state/profile_provider.dart';

class XpGainPopup extends StatelessWidget {
  final int xpGained;
  final int currentLevel;
  final int nextLevel;
  final double levelProgress;
  final int currentXp;
  final int xpForNextLevel;
  final int streak;

  const XpGainPopup({
    Key? key,
    required this.xpGained,
    required this.currentLevel,
    required this.nextLevel,
    required this.levelProgress,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.streak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int xpNeeded = xpForNextLevel - currentXp;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy Icon with glow effect
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Daily Reward!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // XP Gained
            Text(
              '+$xpGained XP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),

            // Streak info
            if (streak > 0)
              Text(
                '🔥 $streak day streak!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 24),

            // Level Progress Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Level labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLevelBadge(currentLevel, true),
                      _buildLevelBadge(nextLevel, false),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  Stack(
                    children: [
                      // Background bar
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Progress bar
                      FractionallySizedBox(
                        widthFactor: levelProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Progress text
                      Container(
                        height: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '${(levelProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // XP to next level
                  Text(
                    '$xpNeeded XP to Level $nextLevel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue.shade700 : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Level $level',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isCurrent ? 14 : 12,
        ),
      ),
    );
  }
}
