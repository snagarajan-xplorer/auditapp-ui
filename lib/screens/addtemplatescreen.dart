import 'dart:io';

import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jiffy/jiffy.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import 'main/layoutscreen.dart';
import 'dart:js' as js;

class AddTemplateScreen extends StatefulWidget {
  const AddTemplateScreen({super.key});

  @override
  State<AddTemplateScreen> createState() => _AddTemplateScreenState();
}

class _AddTemplateScreenState extends State<AddTemplateScreen> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  UserController usercontroller = Get.put(UserController());
  bool loadImage = false;
  String pageTitle = "";
  String sideTitle = "";
  String mode = "Add";
  String modifyRemarks = "";
  List<dynamic> clientlist = [];
  ScreenArgument? pageargument;
  File? selectedFile;
  Uint8List? _imageBytes;
  String? _imageName; //// To store the image data

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
        Navigator.pushNamed(context, "/templatelist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
      }
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      pageTitle = AppTranslations.of(context)!.text("key_user");
      sideTitle = AppTranslations.of(context)!.text("key_userdetails");
      usercontroller.getClientList(context, data: {"role":usercontroller.userData.role,"client_id":usercontroller.userData.clientid},
          callback: (res){
            clientlist = res;
            if(pageargument?.mode == "Edit"){
              mode = "Edit";
            }
            setState(() {});
      });

    });
  }



  Widget buttonComp(){
    return Flexible(
        flex:1,
        child: ButtonComp(
            width: double.infinity,
            height: 35,
            label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
          if(formKey.currentState!.saveAndValidate()){

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
                        showButton: true,
                        buttonName: AppTranslations.of(context)!.text("key_download_temp"),
                        callback: (){
                          js.context.callMethod('open', [API_URL+"templateexport?id=s2hgpasn0chndggqv0saht48b6lv25d8dkxulj9u8bgcosomappaiezrnc6kh6kgb8vbh2aqjplh78nk7r8caf3pq2f0bzckhf9ukv3y2g493w288e83preg","_blank"]);
                        },
                        title: AppTranslations.of(context)!.text("key_title_temp"),
                        child: FormBuilder(
                            key: formKey,
                            child: Column(
                              children: [
                                FormBuilderTextField(
                                  name: "templatename",
                                  validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  onChanged: (value){

                                  },
                                  decoration:  InputDecoration(
                                    label: RichText(
                                      text: TextSpan(
                                        text: AppTranslations.of(context)!.text("key_temp_name"),
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
                                FormBuilderDropdown<String>(
                                  name: "client_id",
                                  items: clientlist.map<DropdownMenuItem<String>>((toElement)=>DropdownMenuItem(
                                    value: toElement["clientid"].toString(),
                                    child: Text(toElement["clientname"]),
                                  )).toList(),
                                  validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                  onChanged: (value){
                                    List<dynamic> selectCompany = clientlist.where((element)=>element["clientid"].toString() == value.toString()).toList();


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
                                ),
                                SizedBox(height: defaultPadding,),
                                FormBuilderTextField(
                                  name: "description",
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

                                FormBuilderField(
                                  name: 'file',
                                  validator: (val) {
                                    if (_imageBytes == null) return 'Please select a file';
                                    return null;
                                  },
                                  builder: (FormFieldState<dynamic> field) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width:250,
                                          height: buttonHeight,
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.attach_file),
                                            label: Text(AppTranslations.of(context)!.text("key_upload_temp")),
                                            onPressed: () async {
                                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                              type: FileType.any, // Restrict to image files
                                              allowMultiple: false,
                                              );

                                              if (result != null && result.files.isNotEmpty) {
                                                _imageBytes = result.files.first.bytes; // Image data
                                                _imageName = result.files.first.name;
                                                setState(() {

                                                });

                                              }
                                            },
                                          ),
                                        ),
                                        if (_imageBytes != null) ...[
                                          SizedBox(height: 10),
                                          Text('Selected File: ${_imageName}'),
                                        ],
                                        if (field.errorText != null) ...[
                                          SizedBox(height: 5),
                                          Text(field.errorText!,
                                              style: TextStyle(color: Colors.red)),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: defaultPadding,),
                                ButtonComp(
                                    width: double.infinity,
                                    height: buttonHeight,
                                    label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
                                  if(formKey.currentState!.saveAndValidate()){
                                    var dataObj = {
                                      "templatename":formKey.currentState!.value["templatename"],
                                      "description":formKey.currentState!.value["description"],
                                      "client_id":formKey.currentState!.value["client_id"],
                                      "assigned_user":usercontroller.userData.userId
                                    };
                                    usercontroller.uploadTemplate(context,bytes: _imageBytes, filename: _imageName ?? "", data: dataObj, callback:(res01){
                                      Navigator.pushNamed(context, "/templatelist",arguments: pageargument);
                                      setState(() {

                                      });
                                    });
                                  }
                                })

                              ],
                            )
                        ),
                    )
                ),


              ],
            ),
          ),
        )
    );
  }
}
