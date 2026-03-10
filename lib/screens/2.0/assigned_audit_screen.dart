import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

// ── Pre-built constants to avoid per-frame allocations ──────────────────────

const _kTitleStyle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF505050));
const _kSubtitleStyle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF898989));
const _kTabStyle =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
const _kTabLabelColor = Color(0xFF01ADEF);
const _kTextColor = Color(0xFF505050);
const _kActionBlue = Color(0xFF2E77D0);
const _kActionGreen = Color(0xFF67AC5B);
const _kActionDisabled = Color(0xFFC9C9C9);
const _kActionTextStyle = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white);
const _kActionPadding = EdgeInsets.symmetric(vertical: 8);
const _kActionBorderRadius = BorderRadius.all(Radius.circular(6));
const _kScrollPadding = EdgeInsets.only(left: 20, right: 20);
const _kTitlePadding = EdgeInsets.all(defaultPadding);
const _kFilterPadding = EdgeInsets.symmetric(
    horizontal: defaultPadding, vertical: defaultPadding / 2);
const _kFyRegex = r'^FY(\d{4})-(\d{2,4})$';

// Pre-built tab widgets — avoids rebuilding on every frame
const _kTabs = <Tab>[
  Tab(text: "All"),
  Tab(text: "Completed"),
  Tab(text: "In Progress"),
  Tab(text: "Upcoming"),
  Tab(text: "Cancelled"),
];

// Static column definitions that don't depend on instance state
const _kStaticColumns = <TableColumnDef>[
  TableColumnDef(label: "Audit ID", flex: 2, key: "audit_id"),
  TableColumnDef(label: "Sched. Date", flex: 2, key: "sched_date"),
  TableColumnDef(label: "Start Date", flex: 2, key: "start_date"),
  TableColumnDef(label: "End Date", flex: 2, key: "end_date"),
  TableColumnDef(label: "State", flex: 2, key: "state"),
  TableColumnDef(label: "City", flex: 2, key: "city"),
  TableColumnDef(label: "Location", flex: 3, key: "location"),
  TableColumnDef(label: "Company", flex: 2, key: "company"),
  TableColumnDef(label: "Assigned by", flex: 2, key: "assigned_by"),
];

class AssignedAuditScreen extends StatefulWidget {
  const AssignedAuditScreen({super.key});

  @override
  State<AssignedAuditScreen> createState() => _AssignedAuditScreenState();
}

