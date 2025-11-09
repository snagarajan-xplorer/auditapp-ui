import 'package:encryptor/encryptor.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LocalStorage{

  static final key = "MHlsI4WexJJGNCFYDUS8wscZm/mqmmcHW2Naf/I+2vCh4MgL/MTEfjF1XyM59j3x";


  static Future<int?> getIntData(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(name);
  }
  static Future<bool> setIntData(String name,dynamic obj) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(name,obj);
  }
  static Future<String?> getStringData(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? output = prefs.getString(name);

    print(output);
    return output;
  }
  static Future<bool> setStringData(String name,dynamic obj) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = Encryptor.encrypt(key, obj);
    return prefs.setString(name,obj);
  }

}