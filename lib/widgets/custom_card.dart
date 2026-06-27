import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0x26FFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: child,
    );
  }
}
