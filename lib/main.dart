import 'package:audit_app/providers/user_data_provider.dart';
import 'package:audit_app/screens/addauditscreen.dart';
import 'package:audit_app/screens/adddata.dart';
import 'package:audit_app/screens/addtemplatescreen.dart';
import 'package:audit_app/screens/auditcategoryscreen.dart';
import 'package:audit_app/screens/auditdetails.dart';
import 'package:audit_app/screens/auditinfoscreen.dart';
import 'package:audit_app/screens/auditlistscreen.dart';
import 'package:audit_app/screens/changepassword_screen.dart';
import 'package:audit_app/screens/questionscreen.dart';
import 'package:audit_app/screens/templatelistscreen.dart';
import 'package:audit_app/screens/templatescreenedit.dart';
import 'package:audit_app/screens/userscreen.dart';
import 'package:audit_app/theme/themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get.dart';

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

import 'controllers/usercontroller.dart';
import 'localization/app_translations_delegate.dart';
import 'localization/application.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_web/url_launcher_web.dart';


void main() {
  setHashUrlStrategy();
  //setPathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  Get.put(UserController());
  runApp(MainApp());
}
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // This widget is the root of your application.
  final LanguageModel model = new LanguageModel();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageModel>(
      create: (context)=>model,
      child: Consumer<LanguageModel>(
          builder: (context,provider,child){
            return GetMaterialApp(
              navigatorKey: navigatorKey,
              getPages: [
                GetPage(name: "/changepassword/:token", page:()=>ChangepasswordScreen()),
                GetPage(name: "/login", page:()=>Loginscreen()),
                GetPage(name: "/dashboard", page:()=>DashboardScreen()),
                GetPage(name: "/user", page:()=>UserScreen()),
                GetPage(name: "/client", page:()=>UserScreen()),
                GetPage(name: "/question", page:()=>UserScreen()),
                GetPage(name: "/auditdetails", page:()=>AuditDetails()),
                GetPage(name: "/addquestion", page:()=>Questionscreen()),
                GetPage(name: "/auditcategorylist", page:()=>AuditCategoryScreen()),
                GetPage(name: "/auditlist", page:()=>Auditlistscreen()),
                GetPage(name: "/addaudit", page:()=>AddAuditScreen()),
                GetPage(name: "/adddata", page:()=>AddDataScreen()),
                GetPage(name: "/auditinfo", page:()=>AuditInfoScreen()),
                GetPage(name: "/templateedit", page:()=>TemplateEditScreen()),
                GetPage(name: "/templatelist", page:()=>Templatelistscreen()),
                GetPage(name: "/addtemplate", page:()=>AddTemplateScreen()),
                GetPage(name: "/", page:()=>Splashscreen()),
              ],
            //   routes: <String, WidgetBuilder>{
            //     "/login": (context) => Loginscreen(),
            //     "/dashboard": (context) => DashboardScreen(),
            //     "/user": (context) => UserScreen(),
            //     "/client": (context) => UserScreen(),
            //     "/question": (context) => UserScreen(),
            //     "/auditdetails": (context) => AuditDetails(),
            //     "/addquestion": (context) => Questionscreen(),
            //     "/auditcategorylist": (context) => AuditCategoryScreen(),
            //     "/auditlist": (context) => Auditlistscreen(),
            //     "/addaudit": (context) => AddAuditScreen(),
            //     "/adddata": (context) => AddDataScreen(),
            //     // "/changepassword": (context) => ChangepasswordScreen(),
            //   },
              debugShowCheckedModeBanner: false,
              initialRoute: "/",
              title: 'Audit App',
              defaultTransition: Transition.noTransition,
              themeMode: provider.themeMode,
              darkTheme: AppThemeData.instance.dark(),
              theme: AppThemeData.instance.light(),
              locale: model.appLocal,
              localizationsDelegates: [
                AppTranslationsDelegate(),
                //provides localised strings
                GlobalCupertinoLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate
              ],
              supportedLocales: application.supportedLocales(),

            );
          }
      ),
    );
  }
}

