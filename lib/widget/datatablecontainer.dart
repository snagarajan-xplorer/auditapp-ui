import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../utils/datatablesource.dart';
import 'buttoncomp.dart';
class DataTableContainer extends StatefulWidget {
  final List<Map<String,dynamic>> dataArr;
  final List<Map<String,dynamic>> fieldArr;
  final String pageType;
  final Function(dynamic) onChanged;
  final Function(dynamic)? callback;
  const DataTableContainer({super.key,this.callback,required this.pageType, required this.dataArr, required this.fieldArr, required this.onChanged,});


  @override
  State<DataTableContainer> createState() => _DataTableContainerState();
}

class _DataTableContainerState extends State<DataTableContainer> {
  ScrollController _horizantal = ScrollController();
  late AppDataTableSource dataTableSource ;
  UserController usercontroller = Get.put(UserController());
  bool loadCont = false;


   @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 100))
    .then((val){
      dataTableSource = AppDataTableSource(dataArr: widget.dataArr,pageType:widget.pageType,buttonName: AppTranslations.of(context)!.text("key_edit"),fieldArr: widget.fieldArr,
        onChanged: (obj){
          if(widget.pageType == "template"){
            usercontroller.getTempalteStatus(context, data: {"template_id":obj["id"],"status":obj["status"]}, callback: (res){
              if(res["cont"] == false){
                dataTableSource.updateData(obj);
                APIService(context).showToastMgs(res["message"]);
              }
            });
          }else if(widget.pageType == "user"){
            usercontroller.getUserStatus(context, data: {"userid":obj["id"],"status":obj["status"]}, callback: (res){
              if(res["cont"] == false){
                dataTableSource.updateData(obj);
                APIService(context).showToastMgs(res["message"]);
              }
            });
          }
        },
        callback: (id){
          widget.callback!(id);
        },

      );
      loadCont = true;
      setState(() {

      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: widget.fieldArr.length != 0 && loadCont == true ? PaginatedDataTable(
        columnSpacing: defaultPadding,
        horizontalMargin: 12,
        columns: widget.fieldArr.map((element)=>DataColumn2(
          label: Container(child: Text(element["lable"],style: headingTableTextStyle,)),
        )).toList(),
        source: dataTableSource,
      ):SizedBox(),
    );
  }
}

