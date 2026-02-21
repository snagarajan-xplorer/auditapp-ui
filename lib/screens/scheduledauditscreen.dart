import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main/layoutscreen.dart';
import '../constants.dart';

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

  List<dynamic> get _pagedAudits {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filteredAudits.length);
    return filteredAudits.sublist(start, end);
  }

  int get _totalPages => (filteredAudits.length / pageSize).ceil();

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
                  _buildFilterDropdown("State:", stateOptions, selectedState, (val) {
                    setState(() {
                      selectedState = val!;
                      selectedZone = "All";
                    });
                    _applyFilter();
                  }),
                  SizedBox(width: 12),
                  _buildFilterDropdown("Zone:", zoneOptions, selectedZone, (val) {
                    setState(() => selectedZone = val!);
                    _applyFilter();
                  }),
                  SizedBox(width: 12),
                  _buildFilterDropdown("", financialYears.map((e) => e["label"] as String).toList(),
                      selectedFinancialYear, (val) {
                    setState(() {
                      selectedFinancialYear = val!;
                      selectedState = "All";
                    });
                    _loadData();
                  }),
                ],
              ),
            ),

            // Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding),
              child: isLoading
                  ? Container(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()))
                  : filteredAudits.isEmpty
                      ? Container(
                          height: 200,
                          child: Center(
                            child: Text("No records found",
                                style: TextStyle(
                                    fontSize: 16, color: Color(0xFF898989))),
                          ))
                      : Column(
                          children: [
                            _buildTableHeader(),
                            ..._pagedAudits
                                .asMap()
                                .entries
                                .map((e) => _buildTableRow(e.value, e.key))
                                .toList(),
                          ],
                        ),
            ),

            _buildPagination(),

            SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF8D8D8D),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          _headerCell("Audit ID", flex: 2),
          _headerCell("Sched. Date", flex: 2),
          _headerCell("Start Date", flex: 2),
          _headerCell("End Date", flex: 2),
          _headerCell("Zone", flex: 2),
          _headerCell("State", flex: 2),
          _headerCell("City", flex: 2),
          _headerCell("Location", flex: 3),
          _headerCell("Type", flex: 2),
          _headerCell("Auditor", flex: 2),
          _headerCell("Status", flex: 2, isLast: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 2, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(right: BorderSide(color: Color(0xFFBCBCBC), width: 1)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFFFFFFF))),
      ),
    );
  }

  Widget _buildTableRow(dynamic row, int index) {
    final isEven = index % 2 == 0;
    final status = row["status"] ?? {};
    final statusLabel = status["label"] ?? "";
    final statusColor = _statusColor(status["color"] ?? "grey");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _dataCell(row["audit_id"] ?? "-", flex: 2),
          _dataCell(row["sched_date"] ?? "-", flex: 2),
          _dataCell(row["start_date"] ?? "-", flex: 2),
          _dataCell(row["end_date"] ?? "-", flex: 2),
          _dataCell(row["zone"] ?? "-", flex: 2),
          _dataCell(row["state"] ?? "-", flex: 2),
          _dataCell(row["city"] ?? "-", flex: 2),
          _dataCell(row["location"] ?? "-", flex: 3),
          _dataCell(row["type_of_location"] ?? "-", flex: 2),
          _dataCell(row["auditor"] ?? "-", flex: 2),
          // Status badge (last column — no right border)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String value, {int flex = 2, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 23, horizontal: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Text(value,
            style: TextStyle(fontSize: 12, color: Color(0xFF505050)),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Color _statusColor(String color) {
    switch (color) {
      case "green": return Color(0xFF67AC5B);
      case "orange": return Color(0xFFF29500);
      case "purple": return Color(0xFF9654CE);
      case "red": return Color(0xFFDD0000);
      default: return Color(0xFF505050);
    }
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageButton(Icons.chevron_left, currentPage > 1, () {
            setState(() => currentPage--);
          }),
          ...List.generate(_totalPages, (i) {
            final page = i + 1;
            final isActive = page == currentPage;
            return GestureDetector(
              onTap: () => setState(() => currentPage = page),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? Color(0xFF01ADEF) : Colors.white,
                  border: Border.all(
                      color: isActive ? Color(0xFF01ADEF) : Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text("$page",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isActive ? Colors.white : Color(0xFF4D4F5C))),
                ),
              ),
            );
          }),
          _pageButton(Icons.chevron_right, currentPage < _totalPages, () {
            setState(() => currentPage++);
          }),
        ],
      ),
    );
  }

  Widget _pageButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFD7DAE2)),
          borderRadius: BorderRadius.circular(0),
          color: Colors.white,
        ),
        child: Icon(icon, size: 18,
            color: enabled ? Color(0xFF808495) : Color(0xFFCCCCCC)),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF505050),
                  fontWeight: FontWeight.w400)),
          SizedBox(width: 8),
        ],
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFC9C9C9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
            style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

