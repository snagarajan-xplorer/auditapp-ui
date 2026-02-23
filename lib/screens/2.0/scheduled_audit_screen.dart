import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

class ScheduledAuditScreen extends StatefulWidget {
  const ScheduledAuditScreen({super.key});

  @override
  State<ScheduledAuditScreen> createState() => _ScheduledAuditScreenState();
}

class _ScheduledAuditScreenState extends State<ScheduledAuditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserController usercontroller = Get.put(UserController());

  // Filter state
  String selectedZone = "All";
  String selectedState = "All";
  String selectedFinancialYear = "";
  List<Map<String, dynamic>> financialYears = [];

  List<String> get stateOptions {
    final states = allAudits
        .map((a) => (a["state"] ?? "") as String)
        .where((s) => s.isNotEmpty && s != "-")
        .toSet()
        .toList()
      ..sort();
    return ["All", ...states];
  }

  List<String> get zoneOptions {
    final zoneSet = allAudits
        .where((a) => selectedState == "All" || (a["state"] ?? "") == selectedState)
        .map((a) => (a["zone"] ?? "") as String)
        .where((z) => z.isNotEmpty && z != "-")
        .toSet()
        .toList()
      ..sort();
    return ["All", ...zoneSet];
  }
  final List<String> years = ["FY2024-25", "FY2023-24", "FY2022-23", "FY2021-22", "FY2020-21"];

  // Data state
  bool isLoading = false;
  List<dynamic> allAudits = [];
  List<dynamic> filteredAudits = [];
  int currentPage = 1;
  final int pageSize = 10;

  // Tab configuration
  final List<String> tabLabels = ["All", "Published", "In Progress", "Upcoming", "Cancelled"];
  final List<String?> tabStatuses = [null, "P", "IP", "S", "CL"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilter();
      }
    });

    // Build financial years — Indian FY starts in April
    // If current month < April, current FY start year = last year
    final now = DateTime.now();
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    financialYears = List.generate(5, (index) {
      final y = fyStartYear - index;
      final nextYearShort = (y + 1).toString().substring(2);
      final fyValue = "FY$y-$nextYearShort";
      return {"label": fyValue, "value": fyValue};
    });
    selectedFinancialYear = financialYears[0]["value"];

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final role = usercontroller.userData.role ?? '';
    final isAdminRole = role == 'SA' || role == 'AD';

    // Convert "FY2025-26" label → bare end year "2026" for the API
    String yearParam = selectedFinancialYear;
    final fyMatch = RegExp(r'^FY(\d{4})-(\d{2,4})$', caseSensitive: false)
        .firstMatch(yearParam);
    if (fyMatch != null) {
      final startYear = int.parse(fyMatch.group(1)!);
      yearParam = (startYear + 1).toString(); // "FY2025-26" → "2026"
    }

    var data = {
      "year": yearParam,
      "month": "All",
      "userid": usercontroller.userData.userId,
      "role": role,
      // SA/AD see all clients — don't send client filter
      if (!isAdminRole) "client": usercontroller.userData.clientid,
      if (!isAdminRole)
        "client_id": usercontroller.userData.clientid?.isNotEmpty == true
            ? usercontroller.userData.clientid!.first
            : null,
    };
    await usercontroller.getScheduledAuditDetails(context, data: data,
        callback: (list, total) {
      allAudits = list;
      _applyFilter();
      if (mounted) setState(() => isLoading = false);
    });
    // Ensure loading stops even if callback was never called
    if (mounted && isLoading) setState(() => isLoading = false);
  }

  void _applyFilter() {
    final tabIndex = _tabController.index;
    final status = tabStatuses[tabIndex];

    List<dynamic> result = allAudits;

    if (status != null) {
      result = result.where((a) => a["status"]["label"] == _labelForStatus(status)).toList();
    }
    if (selectedState != "All") {
      result = result.where((a) => (a["state"] ?? "") == selectedState).toList();
    }
    if (selectedZone != "All") {
      result = result.where((a) => (a["zone"] ?? "") == selectedZone).toList();
    }

    setState(() {
      filteredAudits = result;
      currentPage = 1;
    });
  }

  String _labelForStatus(String status) {
    switch (status) {
      case "P": return "Published";
      case "IP": return "In Progress";
      case "S": return "Upcoming";
      case "CL": return "Cancelled";
      default: return "";
    }
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
            // Title
            Container(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Scheduled Audit Details",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF505050))),
                  SizedBox(height: 4),
                  Text("Detailed overview of all audits",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF898989))),
                ],
              ),
            ),

            // Tabs + Filters Row
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding / 2),
              child: Row(
                children: [
                  // Tabs
                  Expanded(
                    flex: 3,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Color(0xFF01ADEF),
                      unselectedLabelColor: Color(0xFF505050),
                      indicatorColor: Color(0xFF01ADEF),
                      indicatorWeight: 3,
                      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      tabs: tabLabels.map((l) => Tab(text: l)).toList(),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Filters
                  TableFilterDropdown(
                      label: "State:", items: stateOptions, value: selectedState,
                      onChanged: (val) {
                    setState(() {
                      selectedState = val!;
                      selectedZone = "All";
                    });
                    _applyFilter();
                  }),
                  SizedBox(width: 12),
                  TableFilterDropdown(
                      label: "Zone:", items: zoneOptions, value: selectedZone,
                      onChanged: (val) {
                    setState(() => selectedZone = val!);
                    _applyFilter();
                  }),
                  SizedBox(width: 12),
                  TableFilterDropdown(
                      items: financialYears.map((e) => e["label"] as String).toList(),
                      value: selectedFinancialYear,
                      onChanged: (val) {
                    setState(() {
                      selectedFinancialYear = val!;
                      selectedState = "All";
                    });
                    _loadData();
                  }),
                ],
              ),
            ),

            // Table + Pagination
            ReusableTable(
              columns: [
                TableColumnDef(label: "Audit ID", flex: 2, key: "audit_id"),
                TableColumnDef(label: "Sched. Date", flex: 2, key: "sched_date"),
                TableColumnDef(label: "Start Date", flex: 2, key: "start_date"),
                TableColumnDef(label: "End Date", flex: 2, key: "end_date"),
                TableColumnDef(label: "Zone", flex: 2, key: "zone"),
                TableColumnDef(label: "State", flex: 2, key: "state"),
                TableColumnDef(label: "City", flex: 2, key: "city"),
                TableColumnDef(label: "Location", flex: 3, key: "location"),
                TableColumnDef(label: "Type", flex: 2, key: "type_of_location"),
                TableColumnDef(label: "Auditor", flex: 2, key: "auditor"),
                TableColumnDef(
                  label: "Status", flex: 2, isLast: true,
                  cellBuilder: (row, _) {
                    final s = row["status"] ?? {};
                    return statusBadgeCell(
                      label: s["label"] ?? "-",
                      color: s["color"] ?? "grey",
                      showBorder: false,
                    );
                  },
                ),
              ],
              rows: filteredAudits,
              isLoading: isLoading,
              currentPage: currentPage,
              pageSize: pageSize,
              cellVerticalPadding: 23,
              cellHorizontalPadding: 8,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),

            SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}

