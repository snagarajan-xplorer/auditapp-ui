
import 'dart:convert';
import 'package:audit_app/constants.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/wavebackgroundanimation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../controllers/menu_app_controller.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../widget/input.dart';
import '../widget/staranimation.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  UserController usercontroller = Get.put(UserController());
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  GlobalKey<FormState> passwordKey = GlobalKey<FormState>();
  bool showPassword = false;
  String username = "";
  String email = "";
  String password = "";
  int startYear = 2025;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 100))
    .then((onValue){
      String filename = "assets/json/states.json";
      if(kIsWeb){
        filename = "json/states.json";
      }
      usercontroller.year = [];
      int y = Jiffy.now().year;
      if(y == startYear){
        usercontroller.year.add(y.toString());
      }else{
        if(y > startYear){
          for(int id = y;id > startYear;id--){
            usercontroller.year.add(id.toString());
          }
        }
      }

      UtilityService().parseJsonFromAssets(filename)
          .then((res){
        Map<String,dynamic> obj = jsonDecode(res);
        usercontroller.geoJsonParser.parseGeoJsonAsString(res);
      });
    });
  }
  Widget mainComp(){
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: BoxContainer(
              width: 400,
              height:430,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image(image: AssetImage("assets/images/logo.png")),
                    SizedBox(height: defaultPadding,),
                    SizedBox(
                      width: 320,
                      child: Input(
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                          // FormBuilderValidators.email(
                          //     errorText: AppTranslations.of(context)!.text("key_error_02") ?? "")
                        ]),
                        prefixIcon: Icon(CupertinoIcons.person),
                        borderColor: Colors.white60,
                        autofocus: false,
                        placeholder: AppTranslations.of(context)!.text("key_username"),onTap: (){},onChanged: (str){
                        username = str;
                        setState(() {});
                      },),
                    ),
                    SizedBox(height: defaultPadding,),
                    SizedBox(
                      width: 320,
                      child: Input(
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                        ]),
                        borderColor: Colors.white60,
                        autofocus: false,
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
                    ),
                    SizedBox(height: defaultPadding,),
                    SizedBox(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(child: Text(AppTranslations.of(context)!.text("key_forgotpassword")),onTap: (){
                          APIService(context).showWindowAlert(
                              allowClosePopup: false,
                              showCancelBtn: true,
                              cancelbutton: AppTranslations.of(context)!.text("key_btn_cancel"),

                              title:AppTranslations.of(context)!.text("key_forgotpassword"),
                              callback: (){
                                if(passwordKey.currentState!.validate()){
                                  usercontroller.forgotPassword(context, data: {"email":email}, callback: (res){
                                    if(res.containsKey("message")){
                                      APIService(context).showToastMgs(res["message"]);
                                      Navigator.pop(context);
                                    }
                                  });
                                }
                              },
                              child: Container(
                                height: 140,
                                child: Form(
                                  key: passwordKey,
                                  child: Column(
                                    children: [
                                      SizedBox(height: defaultPadding,),
                                      Input(
                                        validator: FormBuilderValidators.compose([
                                          FormBuilderValidators.required(
                                              errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),

                                        ]),
                                        prefixIcon: Icon(CupertinoIcons.person),
                                        borderColor: Colors.white60,
                                        placeholder: AppTranslations.of(context)!.text("key_username"),onTap: (){},onChanged: (str){
                                        email = str;
                                        setState(() {});
                                      },),
                                      SizedBox(height: defaultPadding,),
                                    ],
                                  ),
                                ),
                              ),
                              okbutton: AppTranslations.of(context)!.text("key_btn_proceed"));
                        },),
                      ),
                    ),
                    SizedBox(height: defaultPadding,),
                    SizedBox(
                      width: 320,
                      child: ButtonComp(width:double.infinity,height:buttonHeight,label: AppTranslations.of(context)!.text("key_login"), onPressed:(){
                        if(formKey.currentState!.validate()){
                          var obj = {
                            "email":username,
                            "password":password
                          };
                          usercontroller.login(context, data: obj, callback:(){
                            if(Responsive.isDesktop(context)){
                              if(usercontroller.userData.changepass == "N"){
                                Get.offNamed("/changepassword/"+usercontroller.userData.mvalue.toString()!);
                              }else{
                                Get.offNamed("/dashboard");
                              }
                            }else if(Responsive.isMobile(context)){
                              if(["CL","JrA"].indexOf(usercontroller.userData.role!) != -1){
                                if(usercontroller.userData.changepass == "N"){
                                  Get.offNamed("/changepassword/"+usercontroller.userData.mvalue.toString()!);
                                }else{
                                  Get.offNamed("/dashboard");
                                }
                              }else{
                                APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_21"),callback: (){});
                              }
                            }


                          }, onFail: (String str) {
                            APIService(context).showWindowAlert(title: "",desc: str,callback: (){});
                          });
                        }

                      }),
                    )
                  ],
                ),
              )
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // Set to true if you want the system to handle back navigation
        onPopInvokedWithResult: (didPop,data) {
          if (didPop) return; // If already popped, do nothing
          APIService(context).showWindowAlert(title:AppTranslations.of(context)!.text("key_message_02"),desc:AppTranslations.of(context)!.text("key_message_03"),callback: (){});
          // Custom back navigation logic (e.g., showing a confirmation dialog)
        },
        child:Stack(
          children: [
            CirclesAnimation(),
            mainComp()
          ],
        )
    );
  }
}

