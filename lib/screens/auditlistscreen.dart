import 'package:audit_app/dynamicform/selectinput.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jiffy/jiffy.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../models/dynamicfield.dart';
import '../responsive.dart';
import 'main/layoutscreen.dart';

class Auditlistscreen extends StatefulWidget {
  const Auditlistscreen({super.key});

  @override
  State<Auditlistscreen> createState() => _AuditlistscreenState();
}

class _AuditlistscreenState extends State<Auditlistscreen> {
   late PlutoGridStateManager stateManager;
  List<dynamic> userdata = [];
  ScreenArgument? pageargument;
  UserController usercontroller = Get.put(UserController());
   GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  List<Map<String,dynamic>> auditList = [];
  List<PlutoRow> rows = [];
  List<PlutoColumn> column = [];
  String year = Jiffy.now().year.toString();
  String month = "All";
  String status = "All";
  List<dynamic> statusArr = [
    {
      "key":"All",
      "value":"All"
    },
    {
      "key":"P",
      "value":"Publish"
    },
    {
      "key":"IP",
      "value":"In Progress"
    },
    {
      "key":"S",
      "value":"Up Coming"
    },
    {
      "key":"CL",
      "value":"Cancel"
    }
  ];

   List<Map<String,dynamic>> dataObj = [
    {
      "lable":"Customer",
      "key":"companyname",
      "type":"string",
      "value":"",
      "size":ColumnSize.L,
    },
      {
      "lable":"Audit No",
      "key":"audit_no",
      "type":"string",
      "value":"",
      "size":ColumnSize.L,
      },
      {
      "lable":"Audit Name",
      "key":"auditname",
      "type":"string",
      "value":"",
      "size":ColumnSize.L,
      },
      {
        "lable":"Start Date",
        "key":"start_date",
        "type":"string",
        "value":"",
        "size":ColumnSize.M,
      },
      {
        "lable":"City",
        "key":"city",
        "type":"string",
        "value":"",
        "size":ColumnSize.M,
      },
      {
        "lable":"Status",
        "key":"status",
        "type":"string",
        "value":"",
        "size":ColumnSize.S,
      },
      {
        "lable":"Action",
        "key":"action",
        "type":"button",
        "value":"",
        "size":ColumnSize.L,
      }
  ];
   List<Map<String,dynamic>> monthArr = [
     {"key":"All","value":"All"},
     {"key":1,"value":"January"},
     {"key":2,"value":"February"},
     {"key":3,"value":"March"},
     {"key":4,"value":"April"},
     {"key":5,"value":"May"},
     {"key":6,"value":"June"},
     {"key":7,"value":"July"},
     {"key":8,"value":"August"},
     {"key":9,"value":"September"},
     {"key":10,"value":"October"},
     {"key":11,"value":"November"},
     {"key":12,"value":"December"},
   ];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(usercontroller.userData.role == null){

      usercontroller.loadInitData();
    }
    Future.delayed(Duration(milliseconds: 200))
        .then((onValue) async {

      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      if(pageargument?.mapData.containsKey("path")){
        status = pageargument?.mapData["path"];
      }
      stateManager = PlutoGridStateManager(columns: column, rows: rows, gridFocusNode: FocusNode(), scroll: PlutoGridScrollController());
      setState(() {});
      getAuditList();

    });
  }
  void getAuditList() async {
    Map<String,dynamic> data = {
      "client":usercontroller.userData.clientid,
      "userid":usercontroller.userData.userId,
      "role":usercontroller.userData.role,
      "month":month,
      "year":year
    };
    usercontroller.getAuditList(context, data: data, callback: (res) async {
      rows = [];
      column = [];
      auditList = [];
      setState(() {});
      dataObj.forEach((element){
        PlutoColumn col = PlutoColumn(
          title: element["lable"],
          field: element["key"],
          enableContextMenu: false,
          enableTitleChecked: false,
          enableDropToResize: false,
          enableColumnDrag: false,
          enableEditingMode: false,
          enableFilterMenuItem: false,
          type: PlutoColumnType.text(),
        );
        if(element["key"] == "status"){
          col = PlutoColumn(
            title: element["lable"],
            field: element["key"],
            type: PlutoColumnType.text(),
              enableContextMenu: false,
              enableTitleChecked: false,
              enableDropToResize: false,
              enableColumnDrag: false,
              enableEditingMode: false,
              enableFilterMenuItem: false,
            renderer: (PlutoColumnRendererContext context) {
              return StatusComp(status: context.cell.value.toString(), statusvalue: "");
            }
          );
        }else if(element["key"] == "action"){
          col = PlutoColumn(
              title: element["lable"],
              field: element["key"],
              enableContextMenu: false,
              enableTitleChecked: false,
              enableDropToResize: false,
              enableColumnDrag: false,
              enableEditingMode: false,
              enableFilterMenuItem: false,
              type: PlutoColumnType.text(),
              renderer: (PlutoColumnRendererContext context2) {
                Widget w = Container();
                if(["CL"].indexOf(usercontroller.userData.role.toString()) == -1 && ["P","CL"].indexOf(context2.row.data["status"].toString()) == -1){
                  w = Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: context2.row.data["status"].toString() == "S" ? true:false,
                          child: ButtonComp(width:context2.row.data["status"].toString() == "S" ? 50 : 0,label: AppTranslations.of(context)!.text("key_btn_edit"),color: Colors.green, onPressed: (){
                            Navigator.pushNamed(context, "/addaudit",arguments: ScreenArgument(argument: ArgumentData.USER,mode:"Edit",mapData:auditList,editData: context2.row.data));
                          })
                      ),
                      ButtonComp(width:70,label: AppTranslations.of(context)!.text("key_start"), onPressed: (){
                        Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: context2.row.data));
                      })
                    ],
                  );
                  if(context2.row.data["status"].toString() != "S"){
                    w = ButtonComp(width:110,label: context2.row.data["status"] == "C"?"View Audit":AppTranslations.of(context)!.text("key_start"), onPressed: (){
                      Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: context2.row.data));
                    });
                  }
                }else if(context2.row.data["status"].toString() == "P" ){
                  w = ButtonComp(label: AppTranslations.of(context)!.text("key_report"), onPressed: (){
                   Navigator.pushNamed(context, "/auditdetails",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: context2.row.data));
                  });
                }else if(context2.row.data["status"].toString() == "CL" ){
                  w = ButtonComp(label: AppTranslations.of(context)!.text("key_remarks"), onPressed: (){
                    usercontroller.getAuditRemarks(context, data: {"audit_id":context2.row.data["id"]}, callback:(res){
                      List<dynamic> arr = res.where((element)=>element["type"] == "Cancel Audit").toList();
                      if(arr.length != 0){
                        APIService(context).showWindowAlert(title: arr[0]["type"],desc: arr[0]["remarks"],callback: (){});
                      }
                    });
                    //Navigator.pushNamed(context, "/auditdetails",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: context2.row.data));
                  });
                }
                return w;
              }
          );
        }
        column.add(col);
      });
      List<dynamic> dataArr = res;
      auditList = dataArr.map((e) => e as Map<String, dynamic>).toList();
      auditList.forEach((element){
        Map<String, PlutoCell> obj = {};
        dataObj.forEach((dataobjval){
          if(dataobjval["key"] == "status"){
            obj[dataobjval["key"]]= PlutoCell(value: element[dataobjval["key"]]);
          }else if(dataobjval["key"] == "action"){
            obj[dataobjval["key"]]= PlutoCell(value: element["status"]);
          }else if(dataobjval["key"] == "start_date"){
            obj[dataobjval["key"]]= PlutoCell(value: Jiffy.parseFromDateTime(DateTime.parse(element["start_date"])).format(pattern: "dd/MM/yyyy"));
          }else{
            obj[dataobjval["key"]]= PlutoCell(value: element[dataobjval["key"]]);
          }
        });
        print("status ${status} - ${element["status"]}");
        if(status == "P" && element["status"] == "P"){
          rows.add(PlutoRow(cells: obj,data: element));
        }else if(status == "IP" && ["IP","PG"].indexOf(element["status"]) != -1){
          rows.add(PlutoRow(cells: obj,data: element));
        }else if(status == "CL" && ["CL"].indexOf(element["status"]) != -1){
          rows.add(PlutoRow(cells: obj,data: element));
        }if(status == "S" && element["status"] == "S"){
          rows.add(PlutoRow(cells: obj,data: element));
        }else if(status == "All"){
          rows.add(PlutoRow(cells: obj,data: element));
        }

      });
      refreshGridWithNewData(rows);
      setState(() {});
    });

  }
   void refreshGridWithNewData(List<PlutoRow> newRows) {
    if(stateManager != null){
      stateManager.removeAllRows();
      stateManager.appendRows(newRows);
      stateManager.notifyListeners();
    }
   }

  Widget mobileView(fileInfo) {
    return BoxContainer(
        height: 150,
        child: Container(height: 150,)
    );
  }

  Widget getAuditCom(element){
    String status = AppTranslations.of(context)!.text("key_create");
    if(element["status"] == "IP"){
      status = AppTranslations.of(context)!.text("key_progress");
    }else if(element["status"] == "PG"){
      status = AppTranslations.of(context)!.text("key_progress");
    }else if(element["status"] == "C"){
      status = AppTranslations.of(context)!.text("key_complete");
    }else if(element["status"] == "CL"){
      status = AppTranslations.of(context)!.text("key_cancel");
    }else if(element["status"] == "S"){
      status = AppTranslations.of(context)!.text("key_create");
    }else if(element["status"] == "P"){
      status = AppTranslations.of(context)!.text("key_publish");
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BoxContainer(
        padding: 10,
        width: 310,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 120,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Center(child: Text("#"+element["audit_no"],style: smallTextStyle,)),
                ),
              ),
              SizedBox(height: 15,),
              Center(child: Text(element["companyname"],style: headingTextStyle,)),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.of(context)!.text("key_auditname"),style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14
                          ),),
                          Text(element["auditname"],style: TextStyle(
                              color: Colors.black,
                              fontSize: 14
                          ),maxLines: 4,)
                        ],
                      )
                  ),

                ],
              ),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.of(context)!.text("key_startdate"),style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14
                          ),),
                          Text(Jiffy.parse(element["start_date"]).format(pattern: "dd/MM/yyyy"),style: TextStyle(
                              color: Colors.black,
                              fontSize: 14
                          ),maxLines: 4,)
                        ],
                      )
                  ),
                  Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppTranslations.of(context)!.text("key_starttime"),style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,fontWeight: FontWeight.w500
                          ),),
                          Text(Jiffy.parse(element["start_time"]).format(pattern: "hh:mm a"),style: TextStyle(
                              color: Colors.black,
                              fontSize: 14
                          ),)
                        ],
                      )
                  )
                ],
              ),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppTranslations.of(context)!.text("key_assign"),style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,fontWeight: FontWeight.w500
                      ),),
                      Text(element["auditorname"].toString().trim(),style: TextStyle(
                          color: Colors.black,
                          fontSize: 14
                      ),)
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppTranslations.of(context)!.text("key_status"),style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,fontWeight: FontWeight.w500
                      ),),
                      StatusComp(status: element["status"], statusvalue: status,)
                    ],
                  )
                ],
              ),
              SizedBox(height: 15,),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppTranslations.of(context)!.text("key_address"),style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,fontWeight: FontWeight.w500
                  ),),
                  Text(element["city"]+","+element["state"]+","+element["zone"],style: TextStyle(
                      color: Colors.black,
                      fontSize: 14
                  ),)
                ],
              ),
              SizedBox(height: 15,),
              Visibility(
                visible: ["P","CL"].indexOf(element["status"]) == -1 ? true : false,
                //   visible: false,
                  child: Center(
                    child: ButtonComp(
                        height: buttonHeight,
                        color: Colors.green,
                        width: 200,
                        label: element["status"] == "C"?"View Audit":AppTranslations.of(context)!.text("key_start"),
                        onPressed: (){
                          Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element,editData: element));
                          // if(element["status"] == "S"){
                          //   Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
                          //   // APIService(context).showWindowAlert(title: "",desc: element["remarks"],okbutton:AppTranslations.of(context)!.text("key_btn_ok"),callback: (){
                          //   //   Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
                          //   // });
                          // }else{
                          //   Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
                          // }
                        }
                    ),
                  )
              ),
              // Visibility(
              //     visible: element["status"] == "CL" && menuAccessRole.indexOf(usercontroller.userData.role!) != -1 ? true : false,
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         ButtonComp(
              //             height: buttonHeight,
              //             width: 90,
              //             label: AppTranslations.of(context)!.text("key_edit"),
              //             onPressed: (){
              //               Navigator.pushNamed(context, "/addaudit",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
              //               //Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
              //               //Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
              //             }
              //         ),
              //         ButtonComp(
              //             height: buttonHeight,
              //             width: 90,
              //             label: AppTranslations.of(context)!.text("key_publish"),
              //             onPressed: (){
              //               Map<String,dynamic> dataobj = {"client_id":element["client_id"]};
              //               usercontroller.getClientUserList(context,data: dataobj,errorcallback:(res){
              //                 if(res.containsKey("message")){
              //                   APIService(context).showWindowAlert(title: "",desc: res["message"],callback: (){
              //                     Navigator.pushNamed(context, "/client",arguments: ScreenArgument(argument: ArgumentData.CLIENT,mapData: {}));
              //                   });
              //                 }
              //               },callback: (arr) async {
              //                 if(arr.length == 0){
              //                   return;
              //                 }
              //                 arr.forEach((ele)=>ele["checked"]=false);
              //                 SizedBox col = SizedBox(
              //                   height: 250,
              //                   child: Column(
              //                     mainAxisAlignment: MainAxisAlignment.start,
              //                     crossAxisAlignment: CrossAxisAlignment.start,
              //                     children: [
              //                       Text(AppTranslations.of(context)!.text("key_message_10")),
              //                       SizedBox(
              //                         height: defaultPadding,
              //                       ),
              //                       SizedBox(
              //                         height: 200,
              //                         child: ListView(
              //                           shrinkWrap: false,
              //                           children: arr.map<Widget>((ele)=>Padding(
              //
              //                             padding: const EdgeInsets.only(top: 4,bottom: 4),
              //                             child: FormBuilderCheckbox(
              //                               checkColor: Colors.white,
              //                               activeColor: Colors.blue.shade900,
              //                               initialValue: ele["checked"],
              //                               onChanged: (bool? value) {
              //                                 if(ele["checked"] == true){
              //                                   ele["checked"] = false;
              //                                 }else{
              //                                   ele["checked"] = true;
              //                                 }
              //                                 setState(() {
              //
              //                                 });
              //                               }, name: 'ele', title: Text(ele["email"],style: paragraphTextStyle,),
              //                             ),
              //                           )).toList(),
              //                         ),
              //                       )
              //                     ],
              //                   ),
              //                 );
              //                 APIService(context).showWindowAlert(title: "",desc: "",
              //                     showCancelBtn: true,
              //                     child: col,callback: (){
              //                       Map<String,dynamic> publishobj = {"audit_id":element["audit_no"],"audit_name":element["auditname"],"dataArr":arr};
              //                       usercontroller.publishUserReport(context,data: publishobj,callback: () async {
              //                         Map<String,dynamic> dataobj = {"audit_id":element["id"]};
              //                         usercontroller.publishAuditStatus(context,data: dataobj,callback: () async {
              //                           getAuditList();
              //                           //Navigator.pushNamed(context, "/dashboard",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
              //                         });
              //                       });
              //                     });
              //                 //Navigator.pushNamed(context, "/dashboard",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
              //                 });
              //
              //             }
              //         )
              //       ],
              //     )
              // ),
              Visibility(
                  visible: element["status"] == "CL"? true : false,
                  child: Center(
                    child: ButtonComp(label: AppTranslations.of(context)!.text("key_remarks"), onPressed: (){
                      usercontroller.getAuditRemarks(context, data: {"audit_id":element["id"]}, callback:(res){
                        List<dynamic> arr = res.where((element)=>element["type"] == "Cancel Audit").toList();
                        if(arr.length != 0){
                          APIService(context).showWindowAlert(title: arr[0]["type"],desc: arr[0]["remarks"],callback: (){});
                        }
                      });
                      //Navigator.pushNamed(context, "/auditdetails",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: context2.row.data));
                    }),
                  )
              ),
              Visibility(
                  visible: element["status"] == "P" ? true : false,
                  child: Center(
                    child: ButtonComp(
                        height: buttonHeight,
                        width: 200,
                        label: AppTranslations.of(context)!.text("key_report"),
                        onPressed: (){
                          print("element ${element}");
                          Navigator.pushNamed(context, "/auditdetails",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
                        }
                    ),
                  )
              ),
            ],
          )
      ),
    );
  }
  Widget getContent(){
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: auditList.map<Widget>((element)=>getAuditCom(element)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: PageContainerComp(
            header: Row(
              children: [
                Container(height: 40,width: 180,child: FormBuilderDropdown<dynamic>(
                  name: "status",
                  initialValue: status,
                  items: statusArr.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                    value: toElement["key"].toString(),
                    child: Text(toElement["value"].toString()),
                  )).toList(),
                  onChanged: (value) async {
                    status = value.toString();
                    setState(() {});
                    getAuditList();
                  },
                  validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                  decoration:  InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: "Status",
                        children: [

                        ],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(left: 20,top: 10),
                    counterText: "",
                    errorMaxLines: 3,
                    border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                    enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: Colors.red, width: 1.0)),
                    suffixIcon: null,

                  ),
                )),
                SizedBox(width: 10,),
                Container(height: 40,width: 120,child: FormBuilderDropdown<String>(
                  name: "year",
                  initialValue: year,
                  items: usercontroller.year.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                    value: toElement.toString(),
                    child: Text(toElement.toString()),
                  )).toList(),
                  onChanged: (value) async {
                    year = value.toString();
                    setState(() {});
                    getAuditList();
                  },
                  validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                  decoration:  InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: AppTranslations.of(context)!.text("key_year"),
                        children: [

                        ],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(left: 20,top: 10),
                    counterText: "",
                    errorMaxLines: 3,
                    border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                    enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: Colors.red, width: 1.0)),
                    suffixIcon: null,

                  ),
                ),),
                SizedBox(width: 10,),
                Container(height: 40,width: 120,child: FormBuilderDropdown<dynamic>(
                  name: "month",
                  initialValue: month,
                  items: monthArr.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                    value: toElement["key"].toString(),
                    child: Text(toElement["value"].toString()),
                  )).toList(),
                  onChanged: (value) async {
                    month = value.toString();
                    setState(() {});
                    getAuditList();
                  },
                  validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                  decoration:  InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: AppTranslations.of(context)!.text("key_month"),
                        children: [

                        ],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(left: 20,top: 10),
                    counterText: "",
                    errorMaxLines: 3,
                    border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                    enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                    errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                        borderSide: BorderSide(color: Colors.red, width: 1.0)),
                    suffixIcon: null,

                  ),
                )),
                SizedBox(width: 10,),
              ],
            ),
            isBGTransparent: true,
            enableScroll: false,
            showTitle: true,
            padding: 0,
            child: auditList.length == 0 ?
            Norecordcomp()
                :Center(
              child: SizedBox(
                width: double.infinity,
                child: Responsive.isDesktop(context) ? PlutoGrid(
                  configuration: PlutoGridConfiguration(
                    columnSize: PlutoGridColumnSizeConfig(
                      autoSizeMode: PlutoAutoSizeMode.scale,
                      resizeMode: PlutoResizeMode.pushAndPull,
                    ),
                  ),
                  mode: PlutoGridMode.readOnly,
                  columns:column,
                  rows: rows,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                    stateManager.setPageSize(10, notify: false);
                    setState(() {});// Set rows per page
                  },
                  onChanged: (PlutoGridOnChangedEvent event) {
                    print(event);
                  },
                  createFooter: (stateManager) {
                    stateManager.setPageSize(10,notify: false);
                    return PlutoPagination(stateManager); // Enable pagination
                  },

                ) : ListView.builder(
                  itemCount: auditList.length,
                    itemBuilder: (context,index){
                      return getAuditCom(auditList[index]);
                    }
                ),
              ),
            ),
            title: AppTranslations.of(context)!.text("key_auditlist"),
            showButton: menuAccessRole.indexOf(usercontroller.userData.role!) != -1?true:false,
            callback: (){
              Navigator.pushNamed(context, "/addaudit",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditList));
            },
          ),
        ),
    );
  }
}
