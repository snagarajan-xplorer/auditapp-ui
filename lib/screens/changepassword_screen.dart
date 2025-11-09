import 'package:audit_app/constants.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../controllers/menu_app_controller.dart';
import '../controllers/usercontroller.dart';
import '../widget/input.dart';
class ChangepasswordScreen extends StatefulWidget {
  const ChangepasswordScreen({super.key});

  @override
  State<ChangepasswordScreen> createState() => _ChangepasswordScreenState();
}

class _ChangepasswordScreenState extends State<ChangepasswordScreen> {
  UserController usercontroller = Get.put(UserController());
  GlobalKey<FormState> formKey3 = GlobalKey<FormState>();
  bool showPassword = false;
  bool showConfirmPassword = false;
  String confirmpassword = "";
  String password = "";
  bool btnEnabled = false;
  String msg = "";
  String? token = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 100))
    .then((onValue){
      token = Get.parameters['token'];

      usercontroller.checkCorrectToken(context, data: {"token":token}, callback: (data){
        if(data.containsKey("type")) {
          btnEnabled = false;
          msg = data["message"];
        }else{
          btnEnabled = true;
        }
        setState(() {

        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // Set to true if you want the system to handle back navigation
        onPopInvokedWithResult: (didPop,data) {
          if (didPop) return; // If already popped, do nothing

          // Custom back navigation logic (e.g., showing a confirmation dialog)
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppTranslations.of(context)!.text("key_message_02")),
              content: Text(AppTranslations.of(context)!.text("key_message_03")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Close dialog
                  child: Text(AppTranslations.of(context)!.text("key_btn_cancel")),
                ),

              ],
            ),
          );
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: BoxContainer(
                  width: 400,
                  height:520,
                  child: Form(
                    key: formKey3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image(image: AssetImage("assets/images/logo.png")),
                        SizedBox(height: defaultPadding,),
                        Text(AppTranslations.of(context)!.text("key_message_11"),style: headingTextStyle,),
                        SizedBox(height: defaultPadding,),
                        btnEnabled ? Column(
                          children: [
                            Input(
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                              ]),
                              borderColor: Colors.white60,
                              prefixIcon: Icon(CupertinoIcons.lock),
                              suffixIcon: InkWell(
                                onTap: (){
                                  if(showPassword){
                                    showPassword = false;
                                  }else {
                                    showPassword = true;
                                  }
                                  setState(() {

                                  });
                                  print(showPassword);
                                },
                                child: Icon(showPassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                              ),
                              isPassword:showPassword == false ? true : false ,
                              placeholder: AppTranslations.of(context)!.text("key_password"),onTap: (){},onChanged: (str){
                              password = str;
                              setState(() {});
                            },),
                            SizedBox(height: defaultPadding,),
                            Input(
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                              ]),
                              borderColor: Colors.white60,
                              prefixIcon: Icon(CupertinoIcons.lock),
                              suffixIcon: InkWell(
                                onTap: (){
                                  if(showConfirmPassword){
                                    showConfirmPassword = false;
                                  }else {
                                    showConfirmPassword = true;
                                  }
                                  setState(() {

                                  });

                                },
                                child: Icon(showConfirmPassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                              ),
                              isPassword:showConfirmPassword == false ? true : false ,
                              placeholder: AppTranslations.of(context)!.text("key_confirmpassword"),onTap: (){},onChanged: (str){
                              confirmpassword = str;
                              setState(() {});
                            },),
                            SizedBox(height: defaultPadding,),
                            ButtonComp(width:double.infinity,height:buttonHeight,label: AppTranslations.of(context)!.text("key_btn_proceed"),icon: Icon(CupertinoIcons.nosign), onPressed:(){
                              if(formKey3.currentState!.validate()){
                                if(password != confirmpassword){
                                  APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_error_07"),callback: (){

                                  });
                                  return;
                                }
                                var obj = {
                                  "token":token,
                                  "password":password,
                                  "confirmpassword":confirmpassword
                                };
                                usercontroller.changePassword(context, data: obj, callback:(){
                                  Navigator.popAndPushNamed(context, "/dashboard");
                                });
                              }

                            })
                          ],
                        ): Text(msg,style: headTextStyle,)
                      ],
                    ),
                  )
              ),
            ),
          ),
        )
    );
  }
}
