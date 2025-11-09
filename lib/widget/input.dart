import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../localization/app_translations.dart';


class Input extends StatelessWidget {
  final String placeholder;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FormFieldValidator? validator;
  final bool? isPassword;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool? autofocus;
  final Color? borderColor;

  Input(
      {required this.placeholder,
      this.suffixIcon,
      this.prefixIcon,
      this.onTap,
        this.validator,
      this.onChanged,
      this.autofocus = false,
      this.isPassword = false,
      this.controller, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return TextFormField (
        obscureText: isPassword!,
        validator: validator,
        onTap: onTap,
        onChanged: onChanged,
        controller: controller,
        autofocus: autofocus!,
        textAlignVertical: TextAlignVertical(y: 0.6),
        decoration: InputDecoration(
            filled: false,
            isDense: true,
            suffixIconColor: Theme.of(context).iconTheme.color,
            prefixIconColor: Theme.of(context).iconTheme.color,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.only(left: 5,bottom: 7,right: 5),

            prefixIcon: prefixIcon,
            label: RichText(
                text: TextSpan(
                  text: placeholder,
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
            enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
            focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
            errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: Colors.red, width: 1.0)),

            hintText: placeholder));
  }
}
