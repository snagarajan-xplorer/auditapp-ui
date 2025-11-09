import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/LocalStorage.dart';


class LanguageModel extends ChangeNotifier  {
  Locale _appLocale = Locale('en');
  var _themeMode = ThemeMode.light;
  Locale get appLocal => _appLocale ?? Locale("en");
  String _lang = "en";
  String get lang => _lang ?? "en";
  ThemeMode get themeMode => _themeMode ?? ThemeMode.light;
  void checkLanguage(){
    LocalStorage.getStringData("language")
        .then((value){
      if(value != null){
        if(value == "English"){
          _lang = "en";
          _appLocale = Locale('en');
        }else if(value == "Arabic"){
          _lang = "ar";
          _appLocale = Locale('ar');
        }
      }else{
        _appLocale = Locale('en');
      }
      Get.updateLocale(_appLocale);
    });
  }

  void changeDirection(String lang) {
    if (lang == "English") {
      _appLocale = Locale("en");
      _lang = "en";
    } else {
      _appLocale = Locale("ar");
      _lang = "ar";
    }
    Get.updateLocale(_appLocale);
    notifyListeners();
  }
  Future<void> setThemeModeAsync({
    required ThemeMode themeMode,
    bool save = true,
  }) async {
    if (themeMode != _themeMode) {
      _themeMode = themeMode;

      if (save) {
        final sharedPref = await SharedPreferences.getInstance();

        await sharedPref.setString(StorageKeys.appThemeMode, themeMode.name);
      }

      notifyListeners();
    }
  }
}
