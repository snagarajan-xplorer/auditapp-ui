import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jiffy/jiffy.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../services/LocalStorage.dart';
import 'main/layoutscreen.dart';

class Templatelistscreen extends StatefulWidget {
  const Templatelistscreen({super.key});

  @override
  State<Templatelistscreen> createState() => _TemplatelistscreenState();
}

class _TemplatelistscreenState extends State<Templatelistscreen> {
  List<DataRow> row = [];
  List<DataColumn> column = [];
  List<dynamic> userdata = [];
  String imagePath = "";
  String pageTitle = "";
  String sideTitle = "";
  ScreenArgument? pageargument;
  List<Map<String,dynamic>> templateArr = [];
  List<Map<String,dynamic>> dataObj = [
    {
      "lable":"Template Name",
      "key":"templatename",
      "type":"string",
      "value":""
    },
    {
      "lable":"Client Name",
      "key":"clientname",
      "type":"string",
      "value":""
    },
    {
      "lable":"Description",
      "key":"description",
      "type":"string",
      "value":""
    },
    {
      "lable":"Date",
      "key":"created_at",
      "type":"string",
      "value":""
    },
    {
      "lable":"Status",
      "key":"statusvalue",
      "type":"string",
      "value":""
    },

  ];
  // {
  // "lable":"Action",
  // "key":"",
  // "type":"button",
  // "value":""
  // }
  GlobalKey<FormBuilderState> form = GlobalKey<FormBuilderState>();
  UserController usercontroller = Get.put(UserController());



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(usercontroller.userData.role == null){
      usercontroller.loadInitData();
    }
    Future.delayed(Duration(milliseconds: 200))
        .then((onValue) async {
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument? ?? ScreenArgument();
      print("pageargument?.argument ${pageargument?.argument}");
      if(pageargument?.argument  != null){
        await LocalStorage.setStringData("arguments",pageargument?.argument == ArgumentData.USER ? "User" : "Client");
      }else{
        String? str = await LocalStorage.getStringData("arguments");
        pageargument =  ScreenArgument(argument: str == "User" ? ArgumentData.USER : ArgumentData.CLIENT,mapData: {});
      }
      String role = "ALL";
      pageTitle = AppTranslations.of(context)!.text("key_title_temp");
      sideTitle = AppTranslations.of(context)!.text("key_userdetails");
      usercontroller.getAllTemplateList(context,  callback:(res){
        templateArr = [];
        res.forEach((element){
          element["statusvalue"] = element["status"] == "A" ? "Active" : "Inactive";
          element["created_at"] = Jiffy.parseFromDateTime(DateTime.parse(element["created_at"])).format(pattern: "dd/MM/yyyy");
          templateArr.add(Map.of(element));
        });
        setState(() {});

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: PageContainerComp(
              isBGTransparent: true,
              padding: 0,
              title:pageTitle,
              showTitle: true,
              showButton: menuAccessRole.indexOf(usercontroller.userData.role!) != -1?true:false,
              callback: (){
                ScreenArgument editargu = ScreenArgument(argument:pageargument?.argument,mapData: pageargument?.mapData,mode: "Add",editData: {});
                Navigator.pushNamed(context, "/addtemplate",arguments: pageargument);
              },
              child: templateArr.length == 0 ? Container() : DataTableContainer(
                dataArr: templateArr, fieldArr: dataObj,
                pageType: "template",
                onChanged: (str){
                  print(str);
                },
                callback: (data){
                  ScreenArgument editargu = ScreenArgument(argument:pageargument?.argument,mapData: pageargument?.mapData,mode: "Add",editData: {});
                  Navigator.pushNamed(context, "/addtemplate",arguments: pageargument);
                },
              ),
            ),
          ),
        )
    );
  }
}
