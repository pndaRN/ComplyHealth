import 'package:flutter/material.dart';

class RotatingWelcomeMessage extends StatefulWidget {
  @override
  _RotatingWelcomeMessageState createState() => _RotatingWelcomeMessageState();
}

class _RotatingWelcomeMessageState extends State<RotatingWelcomeMessage> {
  final List<String> messages = [
    "Hello! Welcome to MedSync.",
    "Let's keep your health on track!",
    "Stay healthy with MedSync!",
    "Your medication, your peace of mind.",
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % messages.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        messages[currentIndex],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
