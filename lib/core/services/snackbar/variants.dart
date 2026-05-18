import 'dart:ui';
import 'package:flutter/material.dart';

class _AppColors {
  static const Color darkGrey = Color(0xFF1E1E1E);
  static const Color greenAccent = Colors.greenAccent;
  static const Color redAccent = Colors.redAccent;
  static const Color blueAccent = Colors.blueAccent;
  static const Color purpleAccent = Colors.purpleAccent;
  static const Color white60 = Colors.white60;
  static const Color white24 = Colors.white24;
  static const Color white12 = Colors.white12;
}

/// The type of snackbar to display, determining its theme and iconography.
enum AppSnackbarType {
  /// Success state - used for positive outcomes.
  success,

  /// Error state - used for failures or critical issues.
  error,

  /// Warning state - used for cautionary information.
  warning,

  /// Info state - used for general neutral information.
  info,

  /// Primary state - used for brand-specific notifications.
  primary,

  /// Artist state - used for artist-related notifications (Purple accent).
  artist,

  /// Playlist state - used for playlist-related notifications (Deep blue accent).
  playlist,

  /// Loading state - used for ongoing operations.
  loading,

  /// Custom state - offers ultimate flexibility for all styling elements.
  custom,
}

/// A beautiful, themed content widget for [SnackBar] with premium aesthetics.
///
/// Features include:
/// - Glassmorphism (Backdrop blur)
/// - Subtle glow effects
/// - Modern asymmetric layout
/// - High-fidelity iconography
class AppSnackbarContent extends StatelessWidget {
  final String message;
  final AppSnackbarType type;
  final SnackBarAction? action;
  final bool showLabel;

  /// Custom overrides for [AppSnackbarType.custom]
  final IconData? customIcon;
  final Color? customAccentColor;
  final Gradient? customGradient;
  final String? customLabel;
  final int maxLine;

  const AppSnackbarContent({
    super.key,
    required this.message,
    required this.type,
    this.action,
    this.showLabel = true,
    this.customIcon,
    this.customAccentColor,
    this.customGradient,
    this.customLabel,
    this.maxLine = 2,
  });

  @override
  Widget build(BuildContext context) {
    final (accentColor, icon, glowGradient) = _getStyle(context);

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: _AppColors.darkGrey.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background glow
              Positioned(
                left: -20,
                top: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    // Dynamic Icon Container - More compact
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: glowGradient,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            type == AppSnackbarType.loading
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Icon(icon, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showLabel)
                            Text(
                              _getTypeLabel(),
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                fontSize: 9,
                              ),
                            ),
                          Text(
                            message,
                            maxLines: maxLine,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 8),
                      _buildAction(context, accentColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, Color color) {
    return TextButton(
      onPressed: action!.onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        action!.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          fontSize: 9,
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (type) {
      case AppSnackbarType.success:
        return 'SUCCESS';
      case AppSnackbarType.error:
        return 'ALERT';
      case AppSnackbarType.warning:
        return 'WARNING';
      case AppSnackbarType.info:
        return 'UPDATE';
      case AppSnackbarType.primary:
        return 'APP';
      case AppSnackbarType.artist:
        return 'ARTIST';
      case AppSnackbarType.playlist:
        return 'PLAYLIST';
      case AppSnackbarType.loading:
        return 'LOADING';
      case AppSnackbarType.custom:
        return customLabel?.toUpperCase() ?? 'NOTICE';
    }
  }

  (Color, IconData, Gradient) _getStyle(BuildContext context) {
    switch (type) {
      case AppSnackbarType.success:
        return (
          _AppColors.greenAccent,
          Icons.done_all_rounded,
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _AppColors.greenAccent,
              _AppColors.greenAccent.withValues(alpha: 0.6),
            ],
          ),
        );
      case AppSnackbarType.error:
        return (
          _AppColors.redAccent,
          Icons.bolt_rounded,
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _AppColors.redAccent,
              _AppColors.redAccent.withValues(alpha: 0.6),
            ],
          ),
        );
      case AppSnackbarType.warning:
        return (
          const Color(0xFFFFB038),
          Icons.priority_high_rounded,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB038), Color(0xFFEAB308)],
          ),
        );
      case AppSnackbarType.info:
        return (
          _AppColors.blueAccent,
          Icons.auto_awesome_rounded,
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _AppColors.blueAccent,
              _AppColors.blueAccent.withValues(alpha: 0.6),
            ],
          ),
        );
      case AppSnackbarType.primary:
        return (
          _AppColors.blueAccent,
          Icons.graphic_eq_rounded,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AppColors.blueAccent, Color(0xFFBE89FF)],
          ),
        );
      case AppSnackbarType.artist:
        return (
          _AppColors.purpleAccent,
          Icons.person_pin,
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _AppColors.purpleAccent,
              _AppColors.purpleAccent.withValues(alpha: 0.6),
            ],
          ),
        );
      case AppSnackbarType.playlist:
        return (
          const Color(0xFF5E7BFF), // Vibrant sapphire blue
          Icons.queue_music_rounded,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5E7BFF), Color(0xFF3B4AF2)],
          ),
        );
      case AppSnackbarType.loading:
        return (
          _AppColors.white60,
          Icons.refresh_rounded,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AppColors.white24, _AppColors.white12],
          ),
        );
      case AppSnackbarType.custom:
        final defaultAccent = _AppColors.blueAccent;
        return (
          customAccentColor ?? defaultAccent,
          customIcon ?? Icons.info_outline_rounded,
          customGradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  customAccentColor ?? defaultAccent,
                  (customAccentColor ?? defaultAccent).withValues(alpha: 0.6),
                ],
              ),
        );
    }
  }
}
