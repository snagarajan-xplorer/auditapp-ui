
import 'dart:io';

import 'package:audit_app/models/dynamicfield.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
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
import '../services/LocalStorage.dart';
import '../widget/buttoncomp.dart';
import 'main/layoutscreen.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  UserController usercontroller = Get.put(UserController());
  bool loadImage = false;
  String pageTitle = "";
  String sideTitle = "";
  bool showCamera = false;
  String mode = "Add";
  String status = "A";
  List<dynamic> clientArr = [];
  ScreenArgument? pageargument;
  String headerLable = "";
  bool showActive = false;
  Uint8List? _imageBytes; // To store the image data
  String? _imageName = ""; // To store the image file name

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
    Future.delayed(Duration(milliseconds: 400))
    .then((value) async {
      if(usercontroller.userData.role == null){
        usercontroller.loadInitData();
        String? str = await LocalStorage.getStringData("arguments");
        if(str == "User"){
          Navigator.pushNamed(context, "/user",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
        }else{
          Navigator.pushNamed(context, "/client",arguments: ScreenArgument(argument: str == "User" ? ArgumentData.USER : ArgumentData.CLIENT,mapData: {}));
        }

      }
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;

      usercontroller.getClientList(context, data: {"role":usercontroller.userData.role,"client_id":usercontroller.userData.clientid},
          callback: (res){
            clientArr = res;

            if(pageargument?.argument == ArgumentData.USER){


              pageTitle = AppTranslations.of(context)!.text("key_user");
              sideTitle = AppTranslations.of(context)!.text("key_userdetails");
              headerLable = AppTranslations.of(context)!.text("key_message_08");
              showCamera = true;
            }else if(pageargument?.argument == ArgumentData.CLIENT){

              pageTitle = AppTranslations.of(context)!.text("key_client");
              sideTitle = AppTranslations.of(context)!.text("key_clientdetails");
              headerLable = AppTranslations.of(context)!.text("key_message_07");
              showCamera = false;
            }
            Future.delayed(Duration(milliseconds: 200))
            .then((resvalue){
              if(pageargument?.mode == "Edit"){
                _imageName = pageargument?.editData!["image"];
                mode = "Edit";
                status = pageargument?.editData!["status"];
                if(pageargument?.editData!["client"].toString().indexOf(",") != -1){
                  pageargument?.editData!["client"] = pageargument?.editData!["client"].toString().split(",");
                }else{
                  pageargument?.editData!["client"] = pageargument?.editData!["client"].toString();
                }
                formKey.currentState?.patchValue(pageargument?.editData ?? {});
                print(usercontroller.formArray);
              }
            });
            showActive = true;
            setState(() {});
          });

    });
  }



  Widget getRoleData(){
    return usercontroller.role.length == 0 ?Container()
    :Container(
      height: usercontroller.role.length*60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppTranslations.of(context)!.text("key_roleid"),style: paragraphTextStyle,),
              Text(AppTranslations.of(context)!.text("key_rolename"),style: paragraphTextStyle,)
            ],
          ),
          SizedBox(height: 20,),
          Flexible(
              child: Container(
                child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: usercontroller.role.length,
                    itemBuilder: (context,index){
                      return Container(
                        padding: EdgeInsets.only(top: 10,bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(usercontroller.role[index]["roleid"],style: paragraphTextStyle,),
                            Text(usercontroller.role[index]["rolename"],style: paragraphTextStyle,)
                          ],
                        ),
                      );
                    }
                ),
              )
          )
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        previousScreenName:headerLable,
        showBackbutton: true,
        child: SafeArea(

          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: PageContainerComp(
                showTitle: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            flex:1,
                            child: Align(
                              alignment: Alignment.center,
                              child: Visibility(
                                  visible:showCamera,
                                  child: InkWell(
                                    onTap: () async {
                                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                                        type: FileType.image, // Restrict to image files
                                        allowMultiple: false,
                                      );

                                      if (result != null && result.files.isNotEmpty) {
                                        setState(() {
                                          _imageBytes = result.files.first.bytes; // Image data
                                          _imageName = result.files.first.name;  // File name
                                          loadImage = true;
                                        });
                                      }
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 100,
                                      height: 100,


                                      child: Stack(
                                        children: [
                                          Positioned(
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                    border: Border.all(width: 2,color: bgColor),
                                                    borderRadius: BorderRadius.all(Radius.circular(50)),
                                                    image: DecorationImage(image: mode == "Add" ? loadImage == false ? AssetImage("assets/images/person.jpeg") : MemoryImage(_imageBytes!):_imageName != null ? NetworkImage(IMG_URL+_imageName!):AssetImage("assets/images/person.jpeg"))
                                                ),
                                              )
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Visibility(

                                                  child: Icon(CupertinoIcons.camera_rotate_fill,size: 30,color: Theme.of(context).primaryColor,)
                                              )
                                          )

                                        ],
                                      ),
                                    ),
                                  )
                              ),
                            )
                        ),
                      ],
                    ),
                    SizedBox(height: defaultPadding,),
                    DynamicForm(
                formKey: formKey,
                id: 0,
                transactionType: "",
                showCancelBtn: false,
                dynamicArr: usercontroller.formArray,
                selectionChange: (obj){
                  if(obj.fieldname == "pincode"){
                    usercontroller.getPinCode(context, pincode: obj.fieldvalue, callback:(res){
                      List<DynamicField> arr = usercontroller.formArray.where((element)=>element.fieldName == "city").toList();
                      if(arr.length != 0){
                        arr[0].options = res.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                          value: toElement["Name"].toString(),
                          child: Text(toElement["Name"]),
                        )).toList();
                        setState(() {});
                      }
                      formKey.currentState?.patchValue({
                        "district":res[0]["District"],
                        "state":res[0]["State"]
                      });
                    });
                  }else if(obj.fieldname == "role"){
                    print(obj.fieldvalue );
                    List<DynamicField> clientid = usercontroller.formArray.where((element) => element.fieldName == "client").toList();
                    List<DynamicField> parentid = usercontroller.formArray.where((element) => element.fieldName == "parentid").toList();
                    if(obj.fieldvalue == "AD"){
                      if(clientid.length != 0 && parentid.length != 0){
                        clientid[0].mandatory = "N";
                        parentid[0].mandatory = "N";
                        clientid[0].disabledYN = "Y";
                        parentid[0].disabledYN = "Y";
                        clientid[0].visibility = "N";
                        parentid[0].visibility = "N";
                        clientid[0].rules = [];
                        parentid[0].rules = [];
                        clientid[0].validator = FormBuilderValidators.compose([]);
                        parentid[0].validator = FormBuilderValidators.compose([]);
                      }
                    }else if(obj.fieldvalue == "JrA"){
                      if(clientid.length != 0 && parentid.length != 0){
                        clientid[0].mandatory = "N";
                        parentid[0].mandatory = "N";
                        clientid[0].disabledYN = "Y";
                        parentid[0].disabledYN = "Y";
                        clientid[0].visibility = "N";
                        parentid[0].visibility = "N";
                        clientid[0].rules = [];
                        parentid[0].rules = [];
                        clientid[0].validator = FormBuilderValidators.compose([]);
                        parentid[0].validator = FormBuilderValidators.compose([]);
                      }
                    }else if(obj.fieldvalue == "SrA"){
                      if(clientid.length != 0  && parentid.length != 0){
                        clientid[0].mandatory = "Y";
                        clientid[0].visibility = "Y";
                        clientid[0].rules = [];
                        clientid[0].rules!.add(Rules.fromJson(req));
                        UtilityService().addValidators(clientid[0]);
                        parentid[0].mandatory = "N";
                        parentid[0].visibility = "N";
                        parentid[0].rules = [];
                        parentid[0].validator = FormBuilderValidators.compose([]);
                      }
                    }
                  }
                },
                callback: (form){
                  print(form["formdata"]);

                  if(pageargument?.mode == "Edit"){
                    form["formdata"]["id"] = pageargument?.editData!["id"];
                  }
                  print(form["formdata"]);
                  print(pageargument?.editData);
                  form["formdata"]["status"] = status;

                  if(pageargument?.argument == ArgumentData.USER){
                    // if(_imageName!.isEmpty){
                    //   APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_12"),callback: (){});
                    //   return;
                    // }
                    DateTime d = form["formdata"]["joiningdate"] ?? Jiffy.now().dateTime;
                    form["formdata"]["joiningdate"] = d.toIso8601String();
                    if(form["formdata"]["role"] == "AD" || form["formdata"]["role"] == "JrA"){
                      form["formdata"]["client"] = "0";
                      form["formdata"]["parentid"] = 0;
                    }else if(form["formdata"]["role"] == "SrA"){
                      form["formdata"]["parentid"] = 0;
                      form["formdata"]["client"] = form["formdata"]["client"].join(', ');
                    }
                    //form["formdata"]["client"] = "";
                    //form["formdata"]["client"] = form["formdata"]["client"].join(', ');
                    usercontroller.register(context, data: form["formdata"], callback:(res){
                      var min = res["mid"];
                      if(_imageBytes != null){
                        usercontroller.uploadImage(context,bytes: _imageBytes, filename: _imageName ?? "", data: {"id":min,"type":"profile"}, callback:(res01){
                          Navigator.pushNamed(context, "/user",arguments: pageargument);
                        });
                      }else{
                        Navigator.pushNamed(context, "/user",arguments: pageargument);
                      }
                    });
                  }else{
                    String idvalue = form["formdata"]["client"].toString();
                    List<dynamic> objArr = usercontroller.clinetArr.where((element)=>element["clientid"].toString() == idvalue).toList();
                    if(objArr.length != 0){
                      print(objArr[0]);
                      form["formdata"]["image"] = objArr[0]["logo"];
                      form["formdata"]["companyname"] = objArr[0]["clientname"];
                    }
                    form["formdata"]["role"] = "CL";
                    form["formdata"]["parentid"] = 0;
                    form["formdata"]["pincode"] = " ";
                    form["formdata"]["state"] = " ";
                    form["formdata"]["city"] = " ";
                    form["formdata"]["district"] = " ";
                    form["formdata"]["address"] = " ";
                    //form["formdata"]["client"] = form["formdata"]["client"].join(', ');
                    usercontroller.register(context, data: form["formdata"], callback:(res){
                      Navigator.pushNamed(context, "/user",arguments: pageargument);
                    });
                  }
                }, buttonName: AppTranslations.of(context)!.text("key_btn_proceed"),
              ),
                  ],
                )
                , title: pageTitle
            ),
          ),
        )
    );;
  }
}
