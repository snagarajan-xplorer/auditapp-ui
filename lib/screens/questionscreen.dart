
import 'dart:io';

import 'package:audit_app/models/dynamicfield.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/outlinebutton.dart';
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

class Questionscreen extends StatefulWidget {
  const Questionscreen({super.key});

  @override
  State<Questionscreen> createState() => _QuestionscreenState();
}

class _QuestionscreenState extends State<Questionscreen> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  UserController usercontroller = Get.put(UserController());
  bool loadImage = false;
  String pageTitle = "";
  String sideTitle = "";
  List<dynamic> categorylist = [];
  List<dynamic> dropdownlist = [];
  ScreenArgument? pageargument;
  Uint8List? _imageBytes; // To store the image data
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
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      pageTitle = AppTranslations.of(context)!.text("key_user");
      sideTitle = AppTranslations.of(context)!.text("key_userdetails");
      usercontroller.dropdownlist = [];
      usercontroller.categorylist = [];
      usercontroller.getCategoryList(context, callback:(res){
        categorylist = res;
        usercontroller.getDropdownList(context, callback:(res02){
          dropdownlist = res02;
          setState(() {

          });
        });
      });
    });
  }



  Widget getSideContent(){
    return Expanded(
        flex: 3,
        child: Column(
          children: [
            Flexible(
                flex:1,
                child: BoxContainer(
                  width: double.infinity,
                  showButton: true,
                  buttonName: AppTranslations.of(context)!.text("key_addnew"),
                  showTitle:true,title:AppTranslations.of(context)!.text("key_category"),
                  child: Column(
                    children: categorylist.map<Widget>((toElement){
                      return Container(
                        height: 45,
                        padding: EdgeInsets.only(top: 8,bottom: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200, // Set the color of the border
                              width: 2.0,         // Set the width of the border
                            ),
                          ),
                        ),
                        child: Text(toElement["categoryname"],style: labelTextStyle,maxLines: 3,),
                      );
                    }).toList(),
                  ),
                )
            ),
            SizedBox(height: defaultPadding,),
            Flexible(
                flex:1,
                child: BoxContainer(
                  width: double.infinity,
                  height: double.infinity,
                  showButton: true,
                  buttonName: AppTranslations.of(context)!.text("key_addnew"),
                  showTitle:true,title:AppTranslations.of(context)!.text("key_dropdown"),
                  child: Column(
                    children: dropdownlist.map<Widget>((toElement){
                      return Container(
                        height: 45,
                        padding: EdgeInsets.only(top: 8,bottom: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200, // Set the color of the border
                              width: 2.0,         // Set the width of the border
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(toElement["dropdownname"],style: labelTextStyle,maxLines: 3,),
                            OutlineButtonComp(label: AppTranslations.of(context)!.text("key_add"), onPressed: (){})
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
            ),

          ],
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 5,
                    child: BoxContainer(
                        showTitle: true,
                        title: AppTranslations.of(context)!.text("key_question"),
                        height: double.infinity,
                        width: double.infinity,
                        child: Column(
                          children: [
                            FormBuilder(
                                child: Column(
                                  children: [
                                    FormBuilderDropdown<String>(
                                      name: "company",
                                      items: categorylist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                                        value: toElement["id"].toString(),
                                        child: Text(toElement["categoryname"]),
                                      )).toList(),
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
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    FormBuilderDropdown<String>(
                                      name: "category",
                                      items: categorylist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                                        value: toElement["id"].toString(),
                                        child: Text(toElement["categoryname"]),
                                      )).toList(),
                                      decoration:  InputDecoration(
                                        label: RichText(
                                          text: TextSpan(
                                            text: AppTranslations.of(context)!.text("key_category"),
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
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    FormBuilderTextField(
                                      name: "question",
                                      maxLines: 6,
                                      decoration:  InputDecoration(
                                        label: RichText(
                                          text: TextSpan(
                                            text: AppTranslations.of(context)!.text("key_question"),
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
                                    ),
                                    SizedBox(height: defaultPadding,),
                                    ButtonComp(
                                      width: 200,
                                        height: 35,
                                        label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){

                                    })
                                  ],
                                )
                            )

                          ],
                        )
                    )
                ),
                if(Responsive.isDesktop(context))
                  SizedBox(width: defaultPadding,),
                if(Responsive.isDesktop(context))
                  getSideContent()

              ],
            ),
          ),
        )
    );
  }
}
