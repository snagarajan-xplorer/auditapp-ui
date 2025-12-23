
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'selectionobj.dart';
import 'selected_list_item.dart';
import 'package:flutter/services.dart';



class DynamicField {
  int? fieldInfoId;
  String? lobCode;
  String? lobName;
  String? lobNameBl1;
  String? prodCode;
  String? prodName;
  dynamic? prodNameBl1;
  String? blockCategory;
  String? blockName;
  bool? showMic;
  bool? showHint;
  String? hintMsg;
  String? blockNameBl1;
  int? blockOrder;
  String? fieldName;
  dynamic? minLimit;
  dynamic? maxLimit;
  int? maxLen;
  bool? isMobile;
  bool? allowPaste;
  dynamic? keystate;
  String? labelName;
  String? labelNameBl1;
  dynamic? premiaColumnName;
  int? fieldDisplayOrder;
  dynamic? blockId;
  String? fieldType;
  String? dataType;
  dynamic? serviceName;
  Map<String,dynamic>? requestObj;
  String? visibility;
  String? mandatory;
  bool? isPassword;
  bool? allowSpecialCharactor;
  dynamic? defaultYN;
  dynamic? disabledYN;
  dynamic? minDate;
  dynamic? maxDate;
  dynamic? errorObj;
  int? minLength;
  int? maxLength;
  int? exactLength;
  String? applicableChannel;
  String? applicableTo;
  String? optkey;
  String? optvalue;
  String? caseType;
  String? widgetType;
  dynamic? eventName;
  dynamic? calendarStartView;
  List<Rules>? rules;
  List<Rules>? backupRules;
  List<TextInputFormatter>? inputFormatters;
  TextInputType? textInputType;
  List<DropdownMenuItem<String>>? options;
  List<dynamic>? lovData;
  FormFieldValidator? validator;
  dynamic? fieldValue;
  dynamic? selectedValue;
  dynamic? currencyValue;
  bool? enableTime;
  bool? isCurrency;

  DynamicField(
      {this.fieldInfoId,
        this.lobCode,
        this.lobName,
        this.lobNameBl1,
        this.prodCode,
        this.caseType,
        this.prodName,
        this.requestObj,
        this.widgetType,
        this.lovData ,
        this.optkey,
        this.optvalue,
        this.showMic = false,
        this.prodNameBl1,
        this.blockCategory,
        this.blockName,
        this.showHint = false,
        this.hintMsg = "",
        this.blockNameBl1,
        this.blockOrder,
        this.backupRules,
        this.fieldName,
        this.labelName,
        this.labelNameBl1,
        this.premiaColumnName,
        this.fieldDisplayOrder,
        this.blockId,
        this.errorObj,
        this.fieldType,
        this.dataType,
        this.minLimit,
        this.maxLimit,
        this.allowPaste,
        this.serviceName,
        this.visibility,
        this.mandatory,
        this.defaultYN,
        this.disabledYN,
        this.minDate,
        this.maxDate,
        this.minLength,
        this.maxLength,
        this.exactLength,
        this.applicableChannel,
        this.applicableTo,
        this.eventName,
        this.calendarStartView,
        this.fieldValue,
        this.isPassword = false,
        this.enableTime = false,
        this.isCurrency,
        this.isMobile,
        this.rules});

