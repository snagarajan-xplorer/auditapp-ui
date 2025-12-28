import 'dart:convert';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  String selectedYear = "2025";
  String selectedFinancialYear = "FY2025-26";

  // Dynamic financial years from API
  List<Map<String, dynamic>> financialYears = [];
  bool isLoadingYears = true;

  // Map and data variables
  bool loadData = false;
  List<LatLng> indiaBoundary = [];
  final MapController mapController = MapController();
  double currentZoom = 4.0;
  LatLng currentCenter = LatLng(22.9734, 78.6569);
  List<Polygon> polygons = [];
  Map<String, dynamic> stateDataMap = {};

  UserController usercontroller = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    if (usercontroller.userData.role == null) {
      await usercontroller.loadInitData();
    }

    await loadFinancialYears();
    await newloadGeoJson();
    await loadStateWiseData();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadFinancialYears() async {
    bool apiResponseReceived = false;

    usercontroller.getPublisedFinancialYearList(context, callback: (data) {
      apiResponseReceived = true;

      if (data is List && data.isNotEmpty) {
        if (mounted) {
          setState(() {
            financialYears = data.map((item) {
              return {
                "label": item["financial_year"] ??
                    "FY${item["year"]}-${int.parse(item["year"]) + 1}",
                "value": item["year"] ?? "",
                "start_date": item["start_date"] ?? "",
                "end_date": item["end_date"] ?? "",
                "audit_count": item["audit_count"] ?? 0,
              };
            }).toList();

            if (financialYears.isNotEmpty) {
              selectedFinancialYear = financialYears[0]["label"];
              selectedYear = financialYears[0]["value"];
            }

            isLoadingYears = false;
          });
        }
      } else {
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

  Future<void> loadStateWiseData() async {
    // Always use FY format for year
    String fyValue = selectedFinancialYear; // already in FY format

    var map = {
      "financial_year": fyValue, // use correct key and format
      "userid": usercontroller.userData.userId,
      "role": usercontroller.userData.role
    };

    usercontroller.getAllIndiaStateWiseAudit(context, data: map,
        callback: (data) async {
      stateDataMap = {};

      if (data is List) {
        for (var item in data) {
          String stateName = item["name"] ??
              item["state"] ??
              item["state_name"] ??
              item["stateName"] ??
              "";

          if (stateName.isNotEmpty) {
            dynamic scoreValue = item["score"] ??
                item["risk_score"] ??
                item["riskScore"] ??
                item["compliance_score"];

            int score = -1;
            if (scoreValue != null) {
              if (scoreValue is int) {
                score = scoreValue;
              } else if (scoreValue is String) {
                score = int.tryParse(scoreValue) ?? -1;
              } else if (scoreValue is double) {
                score = scoreValue.toInt();
              }
            }

            stateDataMap[stateName] = {"score": score, "data": item};
          }
        }
      }

      await newloadGeoJson();

      if (mounted) {
        setState(() {});
      }
    });
  }

  Color _getColorForScore(int score) {
    if (score == 0) {
      return Color(0xFFF54234);
    } else if (score == 1) {
      return Color(0xFFFFB552);
    } else if (score == 2) {
      return Color(0xFFFFFD55);
    } else if (score == 3) {
      return Color(0xFFA4DD5B);
    } else if (score == 4) {
      return Color(0xFF5DC2FF);
    } else {
      return Color(0xFFD1D1D1);
    }
  }

  String _normalizeStateName(String name) {
    String normalized = name.trim().toLowerCase();

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

    if (replacements.containsKey(normalized)) {
      return replacements[normalized]!;
    }

    return normalized;
  }

  Future<void> newloadGeoJson() async {
    final data = await rootBundle.loadString('assets/json/india.geojson');
    final geo = jsonDecode(data);

    List<Polygon> loadedPolygons = [];

    for (var feature in geo["features"]) {
      final geometry = feature["geometry"];
      final properties = feature["properties"];
      String stateName = properties["st_nm"] ?? "";

      Color fillColor = _getColorForScore(-1);

      if (stateDataMap.containsKey(stateName)) {
        int score = stateDataMap[stateName]["score"] ?? -1;
        fillColor = _getColorForScore(score);
      } else {
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
      } else if (geometry["type"] == "MultiPolygon") {
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
        }
      }
    }

    if (mounted) {
      setState(() {
        polygons = loadedPolygons;
        if (indiaBoundary.isEmpty && loadedPolygons.isNotEmpty) {
          for (var polygon in loadedPolygons) {
            indiaBoundary.addAll(polygon.points);
          }
        }
      });

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

  List<LatLng> _convertCoords(List coords) {
    return coords
        .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
        .toList();
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
            // Title Section with Dropdown
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "See the Risk. Strengthen the Control",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF898989),
                        ),
                      ),
                      // Financial Year Dropdown
                      isLoadingYears
                          ? CircularProgressIndicator()
                          : _buildFinancialYearDropdown(),
                    ],
                  ),
                ],
              ),
            ),

            // India Map Container
            BoxContainer(
              width: double.infinity,
              height: 500,
              padding: 0,
              isBGTransparent: true,
              child: polygons.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: currentCenter,
                            initialZoom: currentZoom,
                            minZoom: 4.0,
                            maxZoom: 8.0,
                            onPositionChanged:
                                (MapCamera camera, bool hasGesture) {
                              // Update current zoom/center when user interacts with the map
                              setState(() {
                                currentZoom = camera.zoom;
                                currentCenter = camera.center;
                              });
                            },
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            if (polygons.isNotEmpty)
                              PolygonLayer(
                                polygons: polygons,
                              ),
                          ],
                        ),

                        // Legend overlay (bottom-right)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _buildLegendOverlay(),
                        ),

                        // Zoom controls (top-right)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: _buildZoomControls(),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendOverlay() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFC9C9C9), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 150,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Text(
                      "Color Badge",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF08284E),
                      ),
                    ),
                  ),
                  Container(
                    width: 0,
                    height: 40,
                    color: Color(0xFFC9C9C9),
                  ),
                  Container(
                    width: 70,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: Text(
                      "Score",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF08284E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            _buildLegendRow("Not Complied (NC)", Color(0xFFF54234), "0"),
            _buildLegendRow("NC High", Color(0xFFFFB552), "1"),
            _buildLegendRow("NC Medium", Color(0xFFFFFD55), "2"),
            _buildLegendRow("NC Low", Color(0xFFA4DD5B), "3"),
            _buildLegendRow("Complied", Color(0xFF5DC2FF), "4"),
            _buildLegendRow("Not Applicable", Color(0xFFD1D1D1), "N/A",
                isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 3,
          child: InkWell(
            onTap: () => _zoomIn(),
            child: Container(
              width: 40,
              height: 40,
              child: Icon(Icons.add, size: 20, color: Color(0xFF505050)),
            ),
          ),
        ),
        SizedBox(height: 8),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 3,
          child: InkWell(
            onTap: () => _zoomOut(),
            child: Container(
              width: 40,
              height: 40,
              child: Icon(Icons.remove, size: 20, color: Color(0xFF505050)),
            ),
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    double newZoom = (currentZoom + 1).clamp(1.0, 18.0);
    setState(() {
      currentZoom = newZoom;
    });
    try {
      mapController.move(currentCenter, currentZoom);
    } catch (e) {
      // ignore if move not available for mapController version
    }
  }

  void _zoomOut() {
    double newZoom = (currentZoom - 1).clamp(1.0, 18.0);
    setState(() {
      currentZoom = newZoom;
    });
    try {
      mapController.move(currentCenter, currentZoom);
    } catch (e) {
      // ignore if move not available for mapController version
    }
  }

  Widget _buildLegendRow(String label, Color color, String score,
      {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        borderRadius: isLast
            ? BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: isLast
                  ? BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    )
                  : BorderRadius.zero,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 0,
            height: 20,
            color: Color(0xFFC9C9C9),
          ),
          Container(
            width: 70,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: isLast
                  ? BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    )
                  : BorderRadius.zero,
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFC9C9C9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selectedFinancialYear,
            underline: SizedBox(),
            icon:
                Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
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
