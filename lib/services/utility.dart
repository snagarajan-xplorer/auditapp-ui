import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:jiffy/jiffy.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../localization/app_translations.dart';
import '../models/dynamicfield.dart';

import 'api_service.dart';
class UtilityService{
  dynamic? frontFile = null;
  dynamic? backFile = null;


  static const LinearGradient linearGradient =  LinearGradient(
    colors: [Color(0xffffffff),Color(0xfff3f3f3)],
    stops: [0,0.9],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static List<BoxShadow> boxshadow = [
    BoxShadow(
      color: const Color.fromRGBO(36, 36, 36, 0.4),
      offset: const Offset(0, 5),
      blurRadius: 5.0,
    ),
  ];
  final whitespaceRE = RegExp(r"(?! )\s+| \s+");
  final _emailMaskRegExp = RegExp('^(.)(.*?)([^@]?)(?=@[^@]+\$)');
  String maskEmail(String? input,bool? showMask, [int minFill = 4, String fillChar = '*']) {
    minFill ??= 4;
    fillChar ??= '*';
    if(input != null){
      if(showMask!){
        return input!.replaceFirstMapped(_emailMaskRegExp, (m) {
          var start = m.group(1);
          var middle = fillChar * max(minFill, m.group(2)!.length);
          var end = m.groupCount >= 3 ? m.group(3) : start;
          return start! + middle + end!;
        });
      }else{
        return input;
      }
    }else{
      return "";
    }

  }

  Future<Map<String,dynamic>> getClipboardText() async {
    Map<String,dynamic> data = {};
    data["cont"] = false;
    data["value"] = "";
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    String clipboardText = clipboardData?.text ?? "";
    if(clipboardText.isNotEmpty){
      if(clipboardText.length <= 40){
        data["cont"] = true;
        data["value"] = clipboardText;
      }
    }
    return await data;
  }
  String removeWhiteSpace(String? input){
    return input!.split(whitespaceRE).join(" ");
  }
  String maskPhoneNo(String? input,bool? showMask){
    if(input != null){
      if(showMask!){
        var lastdigit = input!.length-3;
        return "*****"+input!.substring(lastdigit,input!.length);
      }else{
        return input;
      }
    }else{
      return "";
    }
  }

  bool isNumeric(String s) {
    if(s == null) {
      return false;
    }
    if(s.isEmpty) {
      return false;
    }
    return double.tryParse(s) != null ||
        int.tryParse(s) != null;
  }

  bool isValidString(String input) {
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(input);
    final hasDigit = RegExp(r'\d').hasMatch(input);
    final isAlphanumericWithHyphen = RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(input);
    return isAlphanumericWithHyphen && hasLetter && hasDigit;
  }
  bool isNumericData(String input) {
    RegExp regExp = RegExp(r"^[0-9]+$");
    return regExp.hasMatch(input);
  }
  Color getColorPercentage (percentage) {
    Color color = Colors.indigo;
    if(percentage! > 75 && percentage! < 99){
      color = Colors.lightGreen;
    }else if(percentage! > 49 && percentage! < 75){
      color = Colors.yellow;
    }else if(percentage! > 20 && percentage! < 49){
      color = Colors.orange;
    }else if(percentage! < 20){
      color = Colors.red;
    }

    return color;
  }
  bool validateEmail(email){
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  Future<String> parseJsonFromAssets(String assetsPath) async {
    print(assetsPath);
    return rootBundle.loadString(assetsPath,cache: false).then((jsonStr) => jsonStr);
  }
  Color getRandomColor() {
    return Color.fromRGBO(
      Random().nextInt(256), // Red (0-255)
      Random().nextInt(256), // Green (0-255)
      Random().nextInt(256), // Blue (0-255)
      1.0, // Opacity (fully opaque)
    );
  }
  Color getRandomPrimaryColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }
  addValidators(DynamicField element) {
    List<FormFieldValidator> fieldvalidators = [];
    element.rules!.forEach((validatefield) {
      switch (validatefield.name) {
        case "required":
        //fieldvalidators.add(RequiredValidator(errorText: validatefield.errorMsg! ?? ""));
          fieldvalidators.add(FormBuilderValidators.required(
              errorText: validatefield.errorMsg! ?? ""));
          break;
        case "minlength":
          fieldvalidators.add(FormBuilderValidators.minLength(
              int.parse(validatefield.script!),
              errorText: validatefield.errorMsg! ?? ""));
          //fieldvalidators.add(MinLengthValidator(int.parse(validatefield.script!),errorText: validatefield.errorMsg! ?? ""));
          break;
        case "maxlength":
        //fieldvalidators.a
          fieldvalidators.add(FormBuilderValidators.maxLength(
              int.parse(validatefield.script!),
              errorText: validatefield.errorMsg! ?? ""));
          //fieldvalidators.add(MaxLengthValidator(int.parse(validatefield.script!),errorText: validatefield.errorMsg! ?? ""));
          break;
        case "min":
          fieldvalidators.add(FormBuilderValidators.min(
              int.parse(validatefield.script!),
              errorText: validatefield.errorMsg! ?? ""));
          //fieldvalidators.add(MinLengthValidator(int.parse(validatefield.script!),errorText: validatefield.errorMsg! ?? ""));
          break;
        case "max":
        //fieldvalidators.a
          fieldvalidators.add(FormBuilderValidators.max(
              int.parse(validatefield.script!),
              errorText: validatefield.errorMsg! ?? ""));
          //fieldvalidators.add(MaxLengthValidator(int.parse(validatefield.script!),errorText: validatefield.errorMsg! ?? ""));
          break;
        case "email":

          // fieldvalidators.add(FormBuilderValidators.email(errorText: validatefield.errorMsg! ?? ""));
        //fieldvalidators.add(EmailValidator(errorText: validatefield.errorMsg! ?? ""));
          break;
        case "pattern":

        //fieldvalidators.add(FormBuilderValidators.);
        //fieldvalidators.add(PatternValidator(validatefield.script as Pattern, errorText: validatefield.errorMsg! ?? ""));
          break;
        default:
          break;
      }
    });
    if (fieldvalidators.length != 0) {
      element.validator = FormBuilderValidators.compose(fieldvalidators);
    }
  }


}