import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/widget/financial_year_dropdown.dart';
import 'package:audit_app/widget/zone_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../responsive.dart';
import '../../widget/reusable_table.dart';

class RedReportListScreen extends StatefulWidget {
  const RedReportListScreen({super.key});

  @override
  State<RedReportListScreen> createState() => _RedReportListScreenState();
}

class _RedReportListScreenState extends State<RedReportListScreen> {
  late final UserController usercontroller;

  String selectedCity = "All";
  String selectedState = "All";
  String selectedZone = "All";
  String year = "";
  List<Map<String, dynamic>> financialYears = [];

  List<String> _cachedCityOptions = const ["All"];
  List<String> _cachedStateOptions = const ["All"];

  bool isLoading = false;
  List<Map<String, dynamic>> allAudits = [];
  List<Map<String, dynamic>> filteredAudits = [];
  int currentPage = 1;
  static const int pageSize = 10;

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    if (usercontroller.userData.role == null) {
      usercontroller.loadInitData();
    }

    final now = DateTime.now();
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    financialYears = List.generate(5, (index) {
      final y = fyStartYear - index;
      final nextYearShort = (y + 1).toString().substring(2);
      final fyValue = "FY$y-$nextYearShort";
      return {"label": fyValue, "value": (y + 1).toString()};
    });
    year = financialYears[0]["value"]!;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    Map<String, dynamic> data = {
      "client": usercontroller.userData.clientid,
      "userid": usercontroller.userData.userId,
      "role": usercontroller.userData.role,
      "year": year,
    };

    usercontroller.getRedReportList(context, data: data, callback: (res) {
      allAudits = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      _rebuildFilterOptions();
      _applyFilter();
      if (mounted) setState(() => isLoading = false);
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && isLoading) setState(() => isLoading = false);
    });
  }

  void _rebuildFilterOptions() {
    final states = allAudits
        .map((a) => (a["state"] ?? "").toString())
        .where((s) => s.isNotEmpty && s != "-")
        .toSet()
        .toList()
      ..sort();
    _cachedStateOptions = ["All", ...states];

    final cities = allAudits
        .map((a) => (a["city"] ?? "").toString())
        .where((s) => s.isNotEmpty && s != "-")
        .toSet()
        .toList()
      ..sort();
    _cachedCityOptions = ["All", ...cities];
  }

  void _applyFilter() {
    List<Map<String, dynamic>> result = List.from(allAudits);

    if (selectedCity != "All") {
      result = result.where((a) => (a["city"] ?? "").toString() == selectedCity).toList();
    }
    if (selectedState != "All") {
      result = result.where((a) => (a["state"] ?? "").toString() == selectedState).toList();
    }
    if (selectedZone != "All") {
      result = result.where((a) => (a["zone"] ?? "").toString() == selectedZone).toList();
    }
    setState(() {
      filteredAudits = result;
      currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Red Report - High Risk",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEA4032))),
                  const SizedBox(height: 18),
                  const Text("Points requiring immediate attention",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w100,
                          color: Color(0xFF898989))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      TableFilterDropdown(
                          label: "City:",
                          items: _cachedCityOptions,
                          value: selectedCity,
                          onChanged: (val) {
                        setState(() => selectedCity = val!);
                        _applyFilter();
                      }),
                      TableFilterDropdown(
                          label: "State:",
                          items: _cachedStateOptions,
                          value: selectedState,
                          onChanged: (val) {
                        setState(() {
                          selectedState = val!;
                          selectedZone = "All";
                        });
                        _applyFilter();
                      }),
                      ZoneDropdown(
                          label: "Zone:",
                          allData: allAudits,
                          stateFilter: selectedState,
                          value: selectedZone,
                          onChanged: (val) {
                        setState(() => selectedZone = val!);
                        _applyFilter();
                      }),
                      FinancialYearDropdown(
                          value: year,
                          items: financialYears,
                          onChanged: (val) {
                        setState(() {
                          year = val;
                          selectedCity = "All";
                          selectedState = "All";
                          selectedZone = "All";
                        });
                        _loadData();
                      }),
                    ],
                  ),
                ],
              ),
            ),
            ReusableTable(
              columns: Responsive.isMobile(context)
                  ? [
                      TableColumnDef(label: "Audit ID", flex: 2, key: "audit_no"),
                      TableColumnDef(label: "Location", flex: 3, key: "location"),
                      TableColumnDef(label: "Activity", flex: 3, key: "activity"),
                      TableColumnDef(
                        label: "Downloads", flex: 2, isLast: true,
                        cellBuilder: (row, _) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: _buildDownloadButton(row),
                        ),
                      ),
                    ]
                  : [
                      TableColumnDef(
                        label: "Audit ID", flex: 2,
                        cellBuilder: (row, _) => _buildColoredCell(row, "audit_no", const Color(0xFFEA4032)),
                      ),
                      TableColumnDef(label: "Zone", flex: 1, key: "zone"),
                      TableColumnDef(label: "State", flex: 2, key: "state"),
                      TableColumnDef(label: "City", flex: 2, key: "city"),
                      TableColumnDef(label: "Location", flex: 2, key: "location"),
                      TableColumnDef(label: "Activity", flex: 3, key: "activity"),
                      TableColumnDef(label: "Responsibility\nTime Frame", flex: 2, key: "responsibility_timeframe"),
                      TableColumnDef(
                        label: "Downloads", flex: 1, isLast: true,
                        cellBuilder: (row, _) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: _buildDownloadButton(row),
                        ),
                      ),
                    ],
              rows: filteredAudits,
              isLoading: isLoading,
              currentPage: currentPage,
              pageSize: pageSize,
              maxVisiblePages: 8,
              headerFontWeight: FontWeight.w700,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredCell(dynamic row, String key, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Text(
        (row[key] ?? '-').toString(),
        style: const TextStyle(fontSize: smallFontSize, color: Colors.black),
      ),
    );
  }

  Widget _buildDownloadButton(dynamic row) {
    return GestureDetector(
      onTap: () {
        final url = (row["reporturl"] ?? "").toString();
        if (url.isEmpty) return;
        final downloadUrl = '${API_URL}export?key=$url';
        launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.download_outlined, size: 18, color: Color(0xFF606060)),
      ),
    );
  }
}
