import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';

class AppMessenger {
  static void showBandMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("AppMessenger: context is null, can't show dialog");

      return;
    }

    final isError = message.contains("lost") || message.contains("sleep") || message.contains("failed");
    final isWarning = message.contains("Adjust");

    showDialog(
      context: context,
      barrierDismissible: !isError, // errors must be explicitly dismissed
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError
                  ? Icons.error
                  : isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.info,
              color: isError
                  ? Colors.red
                  : isWarning
                  ? Colors.orange
                  : Colors.blue,
            ),
            SizedBox(width: 8),
            Text(
              isError
                  ? "Error"
                  : isWarning
                  ? "Warning"
                  : "Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
