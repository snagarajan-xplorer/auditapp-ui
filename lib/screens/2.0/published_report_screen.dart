import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/widget/financial_year_dropdown.dart';
import 'package:audit_app/widget/zone_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../responsive.dart';
import '../../widget/reusable_table.dart';

class PublishedReportScreen extends StatefulWidget {
  const PublishedReportScreen({super.key});

  @override
  State<PublishedReportScreen> createState() => _PublishedReportScreenState();
}

class _PublishedReportScreenState extends State<PublishedReportScreen> {
  late final UserController usercontroller;

  String selectedState = "All";
  String selectedZone = "All";
  String year = "";
  List<Map<String, dynamic>> financialYears = [];

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

    usercontroller.getPublishedReportList(context, data: data, callback: (res) {
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

  }

  void _applyFilter() {
    List<Map<String, dynamic>> result = List.from(allAudits);

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
                  const Text("Published Report",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))),
                  const SizedBox(height: 18),
                  const Text("Publish summary & full reports fields",
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
                      TableColumnDef(label: "Auditor", flex: 2, key: "auditor_name"),
                      TableColumnDef(
                        label: "Report", flex: 2, isLast: true,
                        cellBuilder: (row, _) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: _buildViewButton(row),
                        ),
                      ),
                    ]
                  : [
                      TableColumnDef(label: "Audit ID", flex: 2, key: "audit_no"),
                      TableColumnDef(label: "Sched. Date", flex: 2, key: "scheduled_date"),
                      TableColumnDef(label: "Start Date", flex: 2, key: "start_date"),
                      TableColumnDef(label: "End Date", flex: 2, key: "end_date"),
                      TableColumnDef(label: "Zone", flex: 2, key: "zone"),
                      TableColumnDef(label: "State", flex: 2, key: "state"),
                      TableColumnDef(label: "City", flex: 2, key: "city"),
                      TableColumnDef(label: "Location", flex: 2, key: "location"),
                      TableColumnDef(label: "Type of Location", flex: 2, key: "type_of_location"),
                      TableColumnDef(label: "Auditor", flex: 2, key: "auditor_name"),
                      TableColumnDef(
                        label: "Report", flex: 2, isLast: true,
                        cellBuilder: (row, _) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: _buildViewButton(row),
                        ),
                      ),
                    ],
              rows: filteredAudits,
              isLoading: isLoading,
              currentPage: currentPage,
              pageSize: pageSize,
              maxVisiblePages: 5,
              headerFontWeight: FontWeight.w700,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildViewButton(dynamic row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconButton(
          icon: Icons.visibility_outlined,
          onTap: () {
            Navigator.pushNamed(context, "/summary-report",
                arguments: ScreenArgument(
                    argument: ArgumentData.USER,
                    mapData: Map<String, dynamic>.from(row)));
          },
        ),
        const SizedBox(width: 8),
        _iconButton(
          icon: Icons.download_outlined,
          onTap: () {
            final url = (row["reporturl"] ?? "").toString();
            if (url.isEmpty) return;
            final downloadUrl = '${API_URL}export?key=$url';
            launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF606060)),
      ),
    );
  }
}
