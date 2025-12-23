import 'package:audit_app/screens/userscreen.dart';
import 'package:audit_app/theme/themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/loginscreen.dart';
import '../screens/splashscreen.dart';
import '../providers/languagemodel.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:url_strategy/url_strategy.dart';

import './../constants.dart';
import './../controllers/menu_app_controller.dart';
import './../screens/main/layoutscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'localization/app_translations_delegate.dart';
import 'localization/application.dart';

void main() {
  setHashUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final LanguageModel model = new LanguageModel();
  final MenuAppController theme = new MenuAppController();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: theme,
      child: Container()
    );
  }
}
