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

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<DataRow> row = [];
  List<DataColumn> column = [];
  List<dynamic> userdata = [];
  String imagePath = "";
  String pageTitle = "";
  String sideTitle = "";
  bool loadData = false;
  ScreenArgument? pageargument;
  List<Map<String,dynamic>> userArr = [];
  List<Map<String,dynamic>> dataObj = [
    {
      "lable":"Name",
      "key":"name",
      "type":"string",
      "value":""
    },
    {
      "lable":"Email",
      "key":"email",
      "type":"string",
      "value":""
    },
    {
      "lable":"Mobile",
      "key":"mobile",
      "type":"string",
      "value":""
    },
    {
      "lable":"City",
      "key":"city",
      "type":"string",
      "value":""
    },
    {
      "lable":"State",
      "key":"state",
      "type":"string",
      "value":""
    },
    {
      "lable":"Role",
      "key":"rolename",
      "type":"string",
      "value":""
    },
    {
      "lable":"Status",
      "key":"statusvalue",
      "type":"string",
      "value":""
    },
    {
      "lable":"Action",
      "key":"",
      "type":"button",
      "value":""
    }
  ];
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
      loadData = true;
      setState(() {

      });
      if(pageargument?.argument == ArgumentData.USER){
        pageTitle = AppTranslations.of(context)!.text("key_user");
        sideTitle = AppTranslations.of(context)!.text("key_userdetails");
      }else if(pageargument?.argument == ArgumentData.CLIENT){
        role = "CL";
        pageTitle = AppTranslations.of(context)!.text("key_client");
        sideTitle = AppTranslations.of(context)!.text("key_clientdetails");
      }
      usercontroller.getUserList(context,data:{"role": role,"status":"ALL","client":usercontroller.userData.clientid,"userRole":usercontroller.userData.role}, callback:(res){
        userArr = [];
        usercontroller.userlist = res;
        if(pageargument?.argument == ArgumentData.USER){
          dataObj = [
            {
              "lable":"Name",
              "key":"name",
              "type":"string",
              "value":""
            },
            {
              "lable":"Email",
              "key":"email",
              "type":"string",
              "value":""
            },
            {
              "lable":"Mobile",
              "key":"mobile",
              "type":"string",
              "value":""
            },
            {
              "lable":"City",
              "key":"city",
              "type":"string",
              "value":""
            },
            {
              "lable":"State",
              "key":"state",
              "type":"string",
              "value":""
            },
            {
              "lable":"Role",
              "key":"rolename",
              "type":"string",
              "value":""
            },
            {
              "lable":"Status",
              "key":"statusvalue",
              "type":"string",
              "value":""
            },
            {
              "lable":"Action",
              "key":"",
              "type":"button",
              "value":""
            }
          ];
        }else if(pageargument?.argument == ArgumentData.CLIENT){
          dataObj = [
            {
              "lable":"Company Name",
              "key":"companyname",
              "type":"string",
              "value":""
            },
            {
              "lable":"Name",
              "key":"name",
              "type":"string",
              "value":""
            },
            {
              "lable":"Email",
              "key":"email",
              "type":"string",
              "value":""
            },
            {
              "lable":"Mobile",
              "key":"mobile",
              "type":"string",
              "value":""
            },
            {
              "lable":"Status",
              "key":"statusvalue",
              "type":"string",
              "value":""
            },
            {
              "lable":"Action",
              "key":"",
              "type":"button",
              "value":""
            }
          ];
        }

        usercontroller.userlist.forEach((element){
          element["statusvalue"] = element["status"] == "A" ? "Active" : "Inactive";
          if(pageargument?.argument == ArgumentData.USER && ["CL","SA"].indexOf(element["role"].toString()) == -1){
            userArr.add(Map.of(element));
          }else if(pageargument?.argument == ArgumentData.CLIENT && element["role"] == "CL"){
            userArr.add(Map.of(element));
          }

        });

      setState(() {});

      });
    });
  }
  Widget _buildChild(obj){
    return ListTile(
      title: Text(obj["name"]),
      subtitle: Row(
        children: [
          Text(obj["email"]),
          SizedBox(width: 5,),
          Text(obj["rolename"]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: loadData == false ? SizedBox() : PageContainerComp(
                isBGTransparent: true,
                padding: 0,
                title:pageTitle,
                showTitle: true,
                showButton: menuAccessRole.indexOf(usercontroller.userData.role!) != -1?true:false,
                callback: (){
                  String filename = "assets/json/user.json";
                  if(kIsWeb){
                    filename = "json/user.json";
                  }
                  usercontroller.getStaticForm(context,type: pageargument?.argument ?? ArgumentData.USER, url: filename, callback: (){
                    ScreenArgument editargu = ScreenArgument(argument:pageargument?.argument,mapData: pageargument?.mapData,mode: "Add",editData: {});
                    Navigator.pushNamed(context, "/adddata",arguments: pageargument);
                  });
                },
                child: userArr.length == 0 ? Container() : DataTableContainer(
                  dataArr: userArr, fieldArr: dataObj,
                  pageType: "user",
                  onChanged: (str){

                  },
                  callback: (data){
                    print("data ${data}");
                    String filename = "assets/json/user.json";
                    if(kIsWeb){
                      filename = "json/user.json";
                    }
                    if(pageargument?.argument == ArgumentData.USER){
                      data["joiningdate"] = Jiffy.parse(data["joiningdate"]).dateTime;
                    }else if(pageargument?.argument == ArgumentData.CLIENT){
                      data["client"] = data["client"].toString();
                    }
                    ScreenArgument editargu = ScreenArgument(argument:pageargument?.argument,mapData: pageargument?.mapData,mode: "Edit",editData: data);
                    usercontroller.getStaticForm(context,type: pageargument?.argument ?? ArgumentData.USER, url: filename, callback: (){
                      Navigator.pushNamed(context, "/adddata",arguments: editargu);
                    });
                  },
                ),
               ),
          ),
        )
    );
  }
}
