import 'package:flutter/material.dart';

TableRow buildRowFuture(
  IconData icon,
  Color iconColor,
  Future<String> futureData,
) {
  return TableRow(
    children: <Widget>[
      Icon(icon, size: 23, color: iconColor),
      SizedBox(width: 20),

      FutureBuilder<String>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              "Loading...",
              style: TextStyle(fontSize: 20, color: Colors.white70),
            );
          }

          return Text(
            snapshot.data ?? "Unknown",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          );
        },
      ),
    ],
  );
} 