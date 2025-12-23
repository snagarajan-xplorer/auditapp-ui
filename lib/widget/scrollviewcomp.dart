import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/outlinebutton.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

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
