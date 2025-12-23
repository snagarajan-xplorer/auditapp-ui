import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:web_admin/constants/dimens.dart';
import '../constants.dart';
import 'NoTransitionsBuilder.dart';
import 'theme_extensions/app_button_theme.dart';
import 'theme_extensions/app_color_scheme.dart';
import 'theme_extensions/app_data_table_theme.dart';
import 'theme_extensions/app_sidebar_theme.dart';

const Color kPrimaryColor = Color(0xFF0376d8);
const Color kSecondaryColor = Color(0xFF6C757D);
const Color kErrorColor = Color(0xFFDC3545);
const Color kSuccessColor = Color(0xFF08A158);
const Color kInfoColor = Color(0xFF17A2B8);
const Color kWarningColor = Color(0xFFFFc107);

const Color kTextColor = Color(0xFF2A2B2D);

const Color kScreenBackgroundColor = Color(0xFFF4F6F9);

class AppThemeData {
  AppThemeData._();

  static final AppThemeData _instance = AppThemeData._();

  static AppThemeData get instance => _instance;

  ThemeData light() {
    final themeData = ThemeData(
      useMaterial3: false,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: bgColor),
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      canvasColor: Colors.white,
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0376d8),
              textStyle: TextStyle(color: Colors.white),
              padding: EdgeInsets.only(top: 4, bottom: 4))),
      iconTheme: IconThemeData(color: Colors.grey.shade400),
      scaffoldBackgroundColor: kScreenBackgroundColor,
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF002651)),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: kPrimaryColor,
        onPrimary: Colors.white70,
        secondary: Colors.white,
        onSecondary: Colors.white,
        error: kErrorColor,
        onError: Colors.white,
        background: Colors.white,
        onBackground: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );

    final appColorScheme = AppColorScheme(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kErrorColor,
      success: kSuccessColor,
      info: kInfoColor,
      warning: kWarningColor,
      hyperlink: const Color(0xFF002651),
      buttonTextBlack: kTextColor,
      buttonTextDisabled: kTextColor.withOpacity(0.38),
    );

    final appSidebarTheme = AppSidebarTheme(
      backgroundColor: themeData.drawerTheme.backgroundColor!,
      foregroundColor: const Color(0xFFC2C7D0),
      sidebarWidth: 304.0,
      sidebarLeftPadding: kDefaultPadding,
      sidebarTopPadding: kDefaultPadding,
      sidebarRightPadding: kDefaultPadding,
      sidebarBottomPadding: kDefaultPadding,
      headerUserProfileRadius: 20.0,
      headerUsernameFontSize: 14.0,
      headerTextButtonFontSize: 14.0,
      menuFontSize: 14.0,
      menuBorderRadius: 5.0,
      menuLeftPadding: 0.0,
      menuTopPadding: 2.0,
      menuRightPadding: 0.0,
      menuBottomPadding: 2.0,
      menuHoverColor: Colors.white.withOpacity(0.2),
      menuSelectedFontColor: Colors.white,
      menuSelectedBackgroundColor: appColorScheme.primary,
      menuExpandedBackgroundColor: Colors.white.withOpacity(0.1),
      menuExpandedHoverColor: Colors.white.withOpacity(0.1),
      menuExpandedChildLeftPadding: 4.0,
      menuExpandedChildTopPadding: 2.0,
      menuExpandedChildRightPadding: 4.0,
      menuExpandedChildBottomPadding: 2.0,
    );

    return themeData.copyWith(
      extensions: [
        AppButtonTheme.fromAppColorScheme(appColorScheme),
        appColorScheme,
        AppDataTableTheme.fromTheme(themeData),
        appSidebarTheme,
      ],
    );
  }

  ThemeData dark() {
    final themeData = ThemeData.dark(useMaterial3: false).copyWith(
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF343A40)),
        canvasColor: secondaryColor,
        scaffoldBackgroundColor: bgColor,
        iconTheme: IconThemeData(color: Colors.white),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
            bodySmall: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white),
            bodyMedium: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            bodyLarge: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(backgroundColor: Colors.red)));

    final appColorScheme = AppColorScheme(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kErrorColor,
      success: kSuccessColor,
      info: kInfoColor,
      warning: kWarningColor,
      hyperlink: const Color(0xFF6BBBF7),
      buttonTextBlack: kTextColor,
      buttonTextDisabled: Colors.white.withOpacity(0.38),
    );

    final appSidebarTheme = AppSidebarTheme(
      backgroundColor: themeData.drawerTheme.backgroundColor!,
      foregroundColor: const Color(0xFFC2C7D0),
      sidebarWidth: 304.0,
      sidebarLeftPadding: kDefaultPadding,
      sidebarTopPadding: kDefaultPadding,
      sidebarRightPadding: kDefaultPadding,
      sidebarBottomPadding: kDefaultPadding,
      headerUserProfileRadius: 20.0,
      headerUsernameFontSize: 14.0,
      headerTextButtonFontSize: 14.0,
      menuFontSize: 14.0,
      menuBorderRadius: 5.0,
      menuLeftPadding: 0.0,
      menuTopPadding: 2.0,
      menuRightPadding: 0.0,
      menuBottomPadding: 2.0,
      menuHoverColor: Colors.white.withOpacity(0.2),
      menuSelectedFontColor: Colors.white,
      menuSelectedBackgroundColor: appColorScheme.primary,
      menuExpandedBackgroundColor: Colors.white.withOpacity(0.1),
      menuExpandedHoverColor: Colors.white.withOpacity(0.1),
      menuExpandedChildLeftPadding: 4.0,
      menuExpandedChildTopPadding: 2.0,
      menuExpandedChildRightPadding: 4.0,
      menuExpandedChildBottomPadding: 2.0,
    );

    return themeData.copyWith(
      extensions: [
        AppButtonTheme.fromAppColorScheme(appColorScheme),
        appColorScheme,
        appSidebarTheme,
        AppDataTableTheme.fromTheme(themeData),
      ],
    );
  }
}
