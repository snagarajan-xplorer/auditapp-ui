import 'dart:convert';
import 'dart:math';
import 'package:audit_app/models/reportobj.dart';
import '../main/layoutscreen.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/usercontroller.dart';
import '../../localization/app_translations.dart';
import '../../models/my_files.dart';
import './../../responsive.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> clientArr = [];
  List<dynamic> pieChart = [];
  List<LatLng> latandlong = [];
  List<dynamic> allAuditList = [];
  num totalpercentage = 0;
  List<Map<String, dynamic>> dataArr = [];
  String id = "";
  String client_id = "";
  dynamic dataObj = {
    "complete": 0,
    "incomplete": 0,
    "upcoming": 0,
    "cancel": 0
  };
  List<Map<String, dynamic>> auditList = [];
  List<Map<String, dynamic>> fieldArr = [
    {"type": "string", "key": "auditname"},
    {"type": "string", "key": "companyname"},
    {"type": "string", "key": "start_date"},
    {"type": "string", "key": "statusvalue"}
  ];
  bool showHeatmap = false;
  num total = 0;
  List<String> heading = ["Zone", "State", "No of SMOs"];
  List<DataRow> rows = [];
  List<ReportObj> reportList = [];
  List<Map<String, dynamic>> heatreportList = [];
  UserController usercontroller = Get.put(UserController());
  List<Polygon> mapPoints = [];
  String zone = "All";
  String year = Jiffy.now().year.toString();
  bool loadData = false;
  List<LatLng> indiaBoundary = [];
  final MapController mapController = MapController();
  List<Polygon> polygons = [];

  // Financial years dropdown
  List<Map<String, dynamic>> financialYears = [];
  String selectedFinancialYear = "";

  @override
  void initState() {
    super.initState();

    // Initialize financial years
    final currentYear = DateTime.now().year;
    financialYears = List.generate(5, (index) {
      final y = currentYear - index;
      final nextYearShort = (y + 1).toString().substring(2);
      final fyValue = "FY$y-$nextYearShort";
      return {"label": fyValue, "value": fyValue};
    });
    selectedFinancialYear = financialYears[0]["value"];
    year = selectedFinancialYear; // Use FY format directly

    Future.delayed(Duration(milliseconds: 200)).then((onValue) async {
      newloadGeoJson();
      if (usercontroller.userData.role == null) {
        usercontroller.loadInitData();
      }
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
        // usercontroller.getOverAllReport(context, callback:(resArr){
        //   if(resArr.containsKey("data")){
        //     pieChart = resArr["data"];
        //     pieChart.forEach((element){
        //       totalpercentage = totalpercentage + (num.tryParse(element["percentage"].toString()) ?? 0);
        //     });
        //   }
        // });
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
        setState(() {});
      });
    });
  }


  Future<void> newloadGeoJson() async {
    final data = await rootBundle.loadString('assets/json/india.geojson');
    final geo = jsonDecode(data);

    List<Polygon> loadedPolygons = [];

    for (var feature in geo["features"]) {
      final geometry = feature["geometry"];
      if (geometry["type"] == "Polygon") {
        loadedPolygons.add(
          Polygon(
            points: _convertCoords(geometry["coordinates"][0]),
            color: Color(0xFFD1D1D1), // Use Not Applicable gray instead of white
            borderStrokeWidth: 1.5,
            borderColor: Colors.grey,
          ),
        );
      } else if (geometry["type"] == "MultiPolygon") {
        for (var polygon in geometry["coordinates"]) {
          loadedPolygons.add(
            Polygon(
              points: _convertCoords(polygon[0]),
              color: Color(0xFFD1D1D1), // Use Not Applicable gray instead of white
              borderStrokeWidth: 1.5,
              borderColor: Colors.transparent,
            ),
          );
        }
      }
    }

    setState(() {
      polygons = loadedPolygons;
      if (indiaBoundary.isNotEmpty) {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(indiaBoundary),
            padding: const EdgeInsets.all(20),
          ),
        );
      }
    });
  }

  List<LatLng> _convertCoords(List coords) {
    return coords
        .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
        .toList();
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
        double.tryParse(perStr) ?? 1;
        reportList[0].children!.forEach((obj) {
          if (heading.indexOf(obj.key!) == -1) {
            heading.add(obj.key!);
          }
        });
        usercontroller.getAuditCount(context, data: map, callback: (countobj) {
          dataObj = countobj;

          usercontroller.countList = [
            CloudStorageInfo(
              title: countobj["complete"].toString(),
              numOfFiles: 1328,
              path: "P",
              svgSrc: "assets/icons/Documents.svg",
              totalStorage: "Published Audit",
              color: Colors.green,
              percentage: 100,
            ),
            CloudStorageInfo(
              title: countobj["incomplete"].toString(),
              numOfFiles: 1328,
              path: "IP",
              svgSrc: "assets/icons/google_drive.svg",
              totalStorage: "In Progress Audit",
              color: Colors.deepOrange,
              percentage: 100,
            ),
            CloudStorageInfo(
              title: countobj["upcoming"].toString(),
              numOfFiles: 1328,
              path: "S",
              svgSrc: "assets/icons/one_drive.svg",
              totalStorage: "Up Coming Audit",
              color: Colors.blueAccent,
              percentage: 100,
            ),
            CloudStorageInfo(
              title: countobj["cancel"].toString(),
              numOfFiles: 5328,
              path: "CL",
              svgSrc: "assets/icons/drop_box.svg",
              totalStorage: "Cancelled Audit",
              color: Colors.grey.shade700,
              percentage: 100,
            ),
          ];
          setState(() {});
          Future.delayed(Duration(milliseconds: 400)).then((_) {
            showHeatmap = true;
            setState(() {});
          });
        });

        /*
        usercontroller.getAuditList(context, data: {"userid":usercontroller.userData.userId,"role":usercontroller.userData.role,"client":clientid,"year":Jiffy.now().year.toString(),"month":Jiffy.now().month.toString()}, callback: (auditArr){
          List<dynamic> arrList = auditArr;
          arrList.forEach((ele){
            Map<String,dynamic> _element = Map.of(ele);
            if(_element.containsKey("start_date")){
              _element["start_date"] = Jiffy.parse(_element["start_date"].toString()).format(pattern: "dd/MM/yyyy");
            }
            if(_element.containsKey("status")){
              String status = "";
              if(_element["status"] == "IP"){
                status = AppTranslations.of(context)!.text("key_progress");
              }else if(_element["status"] == "PG"){
                status = AppTranslations.of(context)!.text("key_progress");
              }else if(_element["status"] == "C"){
                if(usercontroller.userData.role == "CL"){
                  status = AppTranslations.of(context)!.text("key_complete");
                }else{
                  status = AppTranslations.of(context)!.text("key_complete");
                }
              }else if(_element["status"] == "S"){
                status = AppTranslations.of(context)!.text("key_create");
              }else if(_element["status"] == "P"){
                status = AppTranslations.of(context)!.text("key_publish");
              }
              _element["statusvalue"] = status;
            }

            auditList.add(_element);
          });
        });
         */
      });
    }
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
    //DataCell col_02 = DataCell(Center(child: Text(obj.state!)));
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
    DataRow row = DataRow(cells: cell);
    return row;
  }

  int Function(int, int) myFunc = (a, b) => max(a, b).toInt();
  Widget getHeatMapContainer() {
    double height = reportList.length == 1 ? 70 : 60;

    return BoxContainer(
        showTitle: false,
        width: double.infinity,
        height: Responsive.isDesktop(context)
            ? (190 + (reportList.length * height))
            : 230 + (reportList.length * height),
        title: AppTranslations.of(context)!.text("key_message_01"),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Responsive.isDesktop(context)
                    ? Text(
                        AppTranslations.of(context)!.text("key_message_01"),
                        style: headTextStyle,
                      )
                    : Text(
                        AppTranslations.of(context)!.text("key_message_01"),
                        style: smallTextStyle,
                        softWrap: true,
                        maxLines: 3,
                      ),
                Visibility(
                    visible: true,
                    child: Container(
                      height: 40,
                      width: 120,
                      child: FormBuilderDropdown<String>(
                        name: "year",
                        initialValue: zone,
                        items: ["All", "North", "East", "West", "South"]
                            .map<DropdownMenuItem<String>>(
                                (toElement) => DropdownMenuItem(
                                      value: toElement.toString(),
                                      child: Text(toElement.toString()),
                                    ))
                            .toList(),
                        onChanged: (value) async {
                          zone = value.toString();
                          setState(() {});
                          await getClientReport(client_id);
                        },
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: AppTranslations.of(context)!.text("key_error_01"))
                        ]),
                        decoration: InputDecoration(
                          label: RichText(
                            text: TextSpan(
                              text:
                                  AppTranslations.of(context)!.text("key_zone"),
                              children: [],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.only(left: 20, top: 10),
                          counterText: "",
                          errorMaxLines: 3,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                  color: ThemeData().primaryColor, width: 1.0)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                  color: ThemeData().primaryColor, width: 1.0)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                  color: ThemeData().primaryColor, width: 1.0)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1.0)),
                          suffixIcon: null,
                        ),
                      ),
                    ))
              ],
            ),
            SizedBox(
              height: defaultPadding,
            ),
            SizedBox(
              width: double.infinity,
              height: reportList.length * height,
              child: DataTable2(
                headingRowHeight: 30,
                columnSpacing: 8,
                horizontalMargin: 8,
                minWidth: 800,
                rows: reportList.map<DataRow>((ele) => getRow(ele)).toList(),
                columns: heading
                    .map((ele) => DataColumn(
                          label: Center(
                              child: SizedBox(
                                  width: 100,
                                  child: Text(
                                    ele,
                                    style: headingTableTextStyle,
                                    textAlign: TextAlign.center,
                                  ))),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(
              height: defaultPadding,
            ),
            Text(
              "The numbers inside each unit indicates number of SMOs has High rated observations",
              style: headingTextStyle,
            ),
            SizedBox(
              height: defaultPadding,
            ),
            SizedBox(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Container(
                    width: 100,
                    height: 30,
                    color: usercontroller.scoreArr[0]["color"],
                    child: Center(child: Text("Extreme")),
                  ),
                  Container(
                    width: 100,
                    height: 30,
                    color: usercontroller.scoreArr[1]["color"],
                    child: Center(child: Text("High")),
                  ),
                  Container(
                    width: 100,
                    height: 30,
                    color: usercontroller.scoreArr[2]["color"],
                    child: Center(child: Text("Medium")),
                  ),
                  Container(
                    width: 100,
                    height: 30,
                    color: usercontroller.scoreArr[3]["color"],
                    child: Center(child: Text("Moderate")),
                  ),
                  Container(
                    width: 100,
                    height: 30,
                    color: usercontroller.scoreArr[4]["color"],
                    child: Center(child: Text("Low")),
                  )
                ],
              ),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, data) {
          if (didPop) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppTranslations.of(context)!.text("key_message_02")),
              content:
                  Text(AppTranslations.of(context)!.text("key_message_03")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      Text(AppTranslations.of(context)!.text("key_btn_cancel")),
                ),
              ],
            ),
          );
        },
        child: LayoutScreen(
          child: PageContainerComp(
            isBGTransparent: true,
            enableScroll: true,
            showTitle: false,
            padding: 0,
            header: SizedBox(),
            title: "",
            child: loadData == false
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: EdgeInsets.only(
                      left: 0,
                      right: 0,
                      bottom: defaultPadding,
                      top:0
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Section
                        Text(
                          "Audit Status at a Glance",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF505050),
                          ),
                        ),
                        SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "A clear view of where the audit execution stands.",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Color(0xFF898989),
                              ),
                            ),
                            _buildFinancialYearDropdown(),
                          ],
                        ),
                        SizedBox(height: 31),

                        // Top 3 Cards (Total, Scheduled, Unscheduled)
                        Row(
                          children: [
                            Expanded(
                              child: _buildTopCard(
                                "Total",
                                (dataObj["complete"] +
                                        dataObj["incomplete"] +
                                        dataObj["upcoming"] +
                                        dataObj["cancel"])
                                    .toString(),
                                Color(0xFF2E77D0),
                              ),
                            ),
                            SizedBox(width: defaultPadding),
                            Expanded(
                              child: _buildTopCard(
                                "Scheduled",
                                dataObj["upcoming"].toString(),
                                Color(0xFF67AC5B),
                              ),
                            ),
                            SizedBox(width: defaultPadding),
                            Expanded(
                              child: _buildTopCard(
                                "Un-scheduled",
                                dataObj["incomplete"].toString(),
                                Color(0xFFFFC422),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 42),

                        // Status Bar with 5 sections
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFC9C9C9),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatusCard(
                                  "Scheduled",
                                  Colors.white,
                                  dataObj["complete"].toString(),
                                  Colors.white,
                                  bgColor: Color(0xFF67AC5B),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              Expanded(
                                child: _buildStatusCard(
                                    "Published",
                                    Color(0xFF2E77D0),
                                    (dataObj["complete"] ~/ 2).toString(),
                                  Colors.black
                                ),
                              ),
                              _buildDivider(),
                              Expanded(
                                child: _buildStatusCard(
                                    "In Progress",
                                    Color(0xFFF29500),
                                    dataObj["incomplete"].toString(),
                                    Colors.black),
                              ),
                              _buildDivider(),
                              Expanded(
                                child: _buildStatusCard(
                                    "Upcoming",
                                   Color(0xFF9654CE),
                                    dataObj["upcoming"].toString(),
                                  Colors.black
                                ),
                              ),
                              _buildDivider(),
                              Expanded(
                                child: _buildStatusCard(
                                    "Cancelled",
                                    Color(0xFFDD0000),
                                    dataObj["cancel"].toString(),
                                  Colors.black
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: defaultPadding * 2),

                        // Heat Map Section (if needed)
                        // if (showHeatmap) getHeatMapContainer(),
                        if (showHeatmap) SizedBox(height: defaultPadding),
                        //if (showHeatmap) 
                        // BoxContainer(
                        //   width: double.infinity,
                        //   height: 700,
                        //   child: FlutterMap(
                        //     mapController: mapController,
                        //     options: MapOptions(
                        //       initialCenter: LatLng(22.9734, 78.6569),
                        //       initialZoom: 4, 
                        //       interactionOptions: const InteractionOptions(
                        //         flags: InteractiveFlag.all &
                        //             ~InteractiveFlag.rotate,
                        //       ),
                        //     ),
                        //     children: [
                        //       if (polygons.isNotEmpty)
                        //         PolygonLayer(
                        //           polygons: polygons,
                        //         ),
                        //       MarkerLayer(
                        //         markers: allAuditList
                        //             .map<Marker>(
                        //               (_element) => Marker(
                        //                 point: LatLng(
                        //                     double.tryParse(
                        //                             _element["latitude"]) ??
                        //                         13.0827,
                        //                     double.tryParse(
                        //                             _element["longitude"]) ??
                        //                         80.2707),
                        //                 width: 35,
                        //                 height: 35,
                        //                 child: Tooltip(
                        //                   message: _element["audit_no"] +
                        //                       "(" +
                        //                       _element["city"] +
                        //                       ")",
                        //                   child: Image(
                        //                     image:
                        //                         AssetImage(_element["svg"]),
                        //                     height: 40,
                        //                   ),
                        //                 ),
                        //               ),
                        //             )
                        //             .toList(),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
          ),
        ));
  }

  Widget _buildTopCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.only(top: 18, bottom: 18, left: 25, right: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFC9C9C9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 17,
            height: 83,
            decoration: BoxDecoration(
              color: color,
            ),
          ),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF898989),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, Color titleColor, String value, Color valueColor, {Color? bgColor, BorderRadius? borderRadius}) {
    return Container(
      height: 152,
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 152,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildFinancialYearDropdown() {
    if (financialYears.isEmpty) {
      return SizedBox();
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
              year = newValue; // Use FY format directly
            });
            // Reload data with new year
            await getClientReport(client_id);
          }
        },
      ),
    );
  }
}
