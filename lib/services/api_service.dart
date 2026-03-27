import 'dart:async';
import 'package:audit_app/responsive.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import '../controllers/usercontroller.dart';
import './../constants.dart';

import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import '../localization/app_translations.dart';

class APIService {
  BuildContext context;
  APIService(this.context);
  UserController usercontroller = Get.put(UserController());

  void showWindowAlert({String? title,
    String? desc,
    Widget? child,
    VoidCallback? callback,
    VoidCallback? cancelcallback,
    bool? allowClosePopup = true,
    bool? showCancelBtn = false,
    bool? hideTitle = false,
    Color? okButtonColor,
    String? okbutton,
    String? cancelbutton}){
    List<Widget> buttons = [];
    if (title!.isEmpty) {
      title = AppTranslations.of(context)!.text("key_info").capitalize;
    }
    ButtonComp btn1 = ButtonComp(color: okButtonColor ?? Color(0xFF0376d8), width:90,label: okbutton ?? AppTranslations.of(context)!.text("key_btn_yes").toUpperCase(),
      onPressed: () {
        if(allowClosePopup!){
          Navigator.pop(context);
        }

        if (callback != null) {
          callback();
        }
      },);
    buttons.add(btn1);
    if (showCancelBtn!) {
      ButtonComp btn2 = ButtonComp(color:Color(0xFF002651),width:90,label: cancelbutton ?? AppTranslations.of(context)!.text("key_btn_no").toUpperCase(),
        onPressed: () {
          Navigator.pop(context);
          if (cancelcallback != null) {
            cancelcallback();
          }
        },);

      buttons.add(btn2);
    }
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: hideTitle == true ? null : Text(title ?? "",style: headTextStyle,),
          content: SizedBox(
            width: Responsive.isMobile(context)?350:500,
            child: child ?? Text(desc ?? "",style: paragraphTextStyle,),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: buttons,
        );
      },
    );
  }
  void showWindowContentAlert({
    Widget? child,
    String? title,
    bool? allowClosePopup = true}){


    showDialog(
      barrierDismissible: false,
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title ?? "",style: headingTextStyle,),
          content: SizedBox(
            width: Responsive.isMobile(context)?350:500,
            child: child,
          ),
          actions: [],
        );
      },
    );
  }
  void loaderShow() {
    // Check if widget is mounted and build is complete
    try {
      OverlayLoadingProgress.start(context,
          barrierDismissible: false,
          widget: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0), color: bgColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset('assets/animation/loader.json',
                    width: 80, height: 80),
              ],
            ),
          ));
    } catch (e) {
      // Silently fail if overlay cannot be shown (e.g., during build)
      debugPrint("Warning: Cannot show loader overlay: $e");
    }
  }

  void loaderHide() {
    OverlayLoadingProgress.stop();
  }
  void showToastMgs(message) {
    debugPrint(message.toString());
    //showToast(message,context:context,position: StyledToastPosition.center);
    // Fluttertoast.showToast(
    //     msg: message,
    //     toastLength: Toast.LENGTH_LONG,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.black,
    //     textColor: Colors.white,
    //     fontSize: 16.0);
  }


  Future<String> getData(dynamic url, bool token,
      {bool loader = true, bool? showError = true}) async {
    try {
      if (loader) {
        loaderShow();
      }

      var durl = API_URL+url;

      var header = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Channel': "M"
      };
      String mtoken = usercontroller.userData.token ?? "";
      if (token) {
        header = <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Channel': "M",
          'Authorization': 'Bearer $mtoken'
        };
      }

      final response = (await http.get(Uri.parse(durl), headers: header));
      if (response.statusCode == 200) {
        if (loader) {
          OverlayLoadingProgress.stop();
        }
        return utf8.decode(response.bodyBytes);
        //return response.body;
      } else {
        dynamic res = JsonDecoder().convert(response.body);
        dynamic mapdata = {};
        mapdata["type"] = "error";
        mapdata["status"] = response.statusCode;
        if(res.containsKey("message")){
          showToastMgs(res["message"]);
          mapdata["message"] = res["message"];
        }
        if (loader) {
          OverlayLoadingProgress.stop();
        }
        switch (response.statusCode) {
          case 502:

            break;
          default:
            if (showError!) {

            }

            break;
        }
        return jsonEncode(mapdata);

        // Map<String,dynamic> res = JsonDecoder().convert(response.body);
        // if(res["responseBody"] != null){
        //   debugPrint(res["responseBody"].runtimeType);
        //   if((res["responseBody"].runtimeType) == String){
        //     showToast(res["responseBody"]);
        //     //Toast.show(res["responseBody"]['errorMessage'], duration: Toast.lengthLong, gravity:  Toast.center);
        //   }else{
        //     showToast(res["responseBody"]['errorMessage']);
        //   }
        // }
        //return response.body;
      }

    } on TimeoutException {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("Request timeout. Please try again.");
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = 0;
      mapdata["message"] = "Request timeout";
      return jsonEncode(mapdata);
    } on http.ClientException catch (e) {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("Cannot connect to server. Please check if backend is running on port 8000.");
      debugPrint("ClientException: ${e.message} - ${e.uri}");
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = 0;
      mapdata["message"] = "Connection refused. Backend server not reachable.";
      return jsonEncode(mapdata);
    } catch (e) {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("An error occurred: ${e.toString()}");
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = 0;
      mapdata["message"] = e.toString();
      return jsonEncode(mapdata);
    }
  }

  Future<String?> uploadFiles(filename,dynamic bytes, String url, Map<String, dynamic> data, {String fileKey = "file"}) async {
    loaderShow();
    var durl = API_URL+url;

    String mtoken = usercontroller.userData.token ?? "";
    var header = <String, String>{
      'Content-Type': 'application/octet-stream; charset=UTF-8',
      'Channel': "M",
      'Authorization': 'Bearer $mtoken'
    };
    var request = http.MultipartRequest('POST', Uri.parse(durl));
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      } else {
        request.fields[key] = "";
      }
    });
    request.files.add(http.MultipartFile.fromBytes(fileKey,bytes,filename: filename,));

    request.headers.addAll(header);
    //var res = await request.send();
    http.StreamedResponse response = await request.send();
    // response.stream.transform(utf8.decoder).listen((value) {
    //   debugPrint(value);
    // });

    if (response.statusCode == 200) {
      loaderHide();
      return (await response.stream.bytesToString());
    } else {
      loaderHide();
      return "error";
    }
  }
  Future<String?> uploadExcelFiles(filename,dynamic bytes, String url, Map<String, dynamic> data, {String fileKey = "file",bool showMsg = true,}) async {
    loaderShow();
    var durl = API_URL+url;

    String mtoken = usercontroller.userData.token ?? "";
    var header = <String, String>{
      'Content-Type': 'application/octet-stream; charset=UTF-8',
      'Channel': "M",
      'Authorization': 'Bearer $mtoken'
    };
    var request = http.MultipartRequest('POST', Uri.parse(durl));
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      } else {
        request.fields[key] = "";
      }
    });
    request.files.add(http.MultipartFile.fromBytes(fileKey,bytes,filename: filename,));

    request.headers.addAll(header);
    //var res = await request.send();
    http.StreamedResponse response = await request.send();
    // response.stream.transform(utf8.decoder).listen((value) {
    //   debugPrint(value);
    // });

    if (response.statusCode == 200) {
      loaderHide();
      return (await response.stream.bytesToString());
    } else {
      loaderHide();
      dynamic res = JsonDecoder().convert(await response.stream.bytesToString());
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = response.statusCode;

      if(res.containsKey("message")){
        if(showMsg){
          showToastMgs(res["message"]);
        }
        mapdata["message"] = res["message"];
      }
      switch (response.statusCode) {
        case 502:

          break;
        default:

          break;
      }
      debugPrint(mapdata.toString());
      return jsonEncode(mapdata);
    }
  }

  Future<String> postData(String url, dynamic data, bool token,
      {bool isJSON = false,
      bool loader = true,
        bool showMsg = true,
      bool? showError = true}) async {
    try {

      if (loader) {
        loaderShow();
      }
      var durl = API_URL+url;
      String mtoken = usercontroller.userData.token ?? "";

      String channel = "M";
      if (url.contains("generateCustomerLoginOtp")) {
        channel = "C";
      }
      var header = <String, String>{
        'Content-Type': 'application/json',
        'Channel': channel
      };

      if (token) {
        header = <String, String>{
          'Content-Type': 'application/json',
          'Channel': channel,
          'Authorization': 'Bearer $mtoken'
        };
      }
      var encoder = JsonEncoder.withIndent("  ");
      var datastr = encoder.convert(data);
      debugPrint(datastr);
      final response = await http.post(Uri.parse(durl),
          headers: header, body: isJSON == false ? datastr : data);

      // http.post(Uri.parse(durl),
      //         headers: header,
      //         body:jsonEncode(data)
      //     )
      // .timeout(const Duration(seconds: 2))
      // .then((value){
      //   if(loader){
      //     OverlayLoadingProgress.stop();
      //   }
      //   response = value;
      // });
      debugPrint(response.statusCode.toString());
      if (response.statusCode == 200) {
        if (loader) {
          OverlayLoadingProgress.stop();
        }
        return utf8.decode(response.bodyBytes);
      } else {
        if (loader) {
          OverlayLoadingProgress.stop();
        }
        dynamic res = JsonDecoder().convert(response.body);
        dynamic mapdata = {};
        mapdata["type"] = "error";
        mapdata["status"] = response.statusCode;

        if(res.containsKey("message")){
          if(showMsg){
            showToastMgs(res["message"]);
          }
          mapdata["message"] = res["message"];
        }
        switch (response.statusCode) {
          case 502:

            break;
          default:
            if (showError!) {


            }
            break;
        }
        debugPrint(mapdata.toString());
        return jsonEncode(mapdata);

        // dynamic res = JsonDecoder().convert(response.body);
        // if(res["responseBody"] != null){
        //   debugPrint(res["responseBody"].runtimeType);
        //   if((res["responseBody"].runtimeType) == String){
        //     showToast(res["responseBody"]);
        //     //Toast.show(res["responseBody"]['errorMessage'], duration: Toast.lengthLong, gravity:  Toast.center);
        //   }else{
        //     showToast(res["responseBody"]['errorMessage']);
        //   }
        // }
        // if(res["error"] != null){
        //   showToast(res["error"]);
        //   //Toast.show(res["responseBody"], duration: Toast.lengthLong, gravity:  Toast.center);
        // }
      }


    } on TimeoutException {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("Request timeout. Please try again.");
      rethrow;
    } on http.ClientException catch (e) {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("Cannot connect to server. Please check if backend is running on port 8000.");
      debugPrint("ClientException: ${e.message} - ${e.uri}");
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = 0;
      mapdata["message"] = "Connection refused. Backend server not reachable.";
      return jsonEncode(mapdata);
    } catch (e) {
      if (loader) {
        OverlayLoadingProgress.stop();
      }
      showToastMgs("Please check your internet");
      dynamic mapdata = {};
      mapdata["type"] = "error";
      mapdata["status"] = 0;
      mapdata["message"] = "Network error: ${e.toString()}";
      return jsonEncode(mapdata);
    }
  }
}
