import 'dart:ui' as ui;
import 'dart:convert';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';

// Generates a large yellow circle BitmapDescriptor for Google Maps markers
Future<BitmapDescriptor> _getYellowCircleMarkerIcon() async {
  final int size = 22;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint paint = Paint()..color = Color(0xFFF54234);
  final Paint border = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  // Draw yellow circle
  canvas.drawCircle(Offset(size/2, size/2), size/2.2, paint);
  // Draw border
  canvas.drawCircle(Offset(size/2, size/2), size/2.2, border);
  final img = await recorder.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}

class RedReportScreen extends StatefulWidget {
  const RedReportScreen({super.key});

  @override
  State<RedReportScreen> createState() => _RedReportScreenState();
}

class _RedReportScreenState extends State<RedReportScreen>
    with SingleTickerProviderStateMixin {
  String selectedYear = "2025";
  String selectedFinancialYear = "FY2025-26";
  String selectedZone = "All";

  // Dynamic financial years from API
  List<Map<String, dynamic>> financialYears = [];
  List<String> zones = [
    "All",
    "South",
    "North",
    "East",
    "West"
  ];
  bool isLoadingYears = true;

  // Google Map variables
  GoogleMapController? mapController;
  double currentZoom = 4.0;
  LatLng currentCenter = LatLng(22.9734, 78.6569);
  Set<Marker> redMarkers = {};
  Set<Polygon> polygons = {};
  Map<String, dynamic> stateDataMap = {};
  // --- India polygons loading ---
  Future<void> _loadIndiaPolygons() async {
    final data = await DefaultAssetBundle.of(context).loadString('assets/json/india.geojson');
    final geo = jsonDecode(data);
    Set<Polygon> loadedPolygons = {};
    int polygonIndex = 0;
    for (var feature in geo["features"]) {
      final geometry = feature["geometry"];
      final properties = feature["properties"];
      String stateName = properties["st_nm"] ?? "";
      Color fillColor = Colors.transparent; // Transparent fill for better label visibility
      Color strokeColor = Colors.black; // Black stroke for clear state outlines

      if (geometry["type"] == "Polygon") {
        List<LatLng> points = _convertCoords(geometry["coordinates"][0]);
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
      } else if (geometry["type"] == "MultiPolygon") {
        for (var polygon in geometry["coordinates"]) {
          List<LatLng> points = _convertCoords(polygon[0]);
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
    setState(() {
      polygons = loadedPolygons;
    });
  }

  List<LatLng> _convertCoords(List coords) {
    return coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
  }

  UserController usercontroller = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadIndiaPolygons();
      await _initializeScreen();
      _addStateMarkers();
    });
  }

  void _addStateMarkers() {
    if (stateDataMap.isEmpty) {
      print("State data map is empty. Cannot add state markers.");
      return;
    }

    Set<Marker> tempMarkers = {};
    stateDataMap.forEach((stateName, coordinates) {
      try {
        double lat = double.parse(coordinates["latitude"].toString());
        double lng = double.parse(coordinates["longitude"].toString());
        tempMarkers.add(
          Marker(
            markerId: MarkerId(stateName),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: stateName,
            ),
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      } catch (e) {
        print("Error adding marker for state $stateName: $e");
      }
    });

    setState(() {
      redMarkers.addAll(tempMarkers);
    });
  }

  Future<void> _initializeScreen() async {
    if (usercontroller.userData.role == null) {
      await usercontroller.loadInitData();
    }

    await loadFinancialYears();
    await loadStateWiseData();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadFinancialYears() async {
    // Always show last 5 financial years in FY format, like dashboard_screen.dart
    final currentYear = DateTime.now().year;
    financialYears = List.generate(5, (index) {
      final year = currentYear - index;
      final nextYearShort = (year + 1).toString().substring(2);
      final fyValue = "FY$year-$nextYearShort";
      return {"label": fyValue, "value": fyValue};
    });
    setState(() {
      selectedFinancialYear = financialYears[0]["value"];
      selectedYear = financialYears[0]["value"];
      isLoadingYears = false;
    });
  }

  Future<void> loadStateWiseData() async {
    // Always use FY format for year
    String fyValue = selectedFinancialYear; // already in FY format
    String zoneValue = selectedZone;

    var map = {
      "financial_year": fyValue, // use correct key and format
      "zone": zoneValue,
      "userid": usercontroller.userData.userId,
      "role": usercontroller.userData.role
    };

    usercontroller.getZoneWiseNCAudit(context, data: map,
        callback: (data) async {
      stateDataMap = {};
      Set<Marker> tempMarkers = {};

      // Handle the actual API response structure
      if (data is Map && data.containsKey('map_data')) {
        var mapData = data['map_data'];
        if (mapData is List) {
          for (var item in mapData) {
            if (item is Map && item.containsKey('location')) {
              var location = item['location'];
              if (location is Map && location.containsKey('latitude') && location.containsKey('longitude')) {
                try {
                  double lat = double.parse(location['latitude'].toString());
                  double lng = double.parse(location['longitude'].toString());
                  final icon = await _getYellowCircleMarkerIcon();
                  tempMarkers.add(
                    Marker(
                      markerId: MarkerId('marker_${item['audit_id']}_${lat}_$lng'),
                      position: LatLng(lat, lng),
                      icon: icon,
                      infoWindow: InfoWindow(
                        title: item['audit_name'] ?? 'Unknown Audit',
                        snippet: '${item['city'] ?? ''}, ${item['branch'] ?? ''}',
                      ),
                    ),
                  );
                } catch (e) {
                  print("Error parsing coordinates: $e");
                }
              }
            }
          }
        }
      }

      redMarkers = tempMarkers;
      setState(() {});
    });
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

  void _zoomIn() {
    double newZoom = (currentZoom + 1).clamp(1.0, 22.0);
    mapController?.animateCamera(
      CameraUpdate.zoomTo(newZoom),
    );
  }

  void _zoomOut() {
    double newZoom = (currentZoom - 1).clamp(1.0, 22.0);
    mapController?.animateCamera(
      CameraUpdate.zoomTo(newZoom),
    );
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
                    "Red Report Audit",
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
                      // Financial Year and Zone Dropdowns
                      Row(
                        children: [
                          _buildZoneDropdown(),
                          SizedBox(width: 12),
                          isLoadingYears
                              ? CircularProgressIndicator()
                              : _buildFinancialYearDropdown(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map Container
            Container(
              width: double.infinity,
              height: 500,
              child: BoxContainer(
                width: double.infinity,
                height: 500,
                padding: 0,
                isBGTransparent: true,
                child: (redMarkers.isEmpty && polygons.isEmpty)
                    ? Center(child: CircularProgressIndicator())
                    : Material(
                        elevation: 12,
                        shadowColor: Colors.black.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Container(
                            color: Color(0xFFC9C9C9), 
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 500,
                                  child: GoogleMap(
                                    key: ValueKey('google_map'),
                                    onMapCreated:
                                        (GoogleMapController controller) {
                                      mapController = controller;
                                     // _setMapStyle(controller);
                                    },
                                    initialCameraPosition: CameraPosition(
                                      target: currentCenter,
                                      zoom: currentZoom,
                                    ),
                                    polygons: polygons,
                                    markers: redMarkers,
                                    mapType: MapType.normal,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    zoomGesturesEnabled: true,
                                    minMaxZoomPreference:
                                        MinMaxZoomPreference(4.0, 20.0),
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
            ),

            SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialYearDropdown() {
    if (financialYears.isEmpty) {
      return Container();
    }
    return Container(
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
        icon: Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF505050),
        ),
        items: financialYears.map((Map<String, dynamic> item) {
          return DropdownMenuItem<String>(
            value: item["value"],
            child: Text(item["label"]),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (mounted && newValue != null) {
            setState(() {
              selectedFinancialYear = newValue;
              selectedYear = newValue;
            });
            await loadStateWiseData();
          }
        },
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFC9C9C9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedZone,
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF505050),
        ),
        items: zones.map((String zone) {
          return DropdownMenuItem<String>(
            value: zone,
            child: Text(zone),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (mounted && newValue != null) {
            setState(() {
              selectedZone = newValue;
            });
            // Load state data with new zone
            await loadStateWiseData();
          }
        },
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
}
