

import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:audit_app/theme/themes.dart';
import 'package:audit_app/widget/containerwithbgimage.dart';
import '../localization/app_translations.dart';
import '../models/screenarguments.dart';
import '../services/api_service.dart';
import '../widget/boxcontainer.dart';
import '../widget/buttoncomp.dart';
import '../widget/datatablecontainer.dart';
import '../widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jiffy/jiffy.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../widget/outlinebutton.dart';
import '../widget/statuscomp.dart';
import 'main/layoutscreen.dart';
import 'dart:js' as js;

class AuditInfoScreen extends StatefulWidget {
  const AuditInfoScreen({super.key});

  @override
  State<AuditInfoScreen> createState() => _AuditInfoScreenState();
}

class _AuditInfoScreenState extends State<AuditInfoScreen> {
  ScreenArgument? pageargument;
  UserController usercontroller = Get.put(UserController());
  dynamic auditObj = null;
  String modifyRemarks = "";
  bool disabledButton = true;




  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 200))
        .then((onValue){
      if(usercontroller.userData.role == null){
        usercontroller.loadInitData();
        usercontroller.selectedIndex = 1;
        Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
      }
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      auditObj = pageargument?.mapData;
      usercontroller.getCurrentDate(context, data: {}, callback: (res){
        print("res ${auditObj}");
        int logintime = Jiffy.parse(res["logintime"],pattern: "yyyy-MM-dd h:m:s").millisecondsSinceEpoch;

        DateTime date = Jiffy.parseFromDateTime(DateTime.parse(auditObj["start_date"])).dateTime;
        DateTime time = Jiffy.parseFromDateTime(DateTime.parse(auditObj["start_time"])).dateTime;

// Combine them into one DateTime
        int audittime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
          time.second,
        ).millisecondsSinceEpoch;
        if(logintime >= audittime){
          disabledButton = false;
        }
        print("auditObj ${auditObj}");
        setState(() {});
      });

    });
  }
  Widget logoComp(img){
    return ContainerBgImage(
      height: 240,
      width: 350,
      imgPath: IMG_URL+img,
    );
  }
  Widget sideContent(element){
    String status = AppTranslations.of(context)!.text("key_create");
    if(element["status"] == "IP"){
      status = AppTranslations.of(context)!.text("key_progress");
    }else if(element["status"] == "PG"){
      status = AppTranslations.of(context)!.text("key_progress");
    }else if(element["status"] == "C"){
      if(usercontroller.userData.role == "CL"){
        status = AppTranslations.of(context)!.text("key_complete");
      }else{
        status = AppTranslations.of(context)!.text("key_complete");
      }
    }else if(element["status"] == "S"){
      status = AppTranslations.of(context)!.text("key_create");
    }else if(element["status"] == "P"){
      status = AppTranslations.of(context)!.text("key_publish");
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

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
      ],
    );
  }
  launchURLPage() async {
    // final Uri url = Uri.parse(API_URL+"export?id="+auditObj["id"].toString());
    // await launchUrl(
    //   url,
    //   webOnlyWindowName: '_blank',
    // );
    js.context.callMethod('open', [API_URL+"export?type=1&id="+auditObj["reporturl"].toString(),"_blank"]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        previousScreenName:AppTranslations.of(context)!.text("key_auditlist"),
        showBackbutton: true,
        child: PageContainerComp(
            isBGTransparent: true,
            padding: 0,
            child: Center(
              child:  auditObj == null?SizedBox():BoxContainer(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height-150,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Responsive.isDesktop(context) ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 1,
                                child: Text(auditObj["companyname"],style: headingTextStyle,)
                            ),
                            Visibility(
                                visible: ["C","P","CL"].indexOf(auditObj["status"]) == -1 ? true : false,
                                child: ButtonComp(
                                    height: buttonHeight,
                                    icon:Icon(Icons.download),
                                    color: kPrimaryColor,
                                    width: 250,
                                    label: AppTranslations.of(context)!.text("key_btn_download_01"),
                                    onPressed: (){
                                      launchURLPage();

                                    }
                                )
                            ),

                          ],
                        ) : Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                                child: Center(child: Text(auditObj["companyname"],style: headingTextStyle,))
                            ),
                            Visibility(
                                visible: ["C","P","CL"].indexOf(auditObj["status"]) == -1 ? true : false,
                                child: ButtonComp(
                                    height: buttonHeight,
                                    icon:Icon(Icons.download),
                                    color: kPrimaryColor,
                                    width: 250,
                                    label: AppTranslations.of(context)!.text("key_btn_download_01"),
                                    onPressed: (){
                                      launchURLPage();

                                    }
                                )
                            ),
                          ],
                        ),
                        SizedBox(height: 15,),
                        // Align(
                        //   alignment: Alignment.centerLeft,
                        //   child: Text(auditObj["city"]+","+auditObj["state"]+","+auditObj["zone"],textAlign: TextAlign.left,),
                        // ),
                        // SizedBox(height: 15,),
                        Responsive.isDesktop(context)?Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            logoComp(auditObj["image"]),
                            SizedBox(width: defaultPadding,),
                            Flexible(
                                flex: 1,
                                child: Container(
                                  child: sideContent(auditObj),
                                )
                            )
                          ],
                        ):sideContent(auditObj),
                        SizedBox(height: 15,),
                        Text(auditObj["remarks"],style: paragTextStyle,maxLines: 10,),
                        SizedBox(height: 15,),
                        Visibility(
                            visible: ["C","P","CL"].indexOf(auditObj["status"]) == -1 && usercontroller.userData.role == "JrA"? true : false,
                            //   visible: false,
                            child: Center(
                              child: Container(
                                width: 320,
                                child: Row(
                                  children: [
                                    ButtonComp(
                                      disabled: disabledButton,
                                        height: buttonHeight,
                                        color: Colors.green,
                                        width: 130,
                                        label: AppTranslations.of(context)!.text("key_start_audit"),
                                        onPressed: (){
                                          Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));

                                        }
                                    ),
                                    SizedBox(width: defaultPadding,),
                                    ButtonComp(
                                        height: buttonHeight,
                                        color: kPrimaryColor,
                                        width: 150,
                                        label: AppTranslations.of(context)!.text("key_btn_cancel_Audit"),
                                        onPressed: (){
                                          APIService(context).showWindowContentAlert(
                                            title: AppTranslations.of(context)!.text("key_btn_cancel_Audit"),
                                            child:Container(
                                              color: Colors.white,
                                              height: 200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  FormBuilderTextField(
                                                    name: "remarksvalue",
                                                    maxLines: 6,
                                                    initialValue: modifyRemarks,
                                                    onChanged: (value){
                                                      modifyRemarks = value!;
                                                      setState(() {

                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      label: RichText(
                                                        text: TextSpan(
                                                          text: AppTranslations.of(context)!.text("key_remark"),
                                                          children: [
                                                            TextSpan(
                                                                style: TextStyle(color: Colors.red),
                                                                text: ' *'
                                                            )
                                                          ],
                                                          style: Theme.of(context).textTheme.bodyMedium,
                                                        ),
                                                      ),

                                                      contentPadding: EdgeInsets.only(left: 20,top: 20,right: 20),
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
                                                    ),
                                                  ),
                                                  SizedBox(height: defaultPadding,),
                                                  Row(
                                                    children: [
                                                      ButtonComp(width:100,label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
                                                        if(modifyRemarks.isEmpty){
                                                          APIService(context).showToastMgs(AppTranslations.of(context)!.text("key_error_08"));
                                                          return;
                                                        }
                                                        Map<String,dynamic> dObj = {
                                                          "audit_id":auditObj["id"],
                                                          "remarks":modifyRemarks,
                                                          "type":"Cancel Audit",
                                                          "userid":usercontroller.userData.userId,
                                                        };
                                                        usercontroller.sendAuditComments(context,data: dObj,callback: (){
                                                          Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                                        },errorcallback:(res){});
                                                      }),
                                                      SizedBox(width: defaultPadding,),
                                                      ButtonComp(width:100,color:Colors.grey,label: AppTranslations.of(context)!.text("key_btn_cancel"), onPressed: (){
                                                        Navigator.of(context).pop();
                                                      })
                                                    ],
                                                  )

                                                ],
                                              ),
                                            ),allowClosePopup: true,);

                                        }
                                    )
                                  ],
                                ),
                              ),
                            )
                        ),
                        Visibility(
                            visible: auditObj["status"] == "C" && usercontroller.userData.role != "JrA" && usercontroller.userData.role != "CL"? true : false,
                            child: Container(
                              width: 350,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ButtonComp(
                                      height: buttonHeight,
                                      width: 90,
                                      label: AppTranslations.of(context)!.text("key_edit"),
                                      onPressed: (){
                                        //Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                        Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                      }
                                  ),
                                  ButtonComp(
                                      height: buttonHeight,
                                      width: 90,
                                      label: AppTranslations.of(context)!.text("key_publish"),
                                      onPressed: (){
                                        Map<String,dynamic> dataobj = {"client_id":auditObj["client_id"]};
                                        usercontroller.getClientUserList(context,data: dataobj,errorcallback:(res){
                                          if(res.containsKey("message")){
                                            APIService(context).showWindowAlert(title: "",desc: res["message"],callback: (){
                                              Navigator.pushNamed(context, "/client",arguments: ScreenArgument(argument: ArgumentData.CLIENT,mapData: {}));
                                            });
                                          }
                                        },callback: (arr) async {
                                          if(arr.length == 0){
                                            return;
                                          }
                                          arr.forEach((ele)=>ele["checked"]=false);
                                          SizedBox col = SizedBox(
                                            height: 250,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(AppTranslations.of(context)!.text("key_message_10")),
                                                SizedBox(
                                                  height: defaultPadding,
                                                ),
                                                SizedBox(
                                                  height: 200,
                                                  child: ListView(
                                                    shrinkWrap: false,
                                                    children: arr.map<Widget>((ele)=>Padding(
                                                      padding: const EdgeInsets.only(top: 4,bottom: 4),
                                                      child: FormBuilderCheckbox(
                                                        checkColor: Colors.white,
                                                        activeColor: Colors.blue.shade900,
                                                        initialValue: ele["checked"],
                                                        onChanged: (bool? value) {
                                                          if(ele["checked"] == true){
                                                            ele["checked"] = false;
                                                          }else{
                                                            ele["checked"] = true;
                                                          }
                                                          setState(() {

                                                          });
                                                        }, name: 'ele', title: Text(ele["email"],style: paragraphTextStyle,),
                                                      ),
                                                    )).toList(),
                                                  ),
                                                )
                                              ],
                                            ),
                                          );
                                          APIService(context).showWindowAlert(title: "",desc: "",
                                              showCancelBtn: true,
                                              allowClosePopup: false,
                                              child: col,callback: (){
                                            List<dynamic> dataObjArr = arr.where((_element)=>_element["checked"]).toList();
                                            if(dataObjArr.length == 0){
                                              APIService(context).showToastMgs(AppTranslations.of(context)!.text("key_message_20"));
                                              return;
                                            }
                                                Navigator.of(context).pop();
                                                Map<String,dynamic> publishobj = {"audit_id":auditObj["audit_no"],"audit_name":auditObj["auditname"],"dataArr":arr};
                                                usercontroller.publishUserReport(context,data: publishobj,callback: () async {
                                                  Map<String,dynamic> dataobj = {"audit_id":auditObj["id"],"userid":usercontroller.userData.userId};
                                                  usercontroller.publishAuditStatus(context,data: dataobj,callback: () async {

                                                    Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                                  });
                                                });
                                              });
                                          //Navigator.pushNamed(context, "/dashboard",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: element));
                                        });

                                      }
                                  ),
                                  ButtonComp(
                                      height: buttonHeight,
                                      width: 120,
                                      label: AppTranslations.of(context)!.text("key_report"),
                                      onPressed: (){
                                        //Navigator.pushNamed(context, "/auditinfo",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                        Navigator.pushNamed(context, "/auditdetails",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                        //Navigator.pushNamed(context, "/auditcategorylist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: auditObj));
                                      }
                                  ),
                                ],
                              ),
                            )
                        ),
                      ],
                    ),
                  )
              ),
            ),
            showTitle: true,
            showButton: false,
            title: AppTranslations.of(context)!.text("key_details"))
    );

  }
}
