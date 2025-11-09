
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import 'package:audit_app/models/dynamicfield.dart';
import 'package:audit_app/screens/dashboard/components/storage_info_card.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/outlinebutton.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jiffy/jiffy.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../dynamicform/dynamicform.dart';
import '../localization/app_translations.dart';
import '../models/screenarguments.dart';
import '../responsive.dart';
import 'main/layoutscreen.dart';

class AddAuditScreen extends StatefulWidget {
  const AddAuditScreen({super.key});

  @override
  State<AddAuditScreen> createState() => _AddAuditScreenState();
}

class _AddAuditScreenState extends State<AddAuditScreen> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  UserController usercontroller = Get.put(UserController());
  bool loadImage = false;
  String pageTitle = "";
  String sideTitle = "";
  String mode = "Add";
  String modifyRemarks = "";
  List<dynamic> customerlist = [];
  List<dynamic> clientlist = [];
  List<dynamic> auditorlist = [];
  List<dynamic> templatelist = [];
  List<dynamic> auditlist = [];
  List<dynamic> citylist = [];
  List<String> zone = [];
  ScreenArgument? pageargument;
  bool loadData = false;
  DateTime initialDate = Jiffy.now().dateTime;
  DateTime firstDate = Jiffy.now().dateTime;
  DateTime lastDate = Jiffy.now().add(months: 8).dateTime;
  String? _image; // To store the image data
  String? _imageName; // To store the image file name

  var req = {
    "validationInfoId": 0,
    "name": "required",
    "type": "client",
    "errorMsg": "Please enter value",
    "errorMsgBl1": "الرجاء إدخال البريد الإلكتروني",
    "script": ""
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 300))
        .then((value){
      if(usercontroller.userData.role == null){
        usercontroller.loadInitData();
        Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
      }
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      auditlist = pageargument?.mapData;
      pageTitle = AppTranslations.of(context)!.text("key_user");
      sideTitle = AppTranslations.of(context)!.text("key_userdetails");
      usercontroller.getClientList(context, data: {"role":usercontroller.userData.role,"client_id":usercontroller.userData.clientid},
          callback: (res){
          clientlist = res;
            usercontroller.getUserList(context,data:{"role": "JrA","status":"A"}, callback:(res){
              customerlist = res.where((element)=> element["role"] == "CL").toList();
              auditorlist = res.where((element)=> element["role"] == "JrA").toList();
              usercontroller.getZone(context, callback: (res2){
                zone = res2.map((toElement)=>toElement.toString()).toList();
                if(pageargument?.mode == "Edit"){
                  _imageName = pageargument?.editData!["image"];
                  mode = "Edit";
                  pageargument?.editData!["client_id"] = pageargument?.editData!["client_id"].toString();
                  pageargument?.editData!["start_date"] = Jiffy.parse(pageargument?.editData!["start_date"]).dateTime;
                  pageargument?.editData!["start_time"] = Jiffy.parse(pageargument?.editData!["start_time"]).dateTime;
                  initialDate = pageargument?.editData!["start_time"];
                  firstDate = pageargument?.editData!["start_time"];
                  lastDate = Jiffy.now().add(months: 8).dateTime;
                  usercontroller.getTemplateList(context, clientid: pageargument?.editData!["client_id"].toString() ?? "0", callback:(res){
                    templatelist = res;
                    Future.delayed(Duration(milliseconds: 400))
                        .then((onValue){
                      loadData = true;
                      setState(() {

                      });
                      formKey.currentState?.patchValue(pageargument?.editData ?? {});
                    });
                  });
                }
                setState(() {});
              });
              setState(() {});
            });
      });

    });
  }
  List<Widget> childCollection_01(){
    return [
      Flexible(
          flex: 1,
          child: FormBuilderTextField(
            name: "branch",
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (value){

            },
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: "Audit Branch",
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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

            ),
          )
      ),
      Responsive.isDesktop(context)?SizedBox(width: defaultPadding,):SizedBox(height: defaultPadding,),
      Flexible(
          flex:1,
          child: FormBuilderDropdown<String>(
            name: "assigned_user",
            items: auditorlist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
              value: toElement["id"].toString(),
              child: Text(toElement["name"]),
            )).toList(),
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_assign"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
          )
      ),
    ];
  }

  List<Widget> childCollection_02(){
    return [
      Flexible(
          flex:1,
          child: FormBuilderDateTimePicker(
            name: "start_date",
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            timePickerInitialEntryMode: TimePickerEntryMode.dialOnly,
            style: Theme.of(context).textTheme.bodyMedium,
            inputType: InputType.date,
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_startdate"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
              suffixIcon: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 20.0,
              ),

            ),
          )
      ),
      Responsive.isDesktop(context)?SizedBox(width: defaultPadding,):SizedBox(height: defaultPadding,),
      Flexible(
          flex:1,
          child: FormBuilderDateTimePicker(
            name: "start_time",
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            timePickerInitialEntryMode: TimePickerEntryMode.dialOnly,
            style: Theme.of(context).textTheme.bodyMedium,
            inputType: InputType.time,
            format: DateFormat.jm(),
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_starttime"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
              suffixIcon: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 20.0,
              ),

            ),
          )
      ),

    ];
  }

  List<Widget> childCollection_03(){
    return [
      Flexible(
          flex:1,
          child: FormBuilderDropdown<String>(
            name: "zone",
            items: zone.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
              value: toElement,
              child: Text(toElement),
            )).toList(),
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_zone"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
          )
      ),
      Responsive.isDesktop(context)?SizedBox(width: defaultPadding,):SizedBox(height: defaultPadding,),
      Flexible(
          child: FormBuilderTextField(
            name: "pincode",
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
            maxLength: 6,
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (value){
              if(value.toString().length == 6){
                usercontroller.getPinCode(context, pincode: value.toString(), callback:(res){
                  citylist = res;
                  setState(() {});
                  formKey.currentState?.patchValue({
                    "state":res[0]["State"],
                    "district":res[0]["District"]
                  });
                });
              }
            },
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_pincode"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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

            ),
          )
      )
    ];
  }
  List<Widget> childCollection_04(){
    return [
      Flexible(
          child: FormBuilderTextField(
            name: "address",
            style: Theme.of(context).textTheme.bodyMedium,
            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: "Address",
                  children: [

                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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

            ),
          )
      ),
      Responsive.isDesktop(context)?SizedBox(width: defaultPadding,):SizedBox(height: defaultPadding,),
      Flexible(
          flex:1,
          child: FormBuilderTextField(
            name: "district",
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            style: Theme.of(context).textTheme.bodyMedium,

            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: "District",
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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


            ),
          )
      ),


    ];
  }
  List<Widget> childCollection_05(){
    return [
      Flexible(
          child: FormBuilderDropdown<String>(
        name: "city",
        items: citylist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
          value: toElement["Name"].toString(),
          child: Text(toElement["Name"]),
        )).toList(),
        validator: FormBuilderValidators.compose([FormBuilderValidators.required(
            errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
        onChanged: (value){

        },
        decoration:  InputDecoration(
          label: RichText(
            text: TextSpan(
              text: AppTranslations.of(context)!.text("key_city"),
              children: [
                TextSpan(
                    style: TextStyle(color: Colors.red),
                    text: ' *'
                )
              ],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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

      Responsive.isDesktop(context)?SizedBox(width: defaultPadding,):SizedBox(height: defaultPadding,),
      Flexible(
          flex:1,
          child: FormBuilderTextField(
            name: "state",
            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
            style: Theme.of(context).textTheme.bodyMedium,

            decoration:  InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: AppTranslations.of(context)!.text("key_state"),
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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


            ),
          )
      ),


    ];
  }
  Widget buttonComp(){
    return Flexible(
        flex:1,
        child: ButtonComp(
            width: double.infinity,
            height: 35,
            label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
          if(formKey.currentState!.saveAndValidate()){

            Map<String,dynamic> data = {};
            formKey.currentState!.value.forEach((key,value){
              if(key.contains("date") || key.contains("time")){
                data[key] = Jiffy.parseFromDateTime(value).dateTime.toIso8601String();
              }else{
                data[key] = value;
              }
            });
            data["end_date"] = data["start_date"];
            data["end_time"] = data["start_time"];
            data["created_user"] = usercontroller.userData.userId;
            final deepEquality = const DeepCollectionEquality();

            if(pageargument?.mode == "Edit"){
              data["id"] = pageargument?.editData!["id"];
              Map<String,dynamic> editObj = {};

              data.forEach((key,value){
                editObj[key] = pageargument?.editData![key];
              });
              editObj["id"] = data["id"];
              editObj["start_date"] = Jiffy.parse(data["start_date"]).dateTime.toIso8601String();
              editObj["start_time"] = Jiffy.parse(data["start_time"]).dateTime.toIso8601String();
              editObj["created_user"] = usercontroller.userData.userId;
              print(editObj);
              print(data);
              if(deepEquality.equals(editObj, data)){
                usercontroller.saveAudit(context, data: data, callback: (){
                  Navigator.pushNamed(context, "/auditlist",arguments: pageargument);
                });
              }else{
                APIService(context).showWindowContentAlert(
                  title: AppTranslations.of(context)!.text("key_change_audit"),
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
                              "audit_id":data["id"],
                              "remarks":modifyRemarks,
                              "type":"Change Audit Data",
                              "userid":usercontroller.userData.userId,
                            };
                            usercontroller.sendAuditComments(context,data: dObj,callback: (){
                              usercontroller.saveAudit(context, data: data, callback: (){
                                Navigator.pushNamed(context, "/auditlist",arguments: pageargument);
                              });
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
            }else{
              usercontroller.saveAudit(context, data: data, callback: (){
                Navigator.pushNamed(context, "/auditlist",arguments: pageargument);
              });
            }



            //formKey.currentState!.value["start_date"] =

          }
        })
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        previousScreenName:AppTranslations.of(context)!.text("key_message_06"),
      showBackbutton: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 5,
                    child: PageContainerComp(
                        showTitle: true,
                        title: AppTranslations.of(context)!.text("key_createaudit"),
                        child:Column(
                          children: [
                            Container(
                              width: 150,
                              height: 100,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    border: Border.all(width: 2,color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    image: DecorationImage(image: loadImage == false ? AssetImage("assets/images/person.jpeg") : NetworkImage(_image!))
                                ),
                              ),
                            ),
                            SizedBox(height: defaultPadding,),
                            FormBuilder(
                                key: formKey,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                            flex: 1,
                                            child: FormBuilderDropdown<String>(
                                              name: "client_id",
                                              items: clientlist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                                                value: toElement["clientid"].toString(),
                                                child: Text(toElement["clientname"]),
                                              )).toList(),
                                              validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                                  errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                              onChanged: (value){
                                                List<dynamic> selectCompany = clientlist.where((element)=>element["clientid"].toString() == value.toString()).toList();
                                                if(selectCompany.length != 0){
                                                  _image = IMG_URL+selectCompany[0]["logo"];
                                                  loadImage = true;
                                                  setState(() {

                                                  });
                                                }
                                                usercontroller.getTemplateList(context, clientid: value.toString(), callback:(res){
                                                  templatelist = res;
                                                  if(mode == "Edit" && loadData){
                                                    loadData = false;
                                                    setState(() {

                                                    });
                                                    Future.delayed(Duration(milliseconds: 400))
                                                        .then((onValue){
                                                      formKey.currentState?.patchValue( {"template_id":pageargument?.editData!["template_id"]});
                                                    });
                                                  }
                                                  setState(() {

                                                  });
                                                });
                                              },
                                              decoration:  InputDecoration(
                                                label: RichText(
                                                  text: TextSpan(
                                                    text: AppTranslations.of(context)!.text("key_comany"),
                                                    children: [
                                                      TextSpan(
                                                          style: TextStyle(color: Colors.red),
                                                          text: ' *'
                                                      )
                                                    ],
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),


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
                                            )
                                        ),

                                      ],
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    Row(children: [
                                      Flexible(
                                          flex:1,
                                          child: FormBuilderDropdown<String>(
                                            name: "template_id",
                                            items: templatelist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                                              value: toElement["id"].toString(),
                                              child: Text(toElement["templatename"]),
                                            )).toList(),
                                            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                            decoration:  InputDecoration(
                                              label: RichText(
                                                text: TextSpan(
                                                  text: AppTranslations.of(context)!.text("key_template"),
                                                  children: [
                                                    TextSpan(
                                                        style: TextStyle(color: Colors.red),
                                                        text: ' *'
                                                    )
                                                  ],
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ),
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
                                          )
                                      ),
                                    ],),
                                    SizedBox(height: defaultPadding,),
                                    FormBuilderTextField(
                                      name: "auditname",
                                      validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                          errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      onChanged: (value){

                                      },
                                      decoration:  InputDecoration(
                                        label: RichText(
                                          text: TextSpan(
                                            text: AppTranslations.of(context)!.text("key_auditname"),
                                            children: [
                                              TextSpan(
                                                  style: TextStyle(color: Colors.red),
                                                  text: ' *'
                                              )
                                            ],
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
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

                                      ),
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    Responsive.isDesktop(context) ? Row(
                                      children: childCollection_01(),
                                    ):Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: childCollection_01(),
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    Responsive.isDesktop(context) ? Row(
                                      children: childCollection_02(),
                                    ):Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: childCollection_02(),
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    FormBuilderTextField(
                                      name: "remarks",
                                      maxLines: 4,
                                      validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                          errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      decoration:  InputDecoration(
                                        label: RichText(
                                          text: TextSpan(
                                            text: AppTranslations.of(context)!.text("key_notes"),
                                            children: [
                                              TextSpan(
                                                  style: TextStyle(color: Colors.red),
                                                  text: ' *'
                                              )
                                            ],
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.only(left: 20,top: 25),
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
                                    Text(AppTranslations.of(context)!.text("key_message_25"),style: TextStyle(fontSize: paragraphFontSize),),
                                    SizedBox(height: defaultPadding,),
                                    Responsive.isDesktop(context) ? Row(
                                      children: childCollection_03(),
                                    ):Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: childCollection_03(),
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    Responsive.isDesktop(context) ? Row(
                                      children: childCollection_04(),
                                    ):Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: childCollection_04(),
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    Responsive.isDesktop(context) ? Row(
                                      children: childCollection_05(),
                                    ):Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: childCollection_05(),
                                    ),
                                    SizedBox(height: defaultPadding,),

                                    Responsive.isDesktop(context) ? Row(
                                      children: [
                                        Flexible(
                                            flex:1,
                                            child: Container()
                                        ),
                                        SizedBox(width: defaultPadding,),
                                        buttonComp(),
                                        SizedBox(width: defaultPadding,),
                                        Flexible(
                                            child: Container()
                                        )
                                      ],
                                    ):buttonComp(),

                                  ],
                                )
                            )

                          ],
                        )
                    )
                ),


              ],
            ),
          ),
        )
    );
  }
}
