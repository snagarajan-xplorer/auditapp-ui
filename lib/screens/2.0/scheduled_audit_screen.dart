import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

// ── Pre-built constants ─────────────────────────────────────────────────────
const _kTitleStyle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF505050));
const _kSubtitleStyle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w100, color: Color(0xFF898989));
const _kTabStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
const _kTabLabelColor = Color(0xFF01ADEF);
const _kTextColor = Color(0xFF505050);
const _kScrollPadding = EdgeInsets.only(left: 20, right: 20);
const _kTitlePadding = EdgeInsets.all(defaultPadding);
const _kFilterPadding = EdgeInsets.symmetric(
    horizontal: defaultPadding, vertical: defaultPadding / 2);

const _kTabs = <Tab>[
  Tab(text: "All"),
  Tab(text: "Published"),
  Tab(text: "In Progress"),
  Tab(text: "Upcoming"),
  Tab(text: "Cancelled"),
];

const _kStaticColumns = <TableColumnDef>[
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
];

class ScheduledAuditScreen extends StatefulWidget {
  const ScheduledAuditScreen({super.key});

  @override
  State<ScheduledAuditScreen> createState() => _ScheduledAuditScreenState();
}

class _ScheduledAuditScreenState extends State<ScheduledAuditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final UserController usercontroller;

  // Filter state
  String selectedZone = "All";
  String selectedState = "All";
  String selectedFinancialYear = "";
  List<Map<String, dynamic>> financialYears = [];

  // Cached filter options — rebuilt only when allAudits changes
  List<String> _cachedStateOptions = const ["All"];
  List<String> _cachedZoneOptions = const ["All"];

  void _rebuildStateOptions() {
    final states = allAudits
        .map((a) => (a["state"] ?? "") as String)
        .where((s) => s.isNotEmpty && s != "-")
        .toSet()
        .toList()
      ..sort();
    _cachedStateOptions = ["All", ...states];
  }

  void _rebuildZoneOptions() {
    final zoneSet = allAudits
        .where((a) => selectedState == "All" || (a["state"] ?? "") == selectedState)
        .map((a) => (a["zone"] ?? "") as String)
        .where((z) => z.isNotEmpty && z != "-")
        .toSet()
        .toList()
      ..sort();
    _cachedZoneOptions = ["All", ...zoneSet];
  }

  // Data state
  bool isLoading = false;
  List<dynamic> allAudits = [];
  List<dynamic> filteredAudits = [];
  int currentPage = 1;
  static const int pageSize = 10;

  // Tab status mapping
  static const List<String?> _tabStatuses = [null, "P", "IP", "S", "CL"];

  // FY regex — compiled once
  static final _fyRegex = RegExp(r'^FY(\d{4})-(\d{2,4})$', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();

    _tabController = TabController(length: _kTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Build financial years — Indian FY starts in April
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

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _rebuildZoneOptions();
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final role = usercontroller.userData.role ?? '';
    final isAdminRole = role == 'SA' || role == 'AD';

    // Convert "FY2025-26" label → bare end year "2026" for the API
    String yearParam = selectedFinancialYear;
    final fyMatch = _fyRegex.firstMatch(yearParam);
    if (fyMatch != null) {
      final startYear = int.parse(fyMatch.group(1)!);
      yearParam = (startYear + 1).toString();
    }

    final data = <String, dynamic>{
      "year": yearParam,
      "month": "All",
      "userid": usercontroller.userData.userId,
      "role": role,
      if (!isAdminRole) "client": usercontroller.userData.clientid,
      if (!isAdminRole)
        "client_id": usercontroller.userData.clientid?.isNotEmpty == true
            ? usercontroller.userData.clientid!.first
            : null,
    };
    await usercontroller.getScheduledAuditDetails(context, data: data,
        callback: (list, total) {
      allAudits = list;
      _rebuildStateOptions();
      _rebuildZoneOptions();
      _applyFilterAndStopLoading();
    });
    if (mounted && isLoading) setState(() => isLoading = false);
  }

  void _applyFilterAndStopLoading() {
    final tabIndex = _tabController.index;
    final status = _tabStatuses[tabIndex];

    List<dynamic> result = allAudits;

    if (status != null) {
      final label = _labelForStatus(status);
      result = result.where((a) => a["status"]["label"] == label).toList();
    }
    if (selectedState != "All") {
      result = result.where((a) => (a["state"] ?? "") == selectedState).toList();
    }
    if (selectedZone != "All") {
      result = result.where((a) => (a["zone"] ?? "") == selectedZone).toList();
    }

    if (mounted) {
      setState(() {
        filteredAudits = result;
        currentPage = 1;
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final tabIndex = _tabController.index;
    final status = _tabStatuses[tabIndex];

    List<dynamic> result = allAudits;

    if (status != null) {
      final label = _labelForStatus(status);
      result = result.where((a) => a["status"]["label"] == label).toList();
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

  static String _labelForStatus(String status) {
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
        padding: _kScrollPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              padding: _kTitlePadding,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Scheduled Audit Details", style: _kTitleStyle),
                  SizedBox(height: 18),
                  Text("Detailed overview of all audits", style: _kSubtitleStyle),
                ],
              ),
            ),

            // Tabs + Filters Row
            Container(
              padding: _kFilterPadding,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: _kTabLabelColor,
                      unselectedLabelColor: _kTextColor,
                      indicatorColor: _kTabLabelColor,
                      indicatorWeight: 3,
                      labelStyle: _kTabStyle,
                      unselectedLabelStyle: _kTabStyle,
                      tabs: _kTabs,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TableFilterDropdown(
                      label: "State:", items: _cachedStateOptions, value: selectedState,
                      onChanged: (val) {
                    setState(() {
                      selectedState = val!;
                      selectedZone = "All";
                    });
                    _rebuildZoneOptions();
                    _applyFilter();
                  }),
                  const SizedBox(width: 12),
                  TableFilterDropdown(
                      label: "Zone:", items: _cachedZoneOptions, value: selectedZone,
                      onChanged: (val) {
                    setState(() => selectedZone = val!);
                    _applyFilter();
                  }),
                  const SizedBox(width: 12),
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
                ..._kStaticColumns,
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

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}

