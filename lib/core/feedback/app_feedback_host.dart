import 'package:flutter/material.dart';
import 'app_feedback.dart';

class AppFeedbackHost extends StatelessWidget {
  final Widget child;

  const AppFeedbackHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned.fill(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            child: Overlay(key: AppFeedback.overlayKey),
          ),
        ),
      ],
    );
  }
}
