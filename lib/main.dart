import 'package:audit_app/screens/addauditscreen.dart';
import 'package:audit_app/screens/2.0/create_audit_screen.dart';
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
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get.dart';

import 'screens/2.0/dashboard_screen.dart';
// import '../screens/loginscreen.dart';
import 'screens/2.0/login_screen.dart';
import '../screens/splashscreen.dart';
import '../providers/languagemodel.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:url_strategy/url_strategy.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/usercontroller.dart';
import 'localization/app_translations_delegate.dart';
import 'localization/application.dart';

import 'package:audit_app/screens/2.0/scheduled_audit_screen.dart';
import 'package:audit_app/screens/2.0/unscheduled_audit_screen.dart';
// import 'package:audit_app/screens/allindiastatewisescreen.dart';
import 'package:audit_app/screens/2.0/all_india_state_wise_audit.dart';
import 'package:audit_app/screens/2.0/red_report_audit.dart';
import 'package:audit_app/screens/2.0/audit_list_screen.dart';
import 'package:audit_app/screens/2.0/user_screen.dart';
import 'package:audit_app/screens/2.0/create_user_screen.dart';

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
      create: (context) => model,
      child: Consumer<LanguageModel>(builder: (context, provider, child) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          getPages: [
            GetPage(
                name: "/changepassword/:token",
                page: () => ChangepasswordScreen()),
            //GetPage(name: "/login", page: () => Loginscreen()),
            GetPage(name: "/dashboard", page: () => DashboardScreen()),
            GetPage(name: "/user", page: () => UserScreenV2()),
            GetPage(name: "/client", page: () => UserScreenV2()),
            GetPage(name: "/question", page: () => UserScreen()),
            GetPage(name: "/auditdetails", page: () => AuditDetails()),
            GetPage(name: "/addquestion", page: () => Questionscreen()),
            GetPage(
                name: "/auditcategorylist", page: () => AuditCategoryScreen()),
            GetPage(name: "/auditlist-v1", page: () => Auditlistscreen()),
            GetPage(name: "/addaudit", page: () => AddAuditScreen()),
            GetPage(name: "/createaudit", page: () => CreateAuditScreen()),
            GetPage(name: "/adddata", page: () => AddDataScreen()),
            GetPage(name: "/createuser", page: () => CreateUserScreen()),
            GetPage(name: "/auditinfo", page: () => AuditInfoScreen()),
            GetPage(name: "/templateedit", page: () => TemplateEditScreen()),
            GetPage(name: "/templatelist", page: () => Templatelistscreen()),
            GetPage(name: "/addtemplate", page: () => AddTemplateScreen()),
            GetPage(
                name: "/scheduledaudit", page: () => ScheduledAuditScreen()),
            GetPage(
                name: "/unscheduledaudit",
                page: () => UnScheduledAuditScreen()),
            // GetPage(
            //     name: "/all-india-state-activity",
            //     page: () => AllIndiaStateWiseScreen()),
            GetPage(
                name: "/all-india-state-wise-audit",
                page: () => AllIndiaStateWiseAudit()),
            GetPage(name: "/red-report", page: () => RedReportScreen()),
            GetPage(name: "/auditlist", page: () => AuditListV2Screen()),
            GetPage(name: "/", page: () => Splashscreen()),
            //2.0
            GetPage(name: "/login", page: () => LoginScreen()),
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
      }),
    );
  }
}