  DynamicField.fromJson(Map<String, dynamic> json) {
    fieldInfoId = json['fieldInfoId'];
    lobCode = json['lobCode'];
    lobName = json['lobName'];
    lobNameBl1 = json['lobNameBl1'];
    prodCode = json['prodCode'];
    prodName = json['prodName'];
    prodNameBl1 = json['prodNameBl1'];
    blockCategory = json['blockCategory'];
    caseType = json["caseType"];
    blockName = json['blockName'];
    lovData = [];
    allowPaste = json['allowPaste'] ?? false;
    widgetType = json["widgetType"] == null? "Column":json["widgetType"];
    blockNameBl1 = json['blockNameBl1'];
    blockOrder = json['blockOrder'];
    fieldName = json['fieldName'];
    maxLen = 1000;
    showHint = false;
    hintMsg = "";
    allowSpecialCharactor = true;
    labelName = json['labelName'];
    fieldValue = json['fieldValue'];
    labelNameBl1 = json['labelNameBl1'];
    enableTime = json['enableTime'];
    optkey = json.containsKey("optkey") ? json["optkey"] : "";
    optvalue = json.containsKey("optvalue") ? json["optvalue"] : "";
    showMic = json["showMic"] == null ? false : json["showMic"];
    premiaColumnName = json['premiaColumnName'];
    fieldDisplayOrder = int.tryParse(json['fieldDisplayOrder'].toString());
    blockId = json['blockId'];
    fieldType = json['fieldType'];
    if(json.containsKey("requestObj")){
      requestObj = json['requestObj'];
    }else{
      requestObj = null;
    }
    isCurrency = json['isCurrency'] == null ? false:json['isCurrency'];
    isMobile = json['isMobile'] == null ? false:json['isMobile'];
    errorObj = {
      "cont":false,
      "msg":""
    };
    isPassword = json["isPassword"] == null?false:json["isPassword"];
    dataType = json['dataType'];
    serviceName = json['serviceName'];
    visibility = json['visibility'];
    mandatory = json['mandatory'];
    defaultYN = json['defaultYN'];
    disabledYN = json['disabledYN'] == null ? "N":json['disabledYN'];
    minDate = json['minDate'];
    maxDate = json['maxDate'];
    minLength = json['minLength'];
    maxLength = json['maxLength'];
    minLimit = json['minLimit'];

    maxLimit = json['maxLimit'];
    exactLength = json['exactLength'];
    applicableChannel = json['applicableChannel'];
    applicableTo = json['applicableTo'];
    eventName = json['eventName'];
    calendarStartView = json['calendarStartView'];
    if (json['rules'] != null) {
      rules = <Rules>[];
      backupRules = <Rules>[];
      json['rules'].forEach((v) {
        rules!.add(new Rules.fromJson(v));
        backupRules!.add(new Rules.fromJson(v));
      });
    }
    inputFormatters = [];
    options = [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fieldInfoId'] = this.fieldInfoId;
    data['lobCode'] = this.lobCode;
    data['lobName'] = this.lobName;
    data['lobNameBl1'] = this.lobNameBl1;
    data['prodCode'] = this.prodCode;
    data["widgetType"] = this.widgetType;
    data['enableTime']= this.enableTime;
    data['prodName'] = this.prodName;
    data["showMic"] = this.showMic;
    data['prodNameBl1'] = this.prodNameBl1;
    data['blockCategory'] = this.blockCategory;
    data['blockName'] = this.blockName;
    data['fieldValue'] = this.fieldValue;
    data["caseType"] = this.caseType;
    data["isCurrency"] = this.isCurrency;
    data["isMobile"] = this.isMobile;
    data["maxLen"] = this.maxLen;
    data["allowSpecialCharactor"]= this.allowSpecialCharactor;
    data['blockNameBl1'] = this.blockNameBl1;
    data['blockOrder'] = this.blockOrder;
    data['fieldName'] = this.fieldName;
    data["isPassword"] = this.isPassword;
    data['labelName'] = this.labelName;
    data['labelNameBl1'] = this.labelNameBl1;
    data['premiaColumnName'] = this.premiaColumnName;
    data['fieldDisplayOrder'] = this.fieldDisplayOrder;
    data['blockId'] = this.blockId;
    data['fieldType'] = this.fieldType;
    data['dataType'] = this.dataType;
    data['serviceName'] = this.serviceName;
    data['visibility'] = this.visibility;
    data['mandatory'] = this.mandatory;
    data['defaultYN'] = this.defaultYN;
    data['disabledYN'] = this.disabledYN;
    data['minDate'] = this.minDate;
    data['maxDate'] = this.maxDate;
    data['minLength'] = this.minLength;
    data['maxLength'] = this.maxLength;
    data['exactLength'] = this.exactLength;
    data['applicableChannel'] = this.applicableChannel;
    data['applicableTo'] = this.applicableTo;
    data['eventName'] = this.eventName;
    data['calendarStartView'] = this.calendarStartView;
    if (this.rules != null) {
      data['rules'] = this.rules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
class dropDownModel{
  dynamic key;
  dynamic value;
  dynamic mandatory;
  dropDownModel({this.key,this.value,this.mandatory});
  dropDownModel.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'];
    mandatory = json['mandatory']==null?"0":json['mandatory'];
  }
}
class Rules {
  int? validationInfoId;
  String? name;
  String? type;
  String? errorMsg;
  String? errorMsgBl1;
  String? script;

  Rules(
      {this.validationInfoId,
        this.name,
        this.type,
        this.errorMsg,
        this.errorMsgBl1,
        this.script});

  Rules.fromJson(Map<String, dynamic> json) {
    validationInfoId = json['validationInfoId'];
    name = json['name'];
    type = json['type'];
    errorMsg = json['errorMsg'];
    errorMsgBl1 = json['errorMsgBl1'];
    script = json['script'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['validationInfoId'] = this.validationInfoId;
    data['name'] = this.name;
    data['type'] = this.type;
    data['errorMsg'] = this.errorMsg;
    data['errorMsgBl1'] = this.errorMsgBl1;
    data['script'] = this.script;
    return data;
  }
}