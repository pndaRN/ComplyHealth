import 'package:flutter/material.dart';

/// Utility class for medication form validation
class MedicationValidator {
  /// Validates medication form fields and shows error messages if validation fails
  static bool validateForm({
    required BuildContext context,
    required String name,
    required String dosage,
    required List<String> conditions,
    required bool isPRN,
    required List<TimeOfDay> scheduledTimes,
    required int? maxDailyDoses,
  }) {
    final List<String> errors = [];

    if (name.trim().isEmpty) {
      errors.add('Please enter a medication name');
    }
    if (dosage.trim().isEmpty) {
      errors.add('Please enter a dosage');
    }
    if (conditions.isEmpty) {
      errors.add('Please select at least one condition');
    }

    // Timing validation
    if (isPRN) {
      // PRN medications require max daily doses
      if (maxDailyDoses == null || maxDailyDoses <= 0) {
        errors.add('Please enter maximum doses per day for PRN medication');
      }
    } else {
      // Scheduled medications require at least one time
      if (scheduledTimes.isEmpty) {
        errors.add('Please add at least one scheduled time or mark as PRN');
      }
    }

    if (errors.isNotEmpty) {
      _showTopError(context, errors);
      return false;
    }

    return true;
  }

  /// Shows error notification sliding down from the top
  static void _showTopError(BuildContext context, List<String> errors) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopErrorNotification(
        errors: errors,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

/// Animated error notification that slides down from the top
class _TopErrorNotification extends StatefulWidget {
  final List<String> errors;
  final VoidCallback onDismiss;

  const _TopErrorNotification({
    required this.errors,
    required this.onDismiss,
  });

  @override
  State<_TopErrorNotification> createState() => _TopErrorNotificationState();
}

class _TopErrorNotificationState extends State<_TopErrorNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.errors
                    .map((error) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
