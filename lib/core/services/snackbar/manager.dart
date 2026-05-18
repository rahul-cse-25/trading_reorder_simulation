import 'package:flutter/material.dart';
import 'package:trading_simulation/core/storage/storage_keys.dart';

import 'variants.dart';

/// A centralized manager for showing beautiful, themed snackbars across the app.
///
/// Use this service to show snackbars without needing a [BuildContext],
/// as it utilizes the global `scaffoldMessengerKey` from [SessionService].
abstract final class AppSnackbar {
  AppSnackbar._();

  static const Duration _duplicateWindow = Duration(milliseconds: 900);
  static DateTime? _lastShownAt;
  static String? _lastFingerprint;

  /// Shows a success snackbar (green themed).
  static void showSuccess(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
  }) {
    _show(
      message,
      AppSnackbarType.success,
      action: action,
      showLabel: showLabel,
    );
  }

  /// Shows an error snackbar (red themed).
  static void showError(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
    int maxLine = 2,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      message,
      AppSnackbarType.error,
      action: action,
      showLabel: showLabel,
      maxLine: maxLine,
      duration: duration,
    );
  }

  /// Shows a warning snackbar (amber themed).
  static void showWarning(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
  }) {
    _show(
      message,
      AppSnackbarType.warning,
      action: action,
      showLabel: showLabel,
    );
  }

  /// Shows an info snackbar (cyan/neutral themed).
  static void showInfo(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
  }) {
    _show(message, AppSnackbarType.info, action: action, showLabel: showLabel);
  }

  /// Shows a primary snackbar (brand purple themed).
  static void showPrimary(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      message,
      AppSnackbarType.primary,
      action: action,
      showLabel: showLabel,
      duration: duration,
    );
  }

  /// Shows an artist snackbar (purple/pink themed).
  static void showArtist(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
  }) {
    _show(
      message,
      AppSnackbarType.artist,
      action: action,
      showLabel: showLabel,
    );
  }

  /// Shows a playlist snackbar (deep blue themed).
  static void showPlaylist(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
  }) {
    _show(
      message,
      AppSnackbarType.playlist,
      action: action,
      showLabel: showLabel,
    );
  }

  /// Shows a loading snackbar with a progress indicator.
  static void showLoading(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      message,
      AppSnackbarType.loading,
      action: action,
      showLabel: showLabel,
      duration: duration,
    );
  }

  /// Shows a fully custom snackbar with optional style overrides.
  static void showCustom(
    String message, {
    SnackBarAction? action,
    bool showLabel = true,
    IconData? icon,
    Color? accentColor,
    Gradient? gradient,
    String? label,
  }) {
    _show(
      message,
      AppSnackbarType.custom,
      action: action,
      showLabel: showLabel,
      customIcon: icon,
      customAccentColor: accentColor,
      customGradient: gradient,
      customLabel: label,
    );
  }

  static void hide() {
    final messenger = AppKeys.instance.scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
  }

  static void _show(
    String message,
    AppSnackbarType type, {
    SnackBarAction? action,
    bool showLabel = true,
    IconData? customIcon,
    Color? customAccentColor,
    Gradient? customGradient,
    String? customLabel,
    Duration duration = const Duration(seconds: 3),
    int maxLine = 2,
  }) {
    final messenger = AppKeys.instance.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final now = DateTime.now();
    final fingerprint = '$type|$message';
    final isDuplicate =
        _lastFingerprint == fingerprint &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _duplicateWindow;

    if (isDuplicate) return;

    _lastFingerprint = fingerprint;
    _lastShownAt = now;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: AppSnackbarContent(
          message: message,
          type: type,
          action: action,
          showLabel: showLabel,
          customIcon: customIcon,
          customAccentColor: customAccentColor,
          customGradient: customGradient,
          customLabel: customLabel,
          maxLine: maxLine,
        ),
        backgroundColor: Colors.transparent,
        dismissDirection: DismissDirection.horizontal,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: EdgeInsets.zero,
        duration: duration,
      ),
    );
  }
}
