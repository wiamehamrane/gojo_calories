import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Centralized error handler that maps exceptions to user-friendly messages.
class AppErrorHandler {
  /// Maps any thrown error to a readable string.
  static String message(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Request timed out. Please check your connection and try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network settings.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final detail = error.response?.data?['detail'];
          if (statusCode == 401) {
            return 'Your session has expired. Please sign in again.';
          }
          if (statusCode == 404 && error.requestOptions.path.contains('auth/me')) {
            return 'Your account was not found. Please sign in again.';
          }
          if (statusCode == 404 && detail != null) {
            return detail.toString();
          }
          if (statusCode == 404) {
            return 'The requested information was not found.';
          }
          if (statusCode == 400 && detail != null) return detail.toString();
          if (statusCode == 503 && detail != null) return detail.toString();
          if (statusCode != null && statusCode >= 500) {
            if (detail != null && detail.toString().isNotEmpty) {
              return detail.toString();
            }
            return 'Server error. Please try again later.';
          }
          return detail?.toString() ?? 'An unexpected error occurred.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error is FormatException) {
      return 'Received an unexpected response from the server.';
    }

    final msg = error.toString();
    // Strip the "Exception:" prefix for cleaner UX
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }

  /// Shows a floating SnackBar with the error message.
  static void showSnackbar(BuildContext context, Object error, {Color? color}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message(error)),
        backgroundColor: color ?? Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a modal dialog with the error message.
  static void showDialog(
    BuildContext context,
    Object error, {
    String title = 'Error',
  }) {
    if (!context.mounted) return;
    showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(message(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
