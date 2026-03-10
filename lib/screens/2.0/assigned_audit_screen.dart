import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

class AssignedAuditScreen extends StatefulWidget {
  const AssignedAuditScreen({super.key});

  @override
  State<AssignedAuditScreen> createState() => _AssignedAuditScreenState();
}

class _AssignedAuditScreenState extends State<AssignedAuditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserController usercontroller = Get.put(UserController());

  // Filter state
  String selectedCompany = "All";
  String selectedFinancialYear = "";
  List<Map<String, dynamic>> financialYears = [];

  List<String> get companyOptions {
    final companies = allAudits
        .map((a) => (a["company"] ?? "") as String)
        .where((c) => c.isNotEmpty && c != "-")
        .toSet()
        .toList()
      ..sort();
    return ["All", ...companies];
  }

  // Data state
  bool isLoading = false;
  List<dynamic> allAudits = [];
  List<dynamic> filteredAudits = [];
  int currentPage = 1;
  final int pageSize = 10;

  // Tab configuration — matches screenshot
  final List<String> tabLabels = [
    "All",
    "Completed",
    "In Progress",
    "Upcoming",
    "Cancelled"
  ];
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

    // Convert "FY2025-26" label → bare end year "2026" for the API
    String yearParam = selectedFinancialYear;
    final fyMatch = RegExp(r'^FY(\d{4})-(\d{2,4})$', caseSensitive: false)
        .firstMatch(yearParam);
    if (fyMatch != null) {
      final startYear = int.parse(fyMatch.group(1)!);
      yearParam = (startYear + 1).toString();
    }

    var data = {
      "year": yearParam,
      "month": "All",
      "userid": usercontroller.userData.userId,
      "role": role,
      "client": usercontroller.userData.clientid,
      if (usercontroller.userData.clientid?.isNotEmpty == true)
        "client_id": usercontroller.userData.clientid!.first,
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
    if (status == "P") {
      final role = usercontroller.userData.role ?? '';
      if (role == "JrA") {
        return ["Review", "Published"];
      }
      return ["Published"];
    }
    switch (status) {
      case "IP":
        return ["Inprogress"];
      case "S":
        return ["Upcoming"];
      case "CL":
        return ["Cancelled"];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20),
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
                      labelStyle: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                      unselectedLabelStyle: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                      tabs: tabLabels.map((l) => Tab(text: l)).toList(),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Company Filter
                  TableFilterDropdown(
                    label: "Company :",
                    items: companyOptions,
                    value: selectedCompany,
                    onChanged: (val) {
                      setState(() => selectedCompany = val!);
                      _applyFilter();
                    },
                  ),
                  SizedBox(width: 12),
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
              columns: [
                TableColumnDef(label: "Audit ID", flex: 2, key: "audit_id"),
                TableColumnDef(
                    label: "Sched. Date", flex: 2, key: "sched_date"),
                TableColumnDef(
                    label: "Start Date", flex: 2, key: "start_date"),
                TableColumnDef(label: "End Date", flex: 2, key: "end_date"),
                TableColumnDef(label: "State", flex: 2, key: "state"),
                TableColumnDef(label: "City", flex: 2, key: "city"),
                TableColumnDef(label: "Location", flex: 3, key: "location"),
                TableColumnDef(label: "Company", flex: 2, key: "company"),
                TableColumnDef(
                    label: "Assigned by", flex: 2, key: "assigned_by"),
                TableColumnDef(
                  label: "Status",
                  flex: 2,
                  cellBuilder: (row, _) {
                    final s = row["status"] ?? {};
                    String label = s["label"] ?? "-";
                    String color = s["color"] ?? "grey";
                    // For JrA, show Review/Published as "Completed"
                    final role = usercontroller.userData.role ?? '';
                    if (role == "JrA" &&
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
                  cellBuilder: (row, _) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    child: _buildActionButtons(row),
                  ),
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

  // ─── Action Buttons per status (mirrors AuditListV2 behavior) ─────────────

  Widget _buildActionButtons(dynamic row) {
    final s = row["status"] ?? {};
    final label = s["label"] ?? "-";

    // Published / Review → View Audit (navigates to detail screen for view + download)
    if (label == "Published" || label == "Review") {
      return _actionButton("View Audit", Color(0xFF2E77D0), () {
        Navigator.pushNamed(context, "/auditdetails",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Inprogress → Continue (navigate to audit form)
    if (label == "Inprogress" || label == "In Progress") {
      return _actionButton("Continue", Color(0xFF2E77D0), () {
        Navigator.pushNamed(context, "/auditcategorylist-v2",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Upcoming → Start (navigate to audit form; it handles startAudit API internally)
    if (label == "Upcoming") {
      return _actionButton("Start", Color(0xFF67AC5B), () {
        Navigator.pushNamed(context, "/auditcategorylist-v2",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Cancelled → Disabled
    if (label == "Cancelled") {
      return _actionButton("Cancelled", Color(0xFFC9C9C9), null);
    }

    return SizedBox.shrink();
  }

  Widget _actionButton(String label, Color bgColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
      ),
    );
  }
}
