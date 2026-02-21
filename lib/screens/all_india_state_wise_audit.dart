import 'dart:convert';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'main/layoutscreen.dart';
import '../constants.dart';
import 'dart:ui' as ui;

class AllIndiaStateWiseAudit extends StatefulWidget { //all-india-state-audit
  const AllIndiaStateWiseAudit({super.key});

  @override
  State<AllIndiaStateWiseAudit> createState() =>
      _AllIndiaStateWiseAuditState();
}

class _AllIndiaStateWiseAuditState
    extends State<AllIndiaStateWiseAudit> {
  String selectedYear = "2025";
  String selectedFinancialYear = "FY2025-26";

  // Dynamic financial years from API
  List<Map<String, dynamic>> financialYears = [];
  bool isLoadingYears = true;

  // Map and data variables
  GoogleMapController? googleMapController;
  double currentZoom = 4.0;
  LatLng currentCenter = LatLng(22.9734, 78.6569);
  Set<Polygon> polygons = {};
  Set<Marker> markers = {};
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
    // Load state-wise data first; it will render polygons after fetching
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
    // Hardcoded last 5 financial years
    final currentYear = DateTime.now().year;
    financialYears = List.generate(5, (index) {
      final year = currentYear - index;
      final nextYearShort = (year + 1).toString().substring(2);
      final fyValue = "FY$year-$nextYearShort";
      return {
        "label": fyValue,
        "value": fyValue,
      };
    });

    if (mounted) {
      setState(() {
        selectedFinancialYear = financialYears[0]["label"];
        selectedYear = financialYears[0]["value"];
        isLoadingYears = false;
      });
    }
  }

  Future<void> loadStateWiseData() async {
    // Pass financial year in FY format (e.g., FY2025-26)
    final String fyValue = selectedYear; // already in FY format from dropdown

    var map = {
      "financial_year": fyValue,
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
      return Color(0xFFE8E8E8); // Light grey for states without data
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

    Set<Polygon> loadedPolygons = {};
    int polygonIndex = 0;

    // Group all points by state name to create ONE marker per state
    Map<String, List<LatLng>> statePointsMap = {};
    Map<String, dynamic> stateInfoMap = {};

    for (var feature in geo["features"]) {
      final geometry = feature["geometry"];
      final properties = feature["properties"];
      String stateName = properties["st_nm"] ?? "";

      // Skip if state name is empty
      if (stateName.isEmpty) continue;

      Color fillColor = _getColorForScore(-1);
      String? matchedKey;
      dynamic stateData;

      if (stateDataMap.containsKey(stateName)) {
        int score = stateDataMap[stateName]["score"] ?? -1;
        fillColor = _getColorForScore(score);
        matchedKey = stateName;
        stateData = stateDataMap[stateName]["data"];
      } else {
        String normalizedGeoJsonName = _normalizeStateName(stateName);

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
          stateData = stateDataMap[matchedKey]["data"];
        }
      }

      // Store state data for marker creation later
      if (!stateInfoMap.containsKey(stateName)) {
        stateInfoMap[stateName] = stateData;
      }

      // Initialize points list for this state if not exists
      if (!statePointsMap.containsKey(stateName)) {
        statePointsMap[stateName] = [];
      }

      if (geometry["type"] == "Polygon") {
        List<LatLng> points = _convertCoords(geometry["coordinates"][0]);
        statePointsMap[stateName]!.addAll(points);
        loadedPolygons.add(
          Polygon(
            polygonId: PolygonId('polygon_$polygonIndex'),
            points: points,
            fillColor: fillColor,
            strokeColor: Colors.grey,
            strokeWidth: 1,
          ),
        );
        polygonIndex++;
      } else if (geometry["type"] == "MultiPolygon") {
        for (var polygon in geometry["coordinates"]) {
          List<LatLng> points = _convertCoords(polygon[0]);
          statePointsMap[stateName]!.addAll(points);
          loadedPolygons.add(
            Polygon(
              polygonId: PolygonId('polygon_$polygonIndex'),
              points: points,
              fillColor: fillColor,
              strokeColor: Colors.transparent,
              strokeWidth: 1,
            ),
          );
          polygonIndex++;
        }
      }
    }

    // Now create ONE marker per state
    Set<Marker> loadedMarkers = {};
    for (var stateName in statePointsMap.keys) {
      List<LatLng> allPoints = statePointsMap[stateName]!;
      if (allPoints.isEmpty) continue;

      LatLng centroid = _calculateCentroid(allPoints);

      final BitmapDescriptor icon = await _createCustomMarkerBitmap(stateName);

      loadedMarkers.add(
        Marker(
          markerId: MarkerId('marker_$stateName'),
          position: centroid,
          icon: icon,
        ),
      );
    }

    if (mounted) {
      setState(() {
        polygons = loadedPolygons;
        markers = loadedMarkers;
      });
    }
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    double latSum = 0;
    double lngSum = 0;
    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 10.0,
        color: Color(0xFF000000),
        fontWeight: FontWeight.w400,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 1,
            color: Colors.white,
          ),
          Shadow(
            offset: Offset(-1, -1),
            blurRadius: 1,
            color: Colors.white,
          ),
        ],
      ),
    );
    textPainter.layout();

    final double width = textPainter.width + 4;
    final double height = textPainter.height + 4;

    textPainter.paint(canvas, Offset(2, 2));

    final img = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _setMapStyle(GoogleMapController controller) {
    String mapStyle = '''
    [
      {
        "featureType": "all",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "all",
        "elementType": "geometry.stroke",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative",
        "elementType": "all",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative.country",
        "elementType": "geometry.stroke",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [{"color": "#ffffff"}]
      },
      {
        "featureType": "poi",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "road",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative.locality",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative.neighborhood",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative.province",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''';
    controller.setMapStyle(mapStyle);
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
            Container(
              width: double.infinity,
              height: 500,
              child: BoxContainer(
                width: double.infinity,
                height: 500,
                padding: 0,
                isBGTransparent: true,
                child: polygons.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : Material(
                        elevation: 12,
                        shadowColor: Colors.black.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 500,
                                child: GoogleMap(
                                  key: ValueKey('google_map'),
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    googleMapController = controller;
                                   // _setMapStyle(controller);
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: currentCenter,
                                    zoom: currentZoom,
                                  ),
                                  polygons: polygons,
                                  markers: markers,
                                  mapType: MapType.normal,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  zoomGesturesEnabled: true,
                                  minMaxZoomPreference:
                                      MinMaxZoomPreference.unbounded,
                                  cameraTargetBounds: CameraTargetBounds(
                                    LatLngBounds(
                                      southwest: LatLng(6.4, 68.1),
                                      northeast: LatLng(35.5, 97.4),
                                    ),
                                  ),
                                  mapToolbarEnabled: false,
                                  compassEnabled: false,
                                  trafficEnabled: false,
                                  buildingsEnabled: false,
                                  indoorViewEnabled: false,
                                  onCameraMove: (CameraPosition position) {
                                    setState(() {
                                      currentZoom = position.zoom;
                                      currentCenter = position.target;
                                    });
                                  },
                                ),
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
                      ),
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
    double newZoom = (currentZoom + 1).clamp(1.0, 22.0);
    googleMapController?.animateCamera(
      CameraUpdate.zoomTo(newZoom),
    );
  }

  void _zoomOut() {
    double newZoom = (currentZoom - 1).clamp(1.0, 22.0);
    googleMapController?.animateCamera(
      CameraUpdate.zoomTo(newZoom),
    );
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
                  // Label equals value (FYYYYY-YY); fallback uses the label itself
                  orElse: () => {"label": newValue, "value": newValue},
                );

                setState(() {
                  selectedFinancialYear = newValue;
                  // Ensure endpoint receives FY format (e.g., FY2025-26)
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
