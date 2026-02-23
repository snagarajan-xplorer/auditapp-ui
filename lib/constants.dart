import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Set to true to use mock data for API responses
const String env = 'prod';

const primaryColor = Color(0xFF2697FF);
const secondaryColor = Color(0xFF2A2D3E);
const bgColor = Color(0xFF212332);

const defaultPadding = 16.0;
const headingFontSize = 18.0;
const paragraphFontSize = 16.0;
const labelFontSize = 14.0;
const smallFontSize = 12.0;
const headTextStyle = TextStyle(
  fontWeight: FontWeight.w900,
  fontSize: headingFontSize
);
const paragraphTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: paragraphFontSize
);
const smallTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: smallFontSize
);
const labelTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: labelFontSize
);
const headingTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: labelFontSize
);
const headingSmallTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: smallFontSize
);
const headingTableTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: smallFontSize
);
const paragTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontSize: labelFontSize
);
// Padding begin.
const double kDefaultPadding = 16.0;

const double kTextPadding = 4.0;
// Padding end.

// Screen width begin.
const double kScreenWidthSm = 576.0;

const double kScreenWidthMd = 768.0;

const double kScreenWidthLg = 992.0;

const double kScreenWidthXl = 1200.0;

const double kScreenWidthXxl = 1400.0;
const List<String> adminRole = ["SA","AD"];

const List<String> menuAccessRole = ["SA","AD","SrA"];


const List<String> menuAccessRoleAdmin = ["SA","AD"];
// Screen width end.

// Dialog width begin.
const double kDialogWidth = 460.0;
// Dialog width end.

const double kFieldWidth = 800.0;
const buttonHeight = 40.0;

// ============================================================================
// API CONFIGURATION
// ============================================================================
// IMPORTANT: Make sure your backend server is running before using local URLs
//
// For LOCAL DEVELOPMENT:
// - Uncomment the 127.0.0.1:8000 URLs below
// - Start your backend server on port 8000
// - If using Docker: use 'host.docker.internal' instead of '127.0.0.1'
//
// For PRODUCTION:
// - Uncomment one of the production URLs (demo.webtekie.in or auditondgo.com)
// - Ensure CORS is properly configured on the backend
// ============================================================================

//https://audit.webtekie.in/public/api/login

// LOCAL DEVELOPMENT (requires backend running on port 8000)
// const API_URL = "http://127.0.0.1:8000/api/";
// const IMG_URL = "http://127.0.0.1:8000/storage/";

// DEMO SERVER
// const API_URL = "https://demo.webtekie.in/restapi/public/api/";
// const IMG_URL = "https://demo.webtekie.in/restapi/public/storage/";

// CURRENTLY ACTIVE (LOCAL - REQUIRES BACKEND RUNNING!)
const API_URL = "http://127.0.0.1:8000/api/";
const IMG_URL = "http://127.0.0.1:8000/storage/";

// PRODUCTION SERVER
// const API_URL = "https://auditondgo.com/restapi/public/api/";
// const IMG_URL = "https://auditondgo.com/restapi/public/storage/";



class StorageKeys {
  static const String appLanguageCode = 'APP_LANGUAGE_CODE';
  static const String appThemeMode = 'APP_THEME_MODE';
  static const String username = 'USERNAME';
  static const String userProfileImageUrl = 'USER_PROFILE_IMAGE_URL';
}


