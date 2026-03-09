import 'package:flutter/material.dart';

class ScrollviewComp extends StatelessWidget {
  final Widget child;
  const ScrollviewComp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: child,
    );
  }
}
