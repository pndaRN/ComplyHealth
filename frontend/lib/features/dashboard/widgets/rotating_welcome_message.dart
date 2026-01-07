import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/profile_provider.dart';

class RotatingWelcomeMessage extends ConsumerStatefulWidget {
  const RotatingWelcomeMessage({super.key});

  @override
  ConsumerState<RotatingWelcomeMessage> createState() =>
      _RotatingWelcomeMessageState();
}

class _RotatingWelcomeMessageState
    extends ConsumerState<RotatingWelcomeMessage> {
  final List<String> _defaultMessages = [
    "Hello! Welcome to ComplyHealth.",
    "Let's keep your health on track!",
    "Stay healthy with ComplyHealth!",
    "Your medication, your peace of mind.",
    "Managing your health, one day at a time.",
    "Welcome back! Ready to track your wellness?",
  ];

  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          final messages = _getMessages();
          currentIndex = (currentIndex + 1) % messages.length;
        });
      }
    });
  }

  List<String> _getMessages() {
    final profileAsync = ref.read(profileProvider);
    final profile = profileAsync.value;

    // If user has a name, show personalized welcome message first
    if (profile != null && profile.firstName.isNotEmpty) {
      return ["Welcome Back ${profile.firstName}!", ..._defaultMessages];
    }

    return _defaultMessages;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _getMessages();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Padding(
        key: ValueKey<int>(currentIndex),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Text(
          messages[currentIndex],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