class _AssignedAuditScreenState extends State<AssignedAuditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final UserController usercontroller;
  late final String _userRole;

  // Filter state
  String selectedCompany = "All";
  String selectedFinancialYear = "";
  List<Map<String, dynamic>> financialYears = [];

  // Cached company options — rebuilt only when allAudits changes
  List<String> _cachedCompanyOptions = const ["All"];

  void _rebuildCompanyOptions() {
    final companies = allAudits
        .map((a) => (a["company"] ?? "") as String)
        .where((c) => c.isNotEmpty && c != "-")
        .toSet()
        .toList()
      ..sort();
    _cachedCompanyOptions = ["All", ...companies];
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
  static final _fyRegex = RegExp(_kFyRegex, caseSensitive: false);

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    _userRole = usercontroller.userData.role ?? '';

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
      "role": _userRole,
      "client": usercontroller.userData.clientid,
      if (usercontroller.userData.clientid?.isNotEmpty == true)
        "client_id": usercontroller.userData.clientid!.first,
    };

    await usercontroller.getScheduledAuditDetails(context, data: data,
        callback: (list, total) {
      allAudits = list;
      _rebuildCompanyOptions();
      _applyFilterAndStopLoading();
    });
    // Ensure loading stops even if callback was never called
    if (mounted && isLoading) setState(() => isLoading = false);
  }

  /// Combines filter + loading-state update into a single setState.
  void _applyFilterAndStopLoading() {
    final tabIndex = _tabController.index;
    final status = _tabStatuses[tabIndex];

    List<dynamic> result = allAudits;

    if (status != null) {
      final labels = _labelsForStatus(status);
      result = result
          .where((a) => labels.contains(a["status"]["label"]))
          .toList();
    }
    if (selectedCompany != "All") {
      result =
          result.where((a) => (a["company"] ?? "") == selectedCompany).toList();
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
      final labels = _labelsForStatus(status);
      result = result
          .where((a) => labels.contains(a["status"]["label"]))
          .toList();
    }
    if (selectedCompany != "All") {
      result =
          result.where((a) => (a["company"] ?? "") == selectedCompany).toList();
    }

    setState(() {
      filteredAudits = result;
      currentPage = 1;
    });
  }

  /// For JrA, "Completed" tab shows both Review (submitted by auditor) and
  /// Published (approved by admin). Other roles see only Published.
  List<String> _labelsForStatus(String status) {
    switch (status) {
      case "P":
        return _userRole == "JrA"
            ? const ["Review", "Published"]
            : const ["Published"];
      case "IP":
        return const ["Inprogress"];
      case "S":
        return const ["Upcoming"];
      case "CL":
        return const ["Cancelled"];
      default:
        return const [];
    }
  }

  // ── Columns that depend on instance state — built once per build ──────────

  List<TableColumnDef> _buildColumns() {
    return [
      ..._kStaticColumns,
      TableColumnDef(
        label: "Status",
        flex: 2,
        cellBuilder: (row, _) {
          final s = row["status"] ?? {};
          String label = s["label"] ?? "-";
          String color = s["color"] ?? "grey";
          // For JrA, show Review/Published as "Completed"
          if (_userRole == "JrA" &&
              (label == "Review" || label == "Published")) {
            label = "Completed";
            color = "green";
          }
          return statusBadgeCell(
            label: label,
            color: color,
          );
        },
      ),
      TableColumnDef(
        label: "Action",
        flex: 2,
        isLast: true,
        cellBuilder: (row, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: _buildActionButtons(row),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final columns = _buildColumns();

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
                  SizedBox(height: 4),
                  Text("Detailed overview of all audits",
                      style: _kSubtitleStyle),
                ],
              ),
            ),

            // Tabs + Filters Row
            Container(
              padding: _kFilterPadding,
              child: Row(
                children: [
                  // Tabs
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
                  // Company Filter
                  TableFilterDropdown(
                    label: "Company :",
                    items: _cachedCompanyOptions,
                    value: selectedCompany,
                    onChanged: (val) {
                      setState(() => selectedCompany = val!);
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 12),
                  // Financial Year Filter
                  TableFilterDropdown(
                    items: financialYears
                        .map((e) => e["label"] as String)
                        .toList(),
                    value: selectedFinancialYear,
                    onChanged: (val) {
                      setState(() {
                        selectedFinancialYear = val!;
                        selectedCompany = "All";
                      });
                      _loadData();
                    },
                  ),
                ],
              ),
            ),

            // Table + Pagination
            ReusableTable(
              columns: columns,
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

  // ─── Action Buttons per status (mirrors AuditListV2 behavior) ─────────────

  Widget _buildActionButtons(dynamic row) {
    final s = row["status"] ?? {};
    final label = s["label"] ?? "-";

    // Published / Review → View Audit (navigates to detail screen for view + download)
    if (label == "Published" || label == "Review") {
      return _actionButton("View Audit", _kActionBlue, () {
        Navigator.pushNamed(context, "/auditdetails",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Inprogress → Continue (navigate to audit form)
    if (label == "Inprogress" || label == "In Progress") {
      return _actionButton("Continue", _kActionBlue, () {
        Navigator.pushNamed(context, "/auditcategorylist-v2",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Upcoming → Start (navigate to audit form; it handles startAudit API internally)
    if (label == "Upcoming") {
      return _actionButton("Start", _kActionGreen, () {
        Navigator.pushNamed(context, "/auditcategorylist-v2",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Cancelled → Disabled
    if (label == "Cancelled") {
      return _actionButton("Cancelled", _kActionDisabled, null);
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton(String label, Color bgColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: _kActionPadding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: _kActionBorderRadius,
        ),
        alignment: Alignment.center,
        child: Text(label,
            textAlign: TextAlign.center,
            style: _kActionTextStyle),
      ),
    );
  }
}
