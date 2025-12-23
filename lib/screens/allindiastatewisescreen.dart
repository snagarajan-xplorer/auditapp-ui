import 'dart:convert';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/reportobj.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'main/layoutscreen.dart';
import 'package:flutter_map/flutter_map.dart';
import '../constants.dart';

class AllIndiaStateWiseScreen extends StatefulWidget {
  const AllIndiaStateWiseScreen({super.key});

  @override
  State<AllIndiaStateWiseScreen> createState() =>
      _AllIndiaStateWiseScreenState();
}

class _AllIndiaStateWiseScreenState extends State<AllIndiaStateWiseScreen>
    with SingleTickerProviderStateMixin {
  String selectedState = "All";
  String selectedZone = "South";
  String selectedYear = "2025"; // Default to year value
  String selectedFinancialYear = "FY2025-26"; // Default to financial year label

  final List<String> states = [
    "All",
    "Karnataka",
    "Tamilnadu",
    "Gujarat",
    "Andhra Pradesh",
    "Telangana",
    "Delhi"
  ];
  final List<String> zones = ["All", "North", "South", "East", "West"];

  // Dynamic financial years from API
  List<Map<String, dynamic>> financialYears = [];
  bool isLoadingYears = true;

  // Map and data variables
  List<Map<String, dynamic>> heatreportList = [];
  List<Polygon> mapPoints = [];
  String zone = "All";
  String year = Jiffy.now().year.toString();
  bool loadData = false;
  List<LatLng> indiaBoundary = [];
  final MapController mapController = MapController();
  List<Polygon> polygons = [];
  Map<String, dynamic> stateDataMap = {}; // Store state-wise data from API
  Map<String, LatLng> stateCenters = {}; // Store state center points for labels
  Map<String, Map<String, dynamic>> stateBoundingBoxes = {}; // Store bounding boxes for text rotation

  // User and data variables
  UserController usercontroller = Get.put(UserController());
  List<dynamic> clientArr = [];
  List<dynamic> allAuditList = [];
  List<Map<String, dynamic>> dataArr = [];
  List<ReportObj> reportList = [];
  List<dynamic> pieChart = [];
  List<Map<String, dynamic>> auditList = [];
  String client_id = "";
  String id = "";
  num total = 0;
  num totalpercentage = 0;
  List<String> heading = ["Zone", "State", "No of SMOs"];
  List<DataRow> rows = [];
  dynamic dataObj = {
    "complete": 0,
    "incomplete": 0,
    "upcoming": 0,
    "cancel": 0
  };

  @override
  void initState() {
    super.initState();
    // Load GeoJSON first without state data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    if (usercontroller.userData.role == null) {
      await usercontroller.loadInitData();
    }
    // Fetch financial years first
    await loadFinancialYears();

    // First load the GeoJSON
    await newloadGeoJson();

    // Then load client list and other data
    usercontroller.getClientList(context, data: {
      "role": usercontroller.userData.role,
      "client_id": usercontroller.userData.clientid
    }, callback: (res) async {
      clientArr = res;
      allAuditList = [];
      dataArr = [];
      reportList = [];
      pieChart = [];
      auditList = [];
      loadData = true;
      if (menuAccessRole.indexOf(usercontroller.userData.role!) != -1) {
        if (clientArr.length != 0) {
          client_id = clientArr[0]["clientid"].toString();
          await getClientReport(client_id);
        }
      } else if (usercontroller.userData.role! == "JrA") {
        List<String> arr =
        usercontroller.userData.clientid.toString().split(",");
        client_id = arr[0];
        await getClientReport(client_id);
      } else {
        client_id = usercontroller.userData.clientid![0];
        await getClientReport(client_id);
      }

      // Load state-wise data after everything else is ready
      await loadStateWiseData();

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadFinancialYears() async {
    // Set a timeout to ensure loading state is cleared
    bool apiResponseReceived = false;

    usercontroller.getPublisedFinancialYearList(context, callback: (data) {
      apiResponseReceived = true;

      if (data is List && data.isNotEmpty) {
        if (mounted) {
          setState(() {
            financialYears = data.map((item) {
              return {
                "label": item["financial_year"] ?? "FY${item["year"]}-${int.parse(item["year"]) + 1}",
                "value": item["year"] ?? "",
                "start_date": item["start_date"] ?? "",
                "end_date": item["end_date"] ?? "",
                "audit_count": item["audit_count"] ?? 0,
              };
            }).toList();

            // Set default selected year to the first item
            if (financialYears.isNotEmpty) {
              selectedFinancialYear = financialYears[0]["label"];
              selectedYear = financialYears[0]["value"];
            }

            isLoadingYears = false;
          });
        }
      } else {
        // Fallback to default if API returns empty data
        if (mounted) {
          setState(() {
            financialYears = [
              {"label": "FY2025-26", "value": "2025", "audit_count": 0},
              {"label": "FY2024-25", "value": "2024", "audit_count": 0},
              {"label": "FY2023-24", "value": "2023", "audit_count": 0},
            ];
            selectedFinancialYear = financialYears[0]["label"];
            selectedYear = financialYears[0]["value"];
            isLoadingYears = false;
          });
        }
      }
    });

    // Wait for 3 seconds, if no response, use fallback
    await Future.delayed(Duration(seconds: 3));

    if (!apiResponseReceived && mounted) {
      setState(() {
        financialYears = [
          {"label": "FY2025-26", "value": "2025", "audit_count": 0},
          {"label": "FY2024-25", "value": "2024", "audit_count": 0},
          {"label": "FY2023-24", "value": "2023", "audit_count": 0},
        ];
        selectedFinancialYear = financialYears[0]["label"];
        selectedYear = financialYears[0]["value"];
        isLoadingYears = false;
      });
    }
  }

  Future<void> getClientReport(String clientid) async {
    if (clientArr.length != 0) {
      id = clientArr[0]["clientname"];
      dataArr = [];
      reportList = [];
      pieChart = [];
      auditList = [];
      allAuditList = [];
      var map = {
        "client_id": clientid,
        "year": year,
        "zone": zone,
        "userid": usercontroller.userData.userId,
        "role": usercontroller.userData.role
      };
      if (menuAccessRoleAdmin.indexOf(usercontroller.userData.role!) != -1) {
        map = {
          "client_id": clientid,
          "year": year,
          "zone": zone,
          "userid": usercontroller.userData.userId,
          "role": usercontroller.userData.role
        };
      }
      usercontroller.getClientHeatReport(context, data: map,
          callback: (mapdata) {
        mapdata.forEach((key, value) {
          total = total + value.length;
          getChildObj(key, value, "state");
          setState(() {});
        });
        setState(() {});
        rows = [];
        String perStr = (100 / totalpercentage).toStringAsFixed(2);
        double per = double.tryParse(perStr) ?? 1;
        if (reportList.isNotEmpty && reportList[0].children != null) {
          reportList[0].children!.forEach((obj) {
            if (heading.indexOf(obj.key!) == -1) {
              heading.add(obj.key!);
            }
          });
        }
        setState(() {});
      });
    }
  }

  Future<void> loadStateWiseData() async {
    // Use the year value directly (e.g., "2025")
    String yearValue = selectedYear;

    var map = {
      "year": yearValue,
      "userid": usercontroller.userData.userId,
      "role": usercontroller.userData.role
    };

    usercontroller.getAllIndiaStateWiseAudit(context, data: map, callback: (data) async {
      stateDataMap = {};

      if (data is List) {
        for (var item in data) {

          // Try different possible field names for state
          String stateName = item["name"] ?? item["state"] ?? item["state_name"] ?? item["stateName"] ?? "";

          if (stateName.isNotEmpty) {
            // Try different possible field names for score
            dynamic scoreValue = item["score"] ?? item["risk_score"] ?? item["riskScore"] ?? item["compliance_score"];

            int score = -1; // Default to N/A (-1) instead of 0
            if (scoreValue != null) {
              if (scoreValue is int) {
                score = scoreValue;
              } else if (scoreValue is String) {
                score = int.tryParse(scoreValue) ?? -1;
              } else if (scoreValue is double) {
                score = scoreValue.toInt();
              }
            }

            stateDataMap[stateName] = {
              "score": score,
              "data": item
            };
          }
        }
      }
      // Reload GeoJSON with new colors
      await newloadGeoJson();

      // Trigger UI update after loading new data
      if (mounted) {
        setState(() {});
      }
    });
  }

  Color _getColorForScore(int score) {
    // Based on the API legend with exact color specifications:
    // 0 = Not Complied (NC) / #F54234 - <20%
    // 1 = NC High / #FFB552 - 20-49%
    // 2 = NC Medium / #FFFD55 - 50-74%
    // 3 = NC Low / #A4DD5B - 75-99%
    // 4 = Complied / #5DC2FF - 100%
    // null/-1 = Not Applicable / #D1D1D1

    if (score == 0) {
      return Color(0xFFF54234); // Red - Not Complied
    } else if (score == 1) {
      return Color(0xFFFFB552); // Orange - NC High
    } else if (score == 2) {
      return Color(0xFFFFFFD55); // Yellow - NC Medium
    } else if (score == 3) {
      return Color(0xFFA4DD5B); // Light Green - NC Low
    } else if (score == 4) {
      return Color(0xFF5DC2FF); // Light Blue - Complied
    } else {
      return Color(0xFFD1D1D1); // Light Gray - Not Applicable
    }
  }

  String _normalizeStateName(String name) {
    // Normalize state names to handle variations
    String normalized = name.trim().toLowerCase();

    // Common replacements
    Map<String, String> replacements = {
      'andaman and nico.in.': 'andaman and nicobar',
      'andaman and nicobar islands': 'andaman and nicobar',
      'arunanchal pradesh': 'arunachal pradesh',
      'chattisgarh': 'chhattisgarh',
      'dadra and nagar hav.': 'dadra and nagar haveli',
      'dadra & nagar haveli': 'dadra and nagar haveli',
      'megalaya': 'meghalaya',
      'pondicherry': 'puducherry',
      'orissa': 'odisha',
      'jammu & kashmir': 'jammu and kashmir',
      'bijapur(kar)': 'karnataka',
    };

    // Check if there's a direct replacement
    if (replacements.containsKey(normalized)) {
      return replacements[normalized]!;
    }

    return normalized;
  }

  Map<int, int> _getScoreCounts() {
    Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, -1: 0}; // -1 for N/A

    stateDataMap.forEach((state, data) {
      int score = data["score"] ?? -1;
      if (counts.containsKey(score)) {
        counts[score] = (counts[score] ?? 0) + 1;
      } else {
        counts[-1] = (counts[-1] ?? 0) + 1; // N/A
      }
    });

    return counts;
  }

  Future<void> newloadGeoJson() async {
    final data = await rootBundle.loadString('assets/json/india.geojson');
    final geo = jsonDecode(data);

    List<Polygon> loadedPolygons = [];
    Map<String, LatLng> centers = {};
    Map<String, Map<String, dynamic>> boundingBoxes = {};
    for (var feature in geo["features"]) {
      final geometry = feature["geometry"];

      final properties = feature["properties"];
      String stateName = properties["st_nm"] ?? "";

      // Get color from stateDataMap or use default white
      Color fillColor = Colors.white;

      // Try exact match first
      if (stateDataMap.containsKey(stateName)) {
        int score = stateDataMap[stateName]["score"] ?? -1;
        fillColor = _getColorForScore(score);
      } else {
        // Try normalized name matching
        String normalizedGeoJsonName = _normalizeStateName(stateName);
        String? matchedKey;

        for (var key in stateDataMap.keys) {
          String normalizedApiName = _normalizeStateName(key);
          if (normalizedApiName == normalizedGeoJsonName) {
            matchedKey = key;
            break;
          }
        }

        if (matchedKey != null) {
          int score = stateDataMap[matchedKey]["score"] ?? -1;
          fillColor = _getColorForScore(score);
        }
      }

      if (geometry["type"] == "Polygon") {
        List<LatLng> points = _convertCoords(geometry["coordinates"][0]);
        loadedPolygons.add(
          Polygon(
            points: points,
            color: fillColor,
            borderStrokeWidth: 1,
            borderColor: Colors.grey.shade700,
          ),
        );

        // Calculate center point and bounding box for label (only if not already stored)
        if (!centers.containsKey(stateName)) {
          centers[stateName] = _calculatePolygonCenter(points);
          boundingBoxes[stateName] = _calculateBoundingBox(points);
        }
      } else if (geometry["type"] == "MultiPolygon") {
        List<LatLng> allPoints = [];
        for (var polygon in geometry["coordinates"]) {
          List<LatLng> points = _convertCoords(polygon[0]);
          loadedPolygons.add(
            Polygon(
              points: points,
              color: fillColor,
              borderStrokeWidth: 1,
              borderColor: Colors.grey.shade700,
            ),
          );
          allPoints.addAll(points);
        }

        // Calculate center point and bounding box from all polygons (only if not already stored)
        if (!centers.containsKey(stateName)) {
          centers[stateName] = _calculatePolygonCenter(allPoints);
          boundingBoxes[stateName] = _calculateBoundingBox(allPoints);
        }
      }
    }

    if (mounted) {
      setState(() {
        polygons = loadedPolygons;
        stateCenters = centers;
        stateBoundingBoxes = boundingBoxes;
        if (indiaBoundary.isEmpty && loadedPolygons.isNotEmpty) {
          // Build boundary from all polygon points
          for (var polygon in loadedPolygons) {
            indiaBoundary.addAll(polygon.points);
          }
        }
      });

      // Fit camera after setState completes
      if (indiaBoundary.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(indiaBoundary),
                padding: const EdgeInsets.all(20),
              ),
            );
          } catch (e) {
            print("Error fitting camera: $e");
          }
        });
      }
    }
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);

    double lat = 0;
    double lng = 0;

    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  Map<String, dynamic> _calculateBoundingBox(List<LatLng> points) {
    if (points.isEmpty) {
      return {"width": 0.0, "height": 0.0, "aspectRatio": 1.0};
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    double width = maxLng - minLng;
    double height = maxLat - minLat;
    double aspectRatio = width / (height == 0 ? 1 : height);

    return {
      "width": width,
      "height": height,
      "aspectRatio": aspectRatio,
      "minLat": minLat,
      "maxLat": maxLat,
      "minLng": minLng,
      "maxLng": maxLng,
    };
  }

  List<LatLng> _convertCoords(List coords) {
    return coords
        .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
        .toList();
  }

  getChildObj(String zone, List<dynamic> arr, String key) {
    double scoredvalue = 0;
    double totalvalue = 0;
    int percentage = 0;
    arr.forEach((element) {
      double scoredvalue2 = 0;
      double totalvalue2 = 0;
      int percentage2 = 0;
      List<ReportObj> robj = reportList
          .where((_element) =>
              _element.state == element[key] &&
              _element.zone == element["zone"])
          .toList();
      ReportObj obj = ReportObj();
      if (robj.length == 0) {
        scoredvalue = 0;
        totalvalue = 0;
        percentage = 0;
        element["isRed"] = false;
        obj.state = element["state"];
        obj.zone = element["zone"];
        obj.city = element["city"];
        obj.auditname = element["auditname"];
        List<dynamic> darr =
            arr.where((ele) => ele["state"] == element["state"]).toList();
        obj.length = darr.length;
        obj.children = [];
        element["category"].forEach((eleobj) {
          double scored =
              double.tryParse(eleobj["totalAnswer"].toString()) ?? 0;
          double total =
              double.tryParse(eleobj["questionlength"].toString()) ?? 0;
          scoredvalue = scoredvalue + scored;
          totalvalue = totalvalue + total;
          percentage = (scoredvalue / totalvalue).round();
          scoredvalue2 = scoredvalue2 + scored;
          totalvalue2 = totalvalue2 + total;
          percentage2 = ((scoredvalue2 / totalvalue2)).round();
          obj.score = scoredvalue;
          obj.total = totalvalue;
          obj.percentage = percentage;
          int per = ((scored / (total * 4)) * 100).round();
          if (per < 26) {
            element["isRed"] = true;
          }
          Children child = Children(
              key: eleobj["heading"],
              scorevalue: scored,
              totalvalue: total,
              value: percentage);
          obj.children!.add(child);
        });
        reportList.add(obj);
      } else {
        obj = robj[0];
        if (element["state"] == obj.state) {
          element["category"].forEach((eleobj) {
            double scored =
                double.tryParse(eleobj["totalAnswer"].toString()) ?? 0;
            double total =
                double.tryParse(eleobj["questionlength"].toString()) ?? 0;
            List<Children> child =
                obj.children!.where((k) => k.key == eleobj["heading"]).toList();
            int scoreVal = (scored / total).round();
            scoredvalue = obj.score! + scored;
            totalvalue = obj.total! + total;
            percentage = (scoredvalue / totalvalue).round();

            obj.score = scoredvalue;
            obj.total = totalvalue;
            obj.percentage = percentage;
            scoredvalue2 = scoredvalue2 + scored;
            totalvalue2 = totalvalue2 + total;
            percentage2 = ((scoredvalue2 / totalvalue2)).round();
            int per = ((scored / (total * 4)) * 100).round();
            if (per < 26) {
              element["isRed"] = true;
            }
            if (child.length == 0) {
              Children child2 = Children(
                  key: eleobj["heading"],
                  scorevalue: scored,
                  totalvalue: total,
                  value: scoreVal);
              obj.children!.add(child2);
            } else {
              child[0].scorevalue = child[0].scorevalue! + scored;
              child[0].totalvalue = child[0].totalvalue! + total;
              int rounded =
                  ((child[0].scorevalue! / child[0].totalvalue!)).round();
              child[0].value = rounded;
            }
          });
        }
      }
      if (element["isRed"] == false) {
        element["percentage"] = percentage2;
      } else {
        element["percentage"] = 0;
      }
      var m = ((scoredvalue2 / (totalvalue2 * 4)) * 100).round();
      String img = "assets/images/low.png";
      if (m! > 75 && m! < 99) {
        img = "assets/images/green.png";
      } else if (m! > 49 && m! < 75) {
        img = "assets/images/medium.png";
      } else if (m! > 20 && m! < 49) {
        img = "assets/images/high.png";
      } else if (m! < 20) {
        img = "assets/images/extreme.png";
      }
      List<Map<String, dynamic>> colorArr = usercontroller.colorArr
          .where((ele) => ele["value"] == element["percentage"].toString())
          .toList();
      if (colorArr.length != 0) {
        element["color"] = UtilityService().getColorPercentage(m);
        element["svg"] = img;
        element["svgcolor"] = colorArr[0]["svgcolor"];
      }
      allAuditList.add(element);
    });
  }

  DataRow getRow(ReportObj obj) {
    List<DataCell> cell = [];
    var m2 = (obj.score! / (obj.total! * 4) * 100).round();
    List<Map<String, dynamic>> color = usercontroller.scoreArr
        .where((ele) => ele["value"] == obj.percentage.toString())
        .toList();
    DataCell col_01 = DataCell(Center(child: Text(obj.zone!)));
    DataCell col_02 = DataCell(Center(
        child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        color.length == 0
            ? Container()
            : Container(
                width: 8,
                height: 15,
                color: UtilityService().getColorPercentage(m2),
              ),
        SizedBox(
          width: 3,
        ),
        Flexible(
          child: Text(
            obj.state!,
            style: smallTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )));
    DataCell col_03 = DataCell(Center(child: Text(obj.length.toString())));
    cell.add(col_01);
    cell.add(col_02);
    cell.add(col_03);
    obj.children!.forEach((kobj) {
      List<Map<String, dynamic>> arr = usercontroller.scoreArr
          .where((ele) => ele["value"] == kobj.value.toString())
          .toList();
      var m = (kobj.scorevalue! / (kobj.totalvalue! * 4) * 100).round();
      Color color = UtilityService().getColorPercentage(m);

      if (arr.length != 0) {
        DataCell col_04 = DataCell(Container(
          decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade200, width: 1)),
          width: 100,
          child: Center(child: Text("")),
        ));
        cell.add(col_04);
      }
    });
    return DataRow(cells: cell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Container(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Heatmap – All India (State wise)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF505050),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "See the Risk. Strengthen the Control",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF898989),
                    ),
                  ),
                ],
              ),
            ),

            // Dropdown Filter
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              child: Builder(
                builder: (context) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Financial Year Dropdown
                      isLoadingYears
                          ? CircularProgressIndicator()
                          : _buildFinancialYearDropdown(),
                    ],
                  );
                },
              ),
            ),

            // India Map Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: defaultPadding),
              child: BoxContainer(
                width: double.infinity,
                height: 700,
                child: polygons.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(22.9734, 78.6569),
                          initialZoom: 4,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          if (polygons.isNotEmpty)
                            PolygonLayer(
                              polygons: polygons,
                            ),
                        ],
                      ),
              ),
            ),

            // Legend
            Container(
              padding: EdgeInsets.all(defaultPadding),
              child: Builder(
                builder: (context) {
                  Map<int, int> scoreCounts = _getScoreCounts();
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItemWithCount("Not Complied (NC)", Color(0xFFF54234), scoreCounts[0] ?? 0, 0),
                          SizedBox(width: 20),
                          _buildLegendItemWithCount("NC High", Color(0xFFFFB552), scoreCounts[1] ?? 0, 1),
                          SizedBox(width: 20),
                          _buildLegendItemWithCount("NC Medium", Color(0xFFFFFFD55), scoreCounts[2] ?? 0, 2),
                          SizedBox(width: 20),
                          _buildLegendItemWithCount("NC Low", Color(0xFFA4DD5B), scoreCounts[3] ?? 0, 3),
                          SizedBox(width: 20),
                          _buildLegendItemWithCount("Complied", Color(0xFF5DC2FF), scoreCounts[4] ?? 0, 4),
                          SizedBox(width: 20),
                          _buildLegendItemWithCount("Not Applicable", Color(0xFFD1D1D1), scoreCounts[-1] ?? 0, -1),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLegendItemWithCount(String label, Color color, int count, int score) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha((0.7 * 255).toInt()),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF505050),
                ),
              ),
              Text(
                "$count ${count == 1 ? 'state' : 'states'}",
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF898989),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFinancialYearDropdown() {
    // Safety check - if financialYears is empty, return a placeholder
    if (financialYears.isEmpty) {
      return Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFC9C9C9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "No years available",
            style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFC9C9C9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selectedFinancialYear,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF505050),
            ),
            items: financialYears.map((Map<String, dynamic> item) {
              return DropdownMenuItem<String>(
                value: item["label"],
                child: Text(item["label"]),
              );
            }).toList(),
            onChanged: (String? newValue) async {
              if (mounted && newValue != null) {
                // Find the selected item to get the year value
                var selectedItem = financialYears.firstWhere(
                  (item) => item["label"] == newValue,
                  orElse: () => {"label": newValue, "value": "2025"},
                );

                setState(() {
                  selectedFinancialYear = newValue;
                  selectedYear = selectedItem["value"];
                });
                // Load state data with new year
                await loadStateWiseData();
              }
            },
          ),
        ),
      ],
    );
  }
}

