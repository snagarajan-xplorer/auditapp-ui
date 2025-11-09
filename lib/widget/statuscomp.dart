import 'package:flutter/material.dart';

import '../localization/app_translations.dart';

class StatusComp extends StatelessWidget {
  final String status;
  final String statusvalue;
  final int? percentage;
  const StatusComp({super.key, required this.status, required this.statusvalue, this.percentage=-1});


  Color getColor (String status) {
    Color color = Colors.green;
    switch (status) {
      case "A":
        color = Colors.green;
        break;
      case "IA":
      // do something else
        color = Colors.red;
        break;
      case "IP":
      // do something else
        color = Colors.orangeAccent;
        break;
      case "PG":
      // do something else
        color = Colors.orangeAccent;
        break;
      case "S":
      // do something else
        color = Colors.pink;
        break;
      case "P":
      // do something else
        color = Colors.green;
        break;
      case "C":
      // do something else
        color = Colors.green.shade900;
        break;
      case "CL":
      // do something else
        color = Colors.red;
        break;
    }
    return color;
  }
  String getStringValue(status,context){
    String txt = "";
    switch (status) {
      case "A":
        txt = AppTranslations.of(context)!.text("key_message_18");
        break;
      case "IA":
      // do something else
        txt = AppTranslations.of(context)!.text("key_message_19");
        break;
      case "IP":
      // do something else
        txt = AppTranslations.of(context)!.text("key_progress");
        break;
      case "PG":
      // do something else
        txt = AppTranslations.of(context)!.text("key_progress");
        break;
      case "S":
      // do something else
        txt = AppTranslations.of(context)!.text("key_create");
        break;
      case "P":
      // do something else
        txt = AppTranslations.of(context)!.text("key_publish");
        break;
      case "C":
      // do something else
        txt = AppTranslations.of(context)!.text("key_complete");
        break;
      case "CL":
      // do something else
        txt = AppTranslations.of(context)!.text("key_cancel");
        break;
    }
    return txt;
  }
  Color getColorPercentage () {
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

  @override
  Widget build(BuildContext context) {


    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 16,height: 16,decoration: BoxDecoration(
          color: percentage == -1 ? getColor(status):getColorPercentage(),
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),),
        SizedBox(width: 4,),
        Text(statusvalue.toString().isEmpty ? getStringValue(status, context):statusvalue.toString())
      ],
    );
  }
}
