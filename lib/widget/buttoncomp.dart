import 'package:flutter/material.dart';

import '../constants.dart';

class ButtonComp extends StatelessWidget {
  final Icon? icon;
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color? color;
  final bool? disabled;
  const ButtonComp({super.key, this.icon, required this.label, required this.onPressed, this.width=200, this.height=buttonHeight, this.color = const Color(0xFF0376d8), this.disabled=false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: icon == null ? ElevatedButton(

        style: TextButton.styleFrom(
          backgroundColor: disabled == false ? Color(0xFF67AC5B) : Color(0xFF535353),
          padding: EdgeInsets.all(5),

        ),
        onPressed: disabled == false ? onPressed : null,
        child: Center(child: Text(label,style: TextStyle(color: Colors.white),)),
      ):ElevatedButton.icon(

        style: TextButton.styleFrom(
          backgroundColor: disabled == false ? color : Color(0xFF535353) ,
          padding: EdgeInsets.all(5),

        ),
        icon:icon,
        onPressed: disabled == false ? onPressed : null,
        label: Center(child: Text(label,style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600))),
      ),
    );
  }
}
