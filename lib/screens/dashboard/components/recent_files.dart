import 'package:audit_app/utils/datatablesource.dart';
import 'package:jiffy/jiffy.dart';

import '../../../localization/app_translations.dart';
import './../../../models/recent_file.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants.dart';

class RecentFiles extends StatelessWidget {
  final List<Map<String,dynamic>> dataArr;
  final List<Map<String,dynamic>> fieldArr;
  final String userRole;
  const RecentFiles({
    Key? key, required this.dataArr, required this.userRole, required this.fieldArr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("dataArr ${dataArr}");
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.of(context)!.text("key_message_05"),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            width: double.infinity,

          ),
        ],
      ),
    );
  }
}

DataRow recentFileDataRow(dynamic fileInfo,context,role) {
  String date = Jiffy.parse(fileInfo["start_date"]).format(pattern: "dd/MM/yyyy");
  String status = AppTranslations.of(context)!.text("key_create");
  if(fileInfo["status"] == "IP"){
    status = AppTranslations.of(context)!.text("key_progress");
  }else if(fileInfo["status"] == "PG"){
    status = AppTranslations.of(context)!.text("key_progress");
  }else if(fileInfo["status"] == "C"){
    if(role == "CL"){
      status = AppTranslations.of(context)!.text("key_complete");
    }else{
      status = AppTranslations.of(context)!.text("key_complete");
    }
  }else if(fileInfo["status"] == "S"){
    status = AppTranslations.of(context)!.text("key_create");
  }else if(fileInfo["status"] == "P"){
    status = AppTranslations.of(context)!.text("key_publish");
  }
  return DataRow(
    cells: [
      DataCell(
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(IMG_URL+fileInfo["image"]),
                  fit: BoxFit.cover
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Text(fileInfo["auditname"]),
            ),
          ],
        ),
      ),
      DataCell(Text(fileInfo["companyname"])),
      DataCell(Text(date)),
      DataCell(Text(status)),
    ],
  );
}
