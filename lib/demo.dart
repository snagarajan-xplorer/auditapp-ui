
import '../providers/languagemodel.dart';
import 'package:url_strategy/url_strategy.dart';

import './../controllers/menu_app_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  setHashUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final LanguageModel model = LanguageModel();
  final MenuAppController theme = MenuAppController();

  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: theme,
      child: Container()
    );
  }
}
