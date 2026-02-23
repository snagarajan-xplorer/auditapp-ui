import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:audit_app/constants.dart';
import 'package:flutter/services.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/LocalStorage.dart';
import 'package:flutter/material.dart';
import 'package:audit_app/models/userdata.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:jiffy/jiffy.dart';

import '../models/dynamicfield.dart';
import '../models/my_files.dart';
import '../services/utility.dart';

class UserController extends GetxController {
  UserData userData = UserData();
  int selectedIndex = 0;
  String selectedClientId = "";
  List<DynamicField> formArray = [];
  List<dynamic> role = [];
  List<dynamic> clinetArr = [];
  List<dynamic> userlist = [];
  List<dynamic> categorylist = [];
  List<dynamic> dropdownlist = [];
  List<String> year = [];
  int startYear = 2025;
  List<Map<String, dynamic>> scoreArr = [
    {"color": Colors.red, "value": "0"},
    {"color": Colors.orange, "value": "1"},
    {"color": Colors.yellow, "value": "2"},
    {"color": Colors.lightGreen, "value": "3"},
    {"color": Colors.indigo, "value": "4"},
    {"color": Colors.blueGrey, "value": "N/A"}
  ];
  List<Map<String, dynamic>> scoreArr2 = [
    {"color": Colors.red, "value": "0"},
    {"color": Colors.orange, "value": "1"},
    {"color": Colors.lightGreen, "value": "2"},
    {"color": Color(0xFF002651), "value": "3"},
  ];
  List<Map<String, dynamic>> colorArr = [
    {
      "color": Colors.red,
      "svg": "assets/images/extreme.png",
      "value": "0",
      "svgcolor": Color(0xFFf33f33)
    },
    {
      "color": Colors.red,
      "svg": "assets/images/high.png",
      "value": "1",
      "svgcolor": Color(0xFFf19d38)
    },
    {
      "color": Colors.orange,
      "svg": "assets/images/high.png",
      "value": "2",
      "svgcolor": Color(0xFFf9df41)
    },
    {
      "color": Colors.yellow,
      "svg": "assets/images/medium.png",
      "value": "3",
      "svgcolor": Color(0xFFf9df41)
    },
    {
      "color": Colors.blue,
      "svg": "assets/images/low.png",
      "value": "4",
      "svgcolor": Color(0xFF4994ec)
    }
  ];
  List<CloudStorageInfo> countList = [];
  GeoJsonParser geoJsonParser = GeoJsonParser(
      defaultPolygonBorderColor: Colors.red,
      defaultPolygonFillColor: Colors.red.withAlpha(10),
      defaultPolylineStroke: 1);
  loadInitData() async {
    String? str = await LocalStorage.getStringData("userdata");
    if (str != null && str.isNotEmpty) {
      userData = UserData.fromJson(jsonDecode(str));
    }
    String filename = "assets/json/states.json";
    if (kIsWeb) {
      filename = "json/states.json";
    }
    year = [];
    int y = Jiffy.now().year;
    if (y == startYear) {
      year.add(y.toString());
    } else {
      if (y > startYear) {
        for (int id = y; id > startYear; id--) {
          year.add(id.toString());
        }
      }
    }

    UtilityService().parseJsonFromAssets(filename).then((res) {
      Map<String, dynamic> obj = jsonDecode(res);
      geoJsonParser.parseGeoJsonAsString(res);
    });
  }

