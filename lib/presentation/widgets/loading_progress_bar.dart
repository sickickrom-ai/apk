import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════
/// LOADING PROGRESS BAR
/// ═══════════════════════════════════════════════════════════════════
/// A sleek linear progress bar displayed at the top of the screen
/// while WebView pages are loading. Shows loading progress from 0 to 100%.
/// ═══════════════════════════════════════════════════════════════════

class LoadingProgressBar extends StatelessWidget {
  /// Current progress value (0.0 to 1.0)
  final double progress;

  const LoadingProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            if (progress < 1.0)
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppConstants.primaryColor,
          ),
          minHeight: 3,
        ),
      ),
    );
  }
}
