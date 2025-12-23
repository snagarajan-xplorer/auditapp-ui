import 'package:flutter/material.dart';

import '../constants.dart';
import '../responsive.dart';

class OutlineButtonComp extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  const OutlineButtonComp({super.key, required this.label, required this.onPressed, this.width=90, this.height=30});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      child: Container(
        width: width,
        height: height,
        child: Center(
          child: Text(
            label!,
            style: labelTextStyle,
          ),
        ),
      ),
      onPressed: () {onPressed!();},
    );
  }
}