  void login(context,
      {required Map data,
      required Function callback,
      required Function(String) onFail}) {
    APIService(context).postData("login", data, false).then((resvalue) async {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        print("login response ${res}");
        if (!res.containsKey("type")) {
          // Clear any stale session from a previous user before saving new one
          await LocalStorage.clearData("userdata");
          await LocalStorage.setStringData("userdata", resvalue);
          userData = UserData.fromJson(res);
          callback(); 
        } else {
          print(res["message"]);
          if (res.containsKey("message")) {
            onFail(res["message"]);
          }
        }
      }
    });
  }

  void checkCorrectToken(context,
      {required Map data, required Function(dynamic) callback}) {
    APIService(context)
        .postData("checkCorrectToken", data, false)
        .then((resvalue) {
      Map<String, dynamic> res = jsonDecode(resvalue);
      callback(res);
    });
  }

  void changePassword(context,
      {required Map<String, dynamic> data, required Function() callback}) {
    APIService(context)
        .postData("changePassword", data, false)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void forgotPassword(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context)
        .postData("forgotPassword", data, false)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        print(res);
        if (!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }

  void register(context,
      {required Map data, required Function(dynamic) callback}) {
    APIService(context).postData("register", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("mid")) {
            callback(res);
          }
        }
      }
    });
  }

  void uploadImage(context,
      {required String filename,
      required dynamic bytes,
      required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context)
        .uploadFiles(filename, bytes, "upload", data)
        .then((resvalue) {
      if (resvalue != null && resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        callback(res);
      }
    });
  }

  void uploadTemplate(context,
      {required String filename,
      required dynamic bytes,
      required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context)
        .uploadExcelFiles(
      filename,
      bytes,
      "saveTemplate",
      data,
    )
        .then((resvalue) {
      print("resvalue ${resvalue}");
      if (resvalue != null && resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (res.containsKey("message")) {
          APIService(context).showToastMgs(res["message"]);
          callback(res);
        }
      } else {
        if (resvalue == "OK") {
          callback({});
        }
      }
    });
  }

  void getUserList(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback}) {
    APIService(context).postData("getUserList", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getOverAllReport(context,
      {required Function(Map<String, dynamic>) callback}) {
    APIService(context).getData("getOverAllReport", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res);
          }
        }
      }
    });
  }

  void getPinCode(context,
      {required String pincode, required Function(List<dynamic>) callback}) {
    APIService(context)
        .getData("searchPincode?pincode=" + pincode, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (res.containsKey("data")) {
          callback(res["data"]);
        }
      }
    });
  }

  void getCategoryList(context, {required Function(List<dynamic>) callback}) {
    APIService(context).getData("getCategoryList", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            categorylist = res["data"];
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getTemplateList(context,
      {required String clientid, required Function(List<dynamic>) callback}) {
    APIService(context)
        .getData("getTemplate?clientid=" + clientid, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getAllTemplateList(context,
      {required Function(List<dynamic>) callback}) {
    APIService(context).getData("getAllTemplate", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getZone(context, {required Function(List<dynamic>) callback}) {
    APIService(context).getData("getZone", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getDropdownList(context, {required Function(dynamic) callback}) {
    APIService(context).getData("getDropDownList", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            dropdownlist = res["data"];
            callback(res["data"]);
          }
        }
      }
    });
  }

  // ─── Financial-Year Helpers ────────────────────────────────────────────────

  /// Parses a financial-year string (e.g. "FY2025-26" or "2025-26") and returns
  /// the inclusive date range: Apr 1 of start-year → Mar 31 of end-year.
  /// Returns null if the string cannot be parsed.
  static Map<String, DateTime>? parseFyRange(String fy) {
    final trimmed = fy.trim();
    // Bare 4-digit end year (e.g. "2026") → Indian FY: Apr 2025 to Mar 2026
    final bareYear = RegExp(r'^\d{4}$').firstMatch(trimmed);
    if (bareYear != null) {
      final endYear = int.parse(trimmed);
      return {
        'start': DateTime(endYear - 1, 4, 1),
        'end':   DateTime(endYear,     3, 31, 23, 59, 59),
      };
    }
    final m = RegExp(
      r'^(?:FY)?(\d{4})-(\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (m == null) return null;
    final startYear = int.parse(m.group(1)!);
    final endPart   = m.group(2)!;
    final endYear   = endPart.length == 2
        ? int.parse(startYear.toString().substring(0, 2) + endPart)
        : int.parse(endPart);
    return {
      'start': DateTime(startYear, 4, 1),
      'end':   DateTime(endYear,   3, 31, 23, 59, 59),
    };
  }

  /// Parses a date string in "dd MMM yyyy" format (e.g. "05 Jan 2026").
  /// Returns null if the string is null, "-", or unparseable.
  static DateTime? parseDMMMYYYY(String? s) {
    if (s == null || s.trim() == '-') return null;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,  'may': 5,  'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final mo = months[parts[1].toLowerCase()];
    final y  = int.tryParse(parts[2]);
    if (d == null || mo == null || y == null) return null;
    return DateTime(y, mo, d);
  }

  /// Filters [items] to those whose [dateField] value ("dd MMM yyyy") falls
  /// within the financial year described by [fy]. If [fy] cannot be parsed,
  /// the original list is returned unchanged.
  static List<dynamic> filterByFy(
      List<dynamic> items, String fy, String dateField) {
    final range = parseFyRange(fy);
    if (range == null) return items;
    final start = range['start']!;
    final end   = range['end']!;
    return items.where((e) {
      final date = parseDMMMYYYY(e[dateField] as String?);
      if (date == null) return true;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  // ─── Audit Normalisation ─────────────────────────────────────────────────────

  Map<String, dynamic> _normalizeAuditStatusMap(String s) {
    const map = {
      'P':  {'label': 'Published',   'color': 'green'},
      'IP': {'label': 'Inprogress',   'color': 'orange'},
      'PG': {'label': 'Inprogress',   'color': 'orange'},
      'C':  {'label': 'Review',       'color': 'pink'},
      'S':  {'label': 'Upcoming',     'color': 'purple'},
      'CL': {'label': 'Cancelled',    'color': 'red'},
    };
    return Map<String, dynamic>.from(map[s] ?? {'label': s, 'color': 'grey'});
  }

  String _formatAuditDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw.toString());
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Map<String, dynamic> _normalizeAuditItem(Map<String, dynamic> item) {
    final statusRaw = item['status'];
    final statusObj = (statusRaw is Map)
        ? Map<String, dynamic>.from(statusRaw)
        : _normalizeAuditStatusMap(statusRaw?.toString() ?? '');
    return {
      'audit_id':         item['audit_no'] ?? item['audit_id'] ?? ('AD-' + (item['id']?.toString() ?? '')),
      'audit_name':       item['audit_name'] ?? item['auditname'] ?? '-',
      'sched_date':       _formatAuditDate(item['sched_date'] ?? item['start_date']),
      'start_date':       _formatAuditDate(item['start_date']),
      'end_date':         _formatAuditDate(item['end_date']),
      'zone':             item['zone'] ?? '-',
      'state':            item['state'] ?? '-',
      'city':             item['city'] ?? '-',
      'location':         item['location'] ?? item['branch'] ?? '-',
      'type_of_location': item['type_of_location'] ?? '-',
      'auditor':          item['auditor'] ?? item['auditorname'] ?? '-',
      'status':           statusObj,
    };
  }

  Future<void> getUnScheduledAuditDetails(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>, int) callback}) async {
    if (env == 'local') {
      final String mockString = await rootBundle
          .loadString('assets/json/mock/get-unscheduled-audit.mock.json');
      final mockData = json.decode(mockString);
      final List<dynamic> list = List<dynamic>.from(mockData['data'] ?? []);
      callback(list, list.length);
      return;
    }
    APIService(context).postData("getUnScheduledAuditDetails", data, true).then((resvalue) {
      try {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              final List<dynamic> list = List<dynamic>.from(res["data"]);
              callback(list, list.length);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("getUnScheduledAuditDetails error: $e");
      }
      callback([], 0);
    });
  }

  Future<void> saveUnScheduledAudit(context,
      {required Map<String, dynamic> data,
      required Function(bool) callback}) async {
    APIService(context).postData("saveUnScheduledAudit", data, true).then((resvalue) {
      try {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          callback(!res.containsKey("type"));
          return;
        }
      } catch (e) {
        debugPrint("saveUnScheduledAudit error: $e");
      }
      callback(false);
    });
  }

  Future<void> deleteUnScheduledAudit(context,
      {required Map<String, dynamic> data,
      required Function(bool) callback}) async {
    APIService(context).postData("deleteUnScheduledAudit", data, true).then((resvalue) {
      try {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          callback(!res.containsKey("type"));
          return;
        }
      } catch (e) {
        debugPrint("deleteUnScheduledAudit error: $e");
      }
      callback(false);
    });
  }

  Future<void> getScheduledAuditDetails(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>, int) callback}) async {
    if (env == 'local') {
      final String mockString = await rootBundle.loadString('assets/json/mock/get-audit-list.mock.json');
      final mockData = json.decode(mockString);
      final raw = (mockData["data"] as List? ?? []);
      final filtered = filterByFy(raw, (data["year"] ?? "") as String, "start_date");
      final list = filtered
          .map((e) => _normalizeAuditItem(Map<String, dynamic>.from(e)))
          .toList();
      callback(list, list.length);
      return;
    }
    APIService(context).postData("getScheduledAuditDetails", data, true).then((resvalue) {
      try {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              final List<dynamic> list = (res["data"] as List)
                  .map((e) => _normalizeAuditItem(Map<String, dynamic>.from(e)))
                  .toList();
              callback(list, list.length);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("getScheduledAuditDetails error: $e");
      }
      // Error or empty — return empty list so UI can stop loading
      callback([], 0);
    });
  }

  void getAuditList(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback}) {
    if (env == 'local') {
      rootBundle.loadString('assets/json/mock/get-auditlist.mock.json').then((mockString) {
        final mockData = json.decode(mockString);
        final List<dynamic> raw = mockData["data"] as List? ?? [];
        // Filter by year range to match backend behaviour
        final yearStr = (data["year"] ?? "").toString();
        final filtered = _filterByYear(raw, yearStr, "start_date");
        // Filter by month if not "All"
        final monthStr = (data["month"] ?? "All").toString();
        final monthFiltered = monthStr == "All"
            ? filtered
            : filtered.where((e) {
                try {
                  final dt = DateTime.parse(e["start_date"].toString());
                  return dt.month.toString() == monthStr;
                } catch (_) {
                  return true;
                }
              }).toList();
        callback(monthFiltered);
      });
      return;
    }
    APIService(context).postData("getAuditList", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          } else {
            // API returned e.g. {"message": "No Record found"}
            callback([]);
          }
          return;
        }
      }
      // Fallback: response was short or had "type" — treat as empty
      callback([]);
    });
  }

  /// Filter mock data by year range (April to March financial year).
  /// [yearStr] is the end year of the FY, e.g. "2026" for FY2025-26.
  static List<dynamic> _filterByYear(List<dynamic> items, String yearStr, String dateField) {
    if (yearStr.isEmpty) return items;
    final endYear = int.tryParse(yearStr);
    if (endYear == null) return items;
    final start = DateTime(endYear - 1, 4, 1);  // April 1 of start year
    final end = DateTime(endYear, 3, 31);        // March 31 of end year
    return items.where((e) {
      try {
        final dt = DateTime.parse(e[dateField].toString());
        return !dt.isBefore(start) && !dt.isAfter(end);
      } catch (_) {
        return true;
      }
    }).toList();
  }

  void getClientUserList(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback,
      required Function(dynamic) errorcallback}) {
    APIService(context)
        .postData("getClientUserList", data, true, showMsg: false)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        } else {
          errorcallback(res);
        }
      }
    });
  }

  void sendAuditComments(context,
      {required Map<String, dynamic> data,
      required VoidCallback callback,
      required Function(dynamic) errorcallback}) {
    APIService(context)
        .postData("sendAuditComments", data, true, showMsg: false)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        } else {
          errorcallback(res);
        }
      }
    });
  }

  void publishUserReport(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context)
        .postData("publishUserReport", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void logout(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context).postData("logout", data, true).then((resvalue) async {
      // Always clear local session regardless of API response
      await LocalStorage.clearData("userdata");
      userData = UserData();
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
          return;
        }
      }
      callback();
    });
  }

  Future<void> getClientList(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback,
      bool loader = true}) async {
    if (env == 'local') {
      final String mockString = await rootBundle.loadString('assets/json/mock/get-client-list.mock.json');
      final mockData = json.decode(mockString);
      callback(mockData["data"]);
    } else {
      APIService(context)
          .postData("getClientList", data, true, loader: loader)
          .then((resvalue) {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              callback(res["data"]);
            }
          }
        }
      });
    }
  }

  Future<void> getClientHeatReport(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) async {
    if (env == 'local') {
      // Load mock data from assets/json/mock/get-audit-report.mock.json
      final String mockString = await rootBundle.loadString('assets/json/mock/get-audit-report.mock.json');
      final mockData = json.decode(mockString);
      callback(mockData["data"]);
    } else {
      APIService(context).postData("getAuditReport", data, true).then((resvalue) {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              callback(res["data"]);
            }
          }
        }
      });
    }
  }

  void getPublisedFinancialYearList(context,
      {required Function(dynamic) callback}) {
    APIService(context)
        .getData("getPublisedFinancialYearList", true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        try {
          Map<String, dynamic> res = jsonDecode(resvalue);

          // Check for error type first
          if (res.containsKey("type") && res["type"] == "error") {
            // Return empty data to trigger fallback
            callback([]);
            return;
          }

          // Handle success response with message and data
          if (res.containsKey("message") && res.containsKey("data")) {
            callback(res["data"]);
          } else if (res.containsKey("data")) {
            callback(res["data"]);
          } else {
            callback([]);
          }
        } catch (e) {
          callback([]);
        }
      } else {
        callback([]);
      }
    }).catchError((error) {
      callback([]);
    });
  }

  void getAllIndiaStateWiseAudit(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) async {
    if (env == 'local') {
      final String mockString = await rootBundle.loadString('assets/json/mock/get-all-india-state-wise-audit.mock.json');
      final mockData = json.decode(mockString);
      callback(mockData["data"]);
      return;
    }
    APIService(context)
        .postData("getAllIndiaStateWiseAudit", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        try {
          Map<String, dynamic> res = jsonDecode(resvalue);

          // Check if response has error type (including HTML errors)
          if (res.containsKey("type") && res["type"] == "error") {
            // Call callback with empty array to trigger fallback
            callback([]);
            return;
          }

          // Handle success response
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              callback(res["data"]);
            } else {
              callback([]);
            }
          } else {
            callback([]);
          }
        } catch (e) {
          callback([]);
        }
      } else {
        callback([]);
      }
    }).catchError((error) {
      // Call callback with empty array to prevent infinite loading
      callback([]);
    });
  }

  void getZoneWiseNCAudit(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) async {
    if (env == 'local') {
      final String mockString = await rootBundle.loadString('assets/json/mock/get-zone-wise-nc-audit.mock.json');
      final mockData = json.decode(mockString);
      callback(mockData);
      return;
    }
    APIService(context)
        .postData("getZoneWiseNCAudit", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        try {
          Map<String, dynamic> res = jsonDecode(resvalue);

          // Check if response has error type (including HTML errors)
          if (res.containsKey("type") && res["type"] == "error") {
            // Call callback with empty array to trigger fallback
            callback([]);
            return;
          }

          // Handle success response - API returns the full response object directly
          if (!res.containsKey("type")) {
            // Return the full response since it contains map_data directly
            callback(res);
          } else {
            callback([]);
          }
        } catch (e) {
          callback([]);
        }
      } else {
        callback([]);
      }
    }).catchError((error) {
      // Call callback with empty array to prevent infinite loading
      callback([]);
    });
  }

  Future<void> getAuditCount(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) async {
    if (env == 'local') {
      final String mockString = await rootBundle.loadString('assets/json/mock/get-audit-summary.mock.json');
      final mockData = json.decode(mockString);
      callback(mockData["data"]);
    } else {
      APIService(context)
          .postData("getAuditSummary", data, true)
          .then((resvalue) {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              callback(res["data"]);
            }
          }
        }
      });
    }
  }

  void getCurrentDate(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context).getData("getCurrentDateTime", true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }

  void getAuditRemarks(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback}) {
    APIService(context).postData("getRemarks", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void getTempalteStatus(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context).postData("templateStatus", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }

  void getUserStatus(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context).postData("userStatus", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback(res);
        }
      }
    });
  }

  void saveAuditBranch(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context)
        .postData("saveAuditBranch", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void removeUploadFile(context,
      {required Map<String, dynamic> data,
      required Function(List<dynamic>) callback}) {
    APIService(context)
        .postData("removeUploadFile", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void publishAuditStatus(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context)
        .postData("publishAuditStatus", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void saveAuditAcknowledge(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context)
        .postData("saveAuditAcknowledge", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void saveAuditQuestion(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context)
        .postData("saveAuditQuestion", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void getAuditQuestion(context,
      {required Map<String, dynamic> data,
      required Function(dynamic) callback}) {
    APIService(context)
        .postData("getAuditQuestion", data, true)
        .then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          if (res.containsKey("data")) {
            callback(res["data"]);
          }
        }
      }
    });
  }

  void saveAudit(context,
      {required Map<String, dynamic> data, required VoidCallback callback}) {
    APIService(context).postData("saveAudit", data, true).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type")) {
          callback();
        }
      }
    });
  }

  void getStaticForm(context,
      {required String url,
      required ArgumentData type,
      required VoidCallback callback}) {
    APIService(context).loaderShow();
    UtilityService().parseJsonFromAssets(url).then((value2) async {
      var res2 = JsonDecoder().convert(value2);
      formArray = [];

      res2.forEach((element) {
        DynamicField obj = DynamicField.fromJson(element);
        obj.isPassword = false;
        obj.showMic = false;
        obj.isCurrency = false;
        obj.disabledYN = obj.disabledYN == null ? "N" : obj.disabledYN;
        obj.enableTime = false;
        obj.fieldValue = "";
        obj.selectedValue = "";
        obj.currencyValue = "";
        obj.isMobile = false;
        obj.maxDate = DateTime.now();
        obj.minDate = Jiffy.now().subtract(years: 30).dateTime;
        if (obj.fieldName == "mobile") {
          obj.isMobile = true;
          obj.maxLen = 10;
        } else if (obj.fieldName == "pincode") {
          obj.maxLen = 6;
        } else if (obj.fieldName.toString().toLowerCase().contains("name")) {
          obj.caseType = "U";
        }
        if (type == ArgumentData.CLIENT) {
          if ([
                "parentid",
                "role",
                "joiningdate",
                "pincode",
                "state",
                "zone",
                "city",
                "address",
                "district",
                "companyname"
              ].indexOf(obj.fieldName!) ==
              -1) {
            obj.visibility = "Y";
            if (obj.fieldName == "client") {
              obj.fieldDisplayOrder = 0;
              obj.fieldType = "Select";
            }
            formArray.add(obj);
          }
        } else {
          if (["companyname"].indexOf(obj.fieldName!) == -1) {
            if (obj.fieldName == "client") {
              obj.fieldDisplayOrder = 10;
              obj.fieldType = "CheckBoxGroup";
            }
            formArray.add(obj);
          }
        }
      });
      APIService(context).getData("role", true).then((resvalue) {
        if (resvalue.length != 5) {
          Map<String, dynamic> res = jsonDecode(resvalue);
          if (!res.containsKey("type")) {
            if (res.containsKey("data")) {
              role = res["data"];
              List<DynamicField> rolefield = formArray
                  .where((element) => element.fieldName == "role")
                  .toList();
              if (rolefield.length != 0) {
                rolefield[0].options = role
                    .map<DropdownMenuItem<String>>((toElement) =>
                        DropdownMenuItem(
                          value: toElement[rolefield[0].optkey.toString()],
                          child:
                              Text(toElement[rolefield[0].optvalue.toString()]),
                        ))
                    .toList();
              }
              getClientList(context,
                  data: {"role": userData.role, "client_id": userData.clientid},
                  callback: (mapdata) {
                clinetArr = mapdata;
                List<DynamicField> rolefield = formArray
                    .where((element) => element.fieldName == "client")
                    .toList();
                List<DynamicField> clientfield = formArray
                    .where((element) => element.fieldName == "client_data")
                    .toList();
                if (rolefield.length != 0) {
                  rolefield[0].lovData = mapdata;
                  rolefield[0].options = mapdata
                      .map<DropdownMenuItem<String>>(
                          (toElement) => DropdownMenuItem(
                                value: toElement["clientid"].toString(),
                                child: Text(toElement["clientname"]),
                              ))
                      .toList();
                }
                if (clientfield.length != 0) {
                  clientfield[0].lovData = mapdata;
                  clientfield[0].options = mapdata
                      .map<DropdownMenuItem<String>>(
                          (toElement) => DropdownMenuItem(
                                value: toElement["clientid"].toString(),
                                child: Text(toElement["clientname"]),
                              ))
                      .toList();
                }
                Future.delayed(Duration(milliseconds: 100)).then((value) {
                  APIService(context).loaderHide();
                  callback();
                });
              });
            }
          }
        }
      });
    });
  }
}
