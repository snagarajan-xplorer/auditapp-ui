
import 'dart:async';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:audit_app/constants.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/LocalStorage.dart';
import 'package:flutter/material.dart';
import 'package:audit_app/models/userdata.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:jiffy/jiffy.dart';

import '../models/dynamicfield.dart';
import '../models/my_files.dart';
import '../services/utility.dart';

class UserController extends GetxController{
  UserData userData = UserData();
  int selectedIndex = 0;
  List<DynamicField> formArray = [];
  List<dynamic> role = [];
  List<dynamic> clinetArr = [];
  List<dynamic> userlist = [];
  List<dynamic> categorylist = [];
  List<dynamic> dropdownlist = [];
  List<String> year = [];
  int startYear = 2025;
  List<Map<String,dynamic>> scoreArr = [
    {
      "color":Colors.red,
      "value":"0"
    },
    {
      "color":Colors.orange,
      "value":"1"
    },
    {
      "color":Colors.yellow,
      "value":"2"
    },
    {
      "color":Colors.lightGreen,
      "value":"3"
    },
    {
      "color":Colors.indigo,
      "value":"4"
    },
    {
      "color":Colors.blueGrey,
      "value":"N/A"
    }
  ];
  List<Map<String,dynamic>> scoreArr2 = [
    {
      "color":Colors.red,
      "value":"0"
    },
    {
      "color":Colors.orange,
      "value":"1"
    },
    {
      "color":Colors.lightGreen,
      "value":"2"
    },
    {
      "color":Color(0xFF002651),
      "value":"3"
    },

  ];
  List<Map<String,dynamic>> colorArr = [
    {
      "color":Colors.red,
      "svg":"assets/images/extreme.png",
      "value":"0",
      "svgcolor":Color(0xFFf33f33)
    },
    {
      "color":Colors.red,
      "svg":"assets/images/high.png",
      "value":"1",
      "svgcolor":Color(0xFFf19d38)
    },
    {
      "color":Colors.orange,
      "svg":"assets/images/high.png",
      "value":"2",
      "svgcolor":Color(0xFFf9df41)
    },
    {
      "color":Colors.yellow,
      "svg":"assets/images/medium.png",
      "value":"3",
      "svgcolor":Color(0xFFf9df41)
    },
    {
      "color":Colors.blue,
      "svg":"assets/images/low.png",
      "value":"4",
      "svgcolor":Color(0xFF4994ec)
    }
  ];
  List<CloudStorageInfo> countList = [];
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultPolygonBorderColor: Colors.red,
    defaultPolygonFillColor: Colors.red.withAlpha(10),
    defaultPolylineStroke: 1
  );
  loadInitData() async {
    String? str = await LocalStorage.getStringData("userdata");
    userData = UserData.fromJson(jsonDecode(str!));
    String filename = "assets/json/states.json";
    if(kIsWeb){
      filename = "json/states.json";
    }
    year = [];
    int y = Jiffy.now().year;
    if(y == startYear){
      year.add(y.toString());
    }else{
      if(y > startYear){
        for(int id = y;id > startYear;id--){
          year.add(id.toString());
        }
      }
    }

    UtilityService().parseJsonFromAssets(filename)
        .then((res){
      Map<String,dynamic> obj = jsonDecode(res);
      geoJsonParser.parseGeoJsonAsString(res);
    });
  }

  void login(context,{required Map data,required Function callback,required Function(String) onFail}){
    APIService(context).postData("login", data, false)
        .then((resvalue) async {
          if(resvalue.length != 5){
            Map<String,dynamic> res = jsonDecode(resvalue);
            print("ffdddd ${res}");
            if(!res.containsKey("type")) {
              await LocalStorage.setStringData("userdata",resvalue);
              userData = UserData.fromJson(res);
              callback();
            }else{
              print(res["message"]);
              if(!res.containsKey("message")) {
                onFail(res["message"]);
              }
            }
          }

    });
  }
  void checkCorrectToken(context,{required Map data,required Function(dynamic) callback}){
    APIService(context).postData("checkCorrectToken", data, false)
        .then((resvalue){
      Map<String,dynamic> res = jsonDecode(resvalue);
      callback(res);

    });
  }
  void changePassword(context,{required Map<String,dynamic> data,required Function() callback}){
    APIService(context).postData("changePassword",data, false)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void forgotPassword(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("forgotPassword",data, false)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        print(res);
        if(!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }
  void register(context,{required Map data,required Function(dynamic) callback}){
    APIService(context).postData("register", data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if(res.containsKey("mid")){
            callback(res);
          }
        }

      }
    });
  }
  void uploadImage(context,{required String filename,required dynamic bytes,required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).uploadFiles(filename,bytes,"upload", data)
        .then((resvalue){
      if(resvalue!.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        callback(res);
      }
    });
  }
  void uploadTemplate(context,{required String filename,required dynamic bytes,required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).uploadExcelFiles(filename,bytes,"saveTemplate", data,)
        .then((resvalue){
          print("resvalue ${resvalue}");
      if(resvalue!.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(res.containsKey("message")){
          APIService(context).showToastMgs(res["message"]);
          callback(res);
        }

      }else{
        if(resvalue == "OK"){

          callback({});
        }
      }
    });
  }

  void getUserList(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback}){
    APIService(context).postData("getUserList", data,true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if(res.containsKey("data")){
            callback(res["data"]);
          }
        }

      }
    });
  }

  void getOverAllReport(context,{required Function(Map<String,dynamic>) callback}){
    APIService(context).getData("getOverAllReport", true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if(res.containsKey("data")){
            callback(res);
          }
        }

      }
    });
  }
  void getPinCode(context,{required String pincode,required Function(List<dynamic>) callback}){
    APIService(context).getData("searchPincode?pincode="+pincode, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(res.containsKey("data")) {
          callback(res["data"]);
        }
      }
    });
  }
  void getCategoryList(context,{required Function(List<dynamic>) callback}){
    APIService(context).getData("getCategoryList", true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            categorylist = res["data"];
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getTemplateList(context,{required String clientid,required Function(List<dynamic>) callback}){
    APIService(context).getData("getTemplate?clientid="+clientid, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getAllTemplateList(context,{required Function(List<dynamic>) callback}){
    APIService(context).getData("getAllTemplate", true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getZone(context,{required Function(List<dynamic>) callback}){
    APIService(context).getData("getZone", true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getDropdownList(context,{required Function(dynamic) callback}){
    APIService(context).getData("getDropDownList", true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            dropdownlist = res["data"];
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getAuditList(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback}){
    APIService(context).postData("getAuditList",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getClientUserList(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback,required Function(dynamic) errorcallback}){
    APIService(context).postData("getClientUserList",data, true,showMsg: false)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }else{
          errorcallback(res);
        }
      }
    });
  }
  void sendAuditComments(context,{required Map<String,dynamic> data,required VoidCallback callback,required Function(dynamic) errorcallback}){
    APIService(context).postData("sendAuditComments",data, true,showMsg: false)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }else{
          errorcallback(res);
        }
      }
    });
  }

  void publishUserReport(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("publishUserReport",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void logout(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("logout",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void getClientList(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback}){
    APIService(context).postData("getClientList",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getClientHeatReport(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("getAuditReport",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getAuditCount(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("getAuditSummary",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getCurrentDate(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).getData("getCurrentDateTime",  true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }
  void getAuditRemarks(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback}){
    APIService(context).postData("getRemarks",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void getTempalteStatus(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("templateStatus",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }
  void getUserStatus(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("userStatus",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }
  void saveAuditBranch(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("saveAuditBranch",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void removeUploadFile(context,{required Map<String,dynamic> data,required Function(List<dynamic>) callback}){
    APIService(context).postData("removeUploadFile",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void publishAuditStatus(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("publishAuditStatus",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void saveAuditAcknowledge(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("saveAuditAcknowledge",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void saveAuditQuestion(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("saveAuditQuestion",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void getAuditQuestion(context,{required Map<String,dynamic> data,required Function(dynamic) callback}){
    APIService(context).postData("getAuditQuestion",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }
  void saveAudit(context,{required Map<String,dynamic> data,required VoidCallback callback}){
    APIService(context).postData("saveAudit",data, true)
        .then((resvalue){
      if(resvalue.length != 5){
        Map<String,dynamic> res = jsonDecode(resvalue);
        if(!res.containsKey("type")) {
          callback();
        }
      }
    });
  }
  void getStaticForm(context,
      {required String url,
        required ArgumentData type,
        required VoidCallback callback}) {
    APIService(context).loaderShow();
    UtilityService().parseJsonFromAssets(url).then((value2) async {
      var res2 = JsonDecoder().convert(value2);
      formArray = [];

      res2.forEach((element) {
        DynamicField obj = DynamicField.fromJson(element);
        obj.isPassword = false;
        obj.showMic = false;
        obj.isCurrency = false;
        obj.disabledYN = obj.disabledYN == null ? "N" : obj.disabledYN;
        obj.enableTime = false;
        obj.fieldValue = "";
        obj.selectedValue = "";
        obj.currencyValue = "";
        obj.isMobile = false;
        obj.maxDate = DateTime.now();
        obj.minDate = Jiffy.now().subtract(years: 30).dateTime;
         if (obj.fieldName == "mobile") {
          obj.isMobile = true;
          obj.maxLen = 10;
        }else if (obj.fieldName == "pincode") {
          obj.maxLen = 6;
        } else if (obj.fieldName.toString().toLowerCase().contains("name")) {
          obj.caseType = "U";
        }
        if(type == ArgumentData.CLIENT){
          if (["parentid","role","joiningdate","pincode","state","zone","city","address","district","companyname"].indexOf(obj.fieldName!) == -1) {
            obj.visibility = "Y";
            if(obj.fieldName == "client"){
              obj.fieldDisplayOrder = 0;
              obj.fieldType = "Select";
            }
            formArray.add(obj);
          }
        }else{
          if (["companyname"].indexOf(obj.fieldName!) == -1) {
            if(obj.fieldName == "client"){
              obj.fieldDisplayOrder = 10;
              obj.fieldType = "CheckBoxGroup";
            }
            formArray.add(obj);
          }
        }

      });
      APIService(context).getData("role", true)
      .then((resvalue){
        if(resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              role = res["data"];
              List<DynamicField> rolefield = formArray.where((
                  element) => element.fieldName == "role").toList();
              if (rolefield.length != 0) {
                rolefield[0].options =
                    role.map<DropdownMenuItem<String>>((toElement) =>
                        DropdownMenuItem(
                          value: toElement[rolefield[0].optkey.toString()],
                          child: Text(toElement[rolefield[0].optvalue
                              .toString()]),
                        )).toList();
              }
              getClientList(context,
                  data: {"role": userData.role, "client_id": userData.clientid},
                  callback: (mapdata) {
                    clinetArr = mapdata;
                    List<DynamicField> rolefield = formArray.where((
                        element) => element.fieldName == "client").toList();
                    List<DynamicField> clientfield = formArray.where((
                        element) => element.fieldName == "client_data").toList();
                    if (rolefield.length != 0) {
                      rolefield[0].lovData = mapdata;
                      rolefield[0].options = mapdata.map<DropdownMenuItem<
                          String>>((toElement) =>
                          DropdownMenuItem(
                            value: toElement["clientid"].toString(),
                            child: Text(toElement["clientname"]),
                          )).toList();
                    }
                    if (clientfield.length != 0) {
                      clientfield[0].lovData = mapdata;
                      clientfield[0].options = mapdata.map<DropdownMenuItem<
                          String>>((toElement) =>
                          DropdownMenuItem(
                            value: toElement["clientid"].toString(),
                            child: Text(toElement["clientname"]),
                          )).toList();
                    }
                    Future.delayed(Duration(milliseconds: 100)).then((value) {
                      APIService(context).loaderHide();
                      callback();
                    });
                  });
            }
          }
        }
      });
    });
  }

}