import 'package:audit_app/constants.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../controllers/usercontroller.dart';

class AppDataTableSource extends DataTableSource{
  final List<Map<String,dynamic>> dataArr;
  final List<Map<String,dynamic>> fieldArr;
  final String? buttonName;
  Function(dynamic) callback;
  final Function(dynamic) onChanged;
  final String pageType;
  AppDataTableSource({required this.dataArr,required this.onChanged,required this.fieldArr,required this.pageType,required this.callback,this.buttonName = "View"});




  @override
  DataRow? getRow(int index) {
    if(index >= dataArr.length) return null;
    Map<String,dynamic> obj = dataArr[index];
    List<DataCell> cell = [];
    fieldArr.forEach((element){
      if(element["type"] == "string"){
        DataCell e = DataCell(Text(obj[element["key"]].toString()));
        if(element["key"] == "description"){
          e = DataCell(Container(width:150,child: Text(obj[element["key"]].toString()),));
        }
        if(element["key"] == "statusvalue"){
           e = DataCell(Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               StatusComp(status: obj["status"], statusvalue: obj[element["key"]],),
               pageType == "template" || pageType == "user"  ? Switch(
                 value: obj["status"] == "A" ? true : false,
                 onChanged: (val){

                    obj["status"] = val ? "A" : "IA";
                    obj["statusvalue"] = obj["status"] == "A"? "Active" : "Inactive";
                   // obj["statusvalue"] = val ? "Active" : "In Active"; // or however you name it
                    notifyListeners(); // Important to refresh the UI
                   onChanged(obj);
                 },
                 activeColor: Colors.green,
                 inactiveThumbColor: Colors.grey.shade400,
                 inactiveTrackColor: Colors.grey.shade400,
               ):SizedBox()
             ],
           ));
        }
        cell.add(e);
      }else if(element["type"] == "button"){
        DataCell e = DataCell(ButtonComp(
          height: buttonHeight,
          width: 80,
          label: buttonName!, onPressed: () {
            callback(obj);
        },
        ));
        cell.add(e);
      }
    });

    return DataRow2(cells: cell);

  }
  void updateData(Map<String, dynamic> obj) {
    List<Map<String,dynamic>> arr = dataArr.where((_element)=>_element["id"] == obj["id"]).toList();
    if(arr.length != 0){
      arr[0]["status"] = "A";
      arr[0]["statusvalue"] = arr[0]["status"] == "A"? "Active" : "Inactive";
    }
    notifyListeners(); // <- this will refresh the UI
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => dataArr.length;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
  
}