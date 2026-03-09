
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



class DynamicField {
  int? fieldInfoId;
  String? lobCode;
  String? lobName;
  String? lobNameBl1;
  String? prodCode;
  String? prodName;
  dynamic prodNameBl1;
  String? blockCategory;
  String? blockName;
  bool? showMic;
  bool? showHint;
  String? hintMsg;
  String? blockNameBl1;
  int? blockOrder;
  String? fieldName;
  dynamic minLimit;
  dynamic maxLimit;
  int? maxLen;
  bool? isMobile;
  bool? allowPaste;
  dynamic keystate;
  String? labelName;
  String? labelNameBl1;
  dynamic premiaColumnName;
  int? fieldDisplayOrder;
  dynamic blockId;
  String? fieldType;
  String? dataType;
  dynamic serviceName;
  Map<String,dynamic>? requestObj;
  String? visibility;
  String? mandatory;
  bool? isPassword;
  bool? allowSpecialCharactor;
  dynamic defaultYN;
  dynamic disabledYN;
  dynamic minDate;
  dynamic maxDate;
  dynamic errorObj;
  int? minLength;
  int? maxLength;
  int? exactLength;
  String? applicableChannel;
  String? applicableTo;
  String? optkey;
  String? optvalue;
  String? caseType;
  String? widgetType;
  dynamic eventName;
  dynamic calendarStartView;
  List<Rules>? rules;
  List<Rules>? backupRules;
  List<TextInputFormatter>? inputFormatters;
  TextInputType? textInputType;
  List<DropdownMenuItem<String>>? options;
  List<dynamic>? lovData;
  FormFieldValidator? validator;
  dynamic fieldValue;
  dynamic selectedValue;
  dynamic currencyValue;
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
    widgetType = json["widgetType"] ?? "Column";
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
    showMic = json["showMic"] ?? false;
    premiaColumnName = json['premiaColumnName'];
    fieldDisplayOrder = int.tryParse(json['fieldDisplayOrder'].toString());
    blockId = json['blockId'];
    fieldType = json['fieldType'];
    if(json.containsKey("requestObj")){
      requestObj = json['requestObj'];
    }else{
      requestObj = null;
    }
    isCurrency = json['isCurrency'] ?? false;
    isMobile = json['isMobile'] ?? false;
    errorObj = {
      "cont":false,
      "msg":""
    };
    isPassword = json["isPassword"] ?? false;
    dataType = json['dataType'];
    serviceName = json['serviceName'];
    visibility = json['visibility'];
    mandatory = json['mandatory'];
    defaultYN = json['defaultYN'];
    disabledYN = json['disabledYN'] ?? "N";
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
        rules!.add(Rules.fromJson(v));
        backupRules!.add(Rules.fromJson(v));
      });
    }
    inputFormatters = [];
    options = [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fieldInfoId'] = fieldInfoId;
    data['lobCode'] = lobCode;
    data['lobName'] = lobName;
    data['lobNameBl1'] = lobNameBl1;
    data['prodCode'] = prodCode;
    data["widgetType"] = widgetType;
    data['enableTime']= enableTime;
    data['prodName'] = prodName;
    data["showMic"] = showMic;
    data['prodNameBl1'] = prodNameBl1;
    data['blockCategory'] = blockCategory;
    data['blockName'] = blockName;
    data['fieldValue'] = fieldValue;
    data["caseType"] = caseType;
    data["isCurrency"] = isCurrency;
    data["isMobile"] = isMobile;
    data["maxLen"] = maxLen;
    data["allowSpecialCharactor"]= allowSpecialCharactor;
    data['blockNameBl1'] = blockNameBl1;
    data['blockOrder'] = blockOrder;
    data['fieldName'] = fieldName;
    data["isPassword"] = isPassword;
    data['labelName'] = labelName;
    data['labelNameBl1'] = labelNameBl1;
    data['premiaColumnName'] = premiaColumnName;
    data['fieldDisplayOrder'] = fieldDisplayOrder;
    data['blockId'] = blockId;
    data['fieldType'] = fieldType;
    data['dataType'] = dataType;
    data['serviceName'] = serviceName;
    data['visibility'] = visibility;
    data['mandatory'] = mandatory;
    data['defaultYN'] = defaultYN;
    data['disabledYN'] = disabledYN;
    data['minDate'] = minDate;
    data['maxDate'] = maxDate;
    data['minLength'] = minLength;
    data['maxLength'] = maxLength;
    data['exactLength'] = exactLength;
    data['applicableChannel'] = applicableChannel;
    data['applicableTo'] = applicableTo;
    data['eventName'] = eventName;
    data['calendarStartView'] = calendarStartView;
    if (rules != null) {
      data['rules'] = rules!.map((v) => v.toJson()).toList();
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
    mandatory = json['mandatory'] ?? "0";
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['validationInfoId'] = validationInfoId;
    data['name'] = name;
    data['type'] = type;
    data['errorMsg'] = errorMsg;
    data['errorMsgBl1'] = errorMsgBl1;
    data['script'] = script;
    return data;
  }
}