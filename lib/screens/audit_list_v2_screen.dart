import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'main/layoutscreen.dart';
import '../constants.dart';

class AuditListV2Screen extends StatefulWidget {
  const AuditListV2Screen({super.key});

  @override
  State<AuditListV2Screen> createState() => _AuditListV2ScreenState();
}

class _AuditListV2ScreenState extends State<AuditListV2Screen> {
  UserController usercontroller = Get.put(UserController());

  // Filter state
  String selectedState = "All";
  String selectedZone = "All";
  String year = "";
  String month = "All";
  List<Map<String, dynamic>> financialYears = [];

  // Status map for converting raw codes to display objects
  static const Map<String, Map<String, String>> _statusMap = {
    'P':  {'label': 'Published',   'color': 'green'},
    'IP': {'label': 'Inprogress',  'color': 'orange'},
    'PG': {'label': 'Inprogress',  'color': 'orange'},
    'C':  {'label': 'Review',      'color': 'pink'},
    'S':  {'label': 'Upcoming',    'color': 'purple'},
    'CL': {'label': 'Cancelled',   'color': 'red'},
  };

  List<String> get stateOptions {
    final states = allAudits
        .map((a) => (a["state"] ?? "").toString())
        .where((s) => s.isNotEmpty && s != "-")
        .toSet()
        .toList()
      ..sort();
    return ["All", ...states];
  }

  List<String> get zoneOptions {
    final zones = allAudits
        .where(
            (a) => selectedState == "All" || (a["state"] ?? "").toString() == selectedState)
        .map((a) => (a["zone"] ?? "").toString())
        .where((z) => z.isNotEmpty && z != "-")
        .toSet()
        .toList()
      ..sort();
    return ["All", ...zones];
  }

  // Data state
  bool isLoading = false;
  List<Map<String, dynamic>> allAudits = [];
  List<Map<String, dynamic>> filteredAudits = [];
  int currentPage = 1;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    if (usercontroller.userData.role == null) {
      usercontroller.loadInitData();
    }

    // Use same year list as existing audit list screen
    year = Jiffy.now().year.toString();

    // Build financial years — Indian FY starts in April
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
      "month": month,
      "year": year,
    };

    usercontroller.getAuditList(context, data: data, callback: (res) {
      allAudits = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      _applyFilter();
      if (mounted) setState(() => isLoading = false);
    });
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

  List<Map<String, dynamic>> get _pagedAudits {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filteredAudits.length);
    return filteredAudits.sublist(start, end);
  }

  int get _totalPages => filteredAudits.isEmpty ? 1 : (filteredAudits.length / pageSize).ceil();

  // ─── Data field helpers (normalize raw getAuditList fields) ─────────────────

  String _getAuditId(Map<String, dynamic> row) =>
      (row["audit_no"] ?? row["audit_id"] ?? "-").toString();

  String _getAuditName(Map<String, dynamic> row) =>
      (row["auditname"] ?? row["audit_name"] ?? "-").toString();

  String _getAssignedTo(Map<String, dynamic> row) =>
      (row["auditorname"] ?? row["auditor"] ?? "-").toString();

  String _getSchedDate(Map<String, dynamic> row) {
    try {
      final raw = row["start_date"];
      if (raw == null) return "-";
      return Jiffy.parseFromDateTime(DateTime.parse(raw.toString()))
          .format(pattern: "MMM dd, yyyy");
    } catch (_) {
      return (row["start_date"] ?? "-").toString();
    }
  }

  String _getEndDate(Map<String, dynamic> row) {
    try {
      final raw = row["end_date"];
      if (raw == null || raw.toString().isEmpty) return "-";
      return Jiffy.parseFromDateTime(DateTime.parse(raw.toString()))
          .format(pattern: "MMM dd, yyyy");
    } catch (_) {
      return (row["end_date"] ?? "-").toString();
    }
  }

  Map<String, String> _getStatus(Map<String, dynamic> row) {
    final raw = row["status"];
    if (raw is Map) {
      return {"label": raw["label"]?.toString() ?? "-", "color": raw["color"]?.toString() ?? "grey"};
    }
    return _statusMap[raw?.toString()] ?? {"label": raw?.toString() ?? "-", "color": "grey"};
  }

  // ─── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String color) {
    switch (color) {
      case "green":
        return Color(0xFF67AC5B);
      case "orange":
        return Color(0xFFF29500);
      case "purple":
        return Color(0xFF9654CE);
      case "red":
        return Color(0xFFDD0000);
      case "pink":
        return Color(0xFFAC5B5B);
      default:
        return Color(0xFF505050);
    }
  }

  // ─── Action Buttons per status ──────────────────────────────────────────────

  Widget _buildActionButtons(Map<String, dynamic> row) {
    final status = _getStatus(row);
    final statusLabel = status["label"] ?? "";
    final rawStatus = row["status"]?.toString() ?? "";

    // Published → View Audit
    if (statusLabel == "Published" || rawStatus == "P") {
      return _actionButton("View Audit", Color(0xFF2E77D0), () {
        Navigator.pushNamed(context, "/auditdetails",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: row));
      });
    }

    // Review → Edit + Publish
    if (statusLabel == "Review" || rawStatus == "C") {
      return Row(
        children: [
          Expanded(
            child: _actionButton("Edit", Color(0xFF535353), () {
              Navigator.pushNamed(context, "/addaudit",
                  arguments: ScreenArgument(
                      argument: ArgumentData.USER,
                      mode: "Edit",
                      mapData: allAudits,
                      editData: row));
            }, flexible: true),
          ),
          SizedBox(width: 5),
          Expanded(
            child: _actionButton("Publish", Color(0xFF67AC5B), () {
              _publishAudit(row);
            }, flexible: true),
          ),
        ],
      );
    }

    // Inprogress → Cancel
    if (statusLabel == "Inprogress" || rawStatus == "IP" || rawStatus == "PG") {
      return _actionButton("Cancel", Color(0xFF535353), () {
        _cancelAudit(row);
      });
    }

    // Upcoming → Edit
    if (statusLabel == "Upcoming" || rawStatus == "S") {
      return _actionButton("Edit", Color(0xFF535353), () {
        Navigator.pushNamed(context, "/addaudit",
            arguments: ScreenArgument(
                argument: ArgumentData.USER,
                mode: "Edit",
                mapData: allAudits,
                editData: row));
      });
    }

    // Cancelled → disabled
    if (statusLabel == "Cancelled" || rawStatus == "CL") {
      return _actionButton("Cancelled", Color(0xFFC9C9C9), null,
          textColor: Color(0xFFA09E9E));
    }

    return SizedBox.shrink();
  }

  Widget _actionButton(String label, Color bgColor, VoidCallback? onTap,
      {Color textColor = Colors.white, bool flexible = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: flexible ? null : 90,
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
                color: textColor)),
      ),
    );
  }

  void _publishAudit(dynamic row) {
    APIService(context).showWindowAlert(
        title: "Publish Audit",
        desc: "Are you sure you want to publish this audit?",
        showCancelBtn: true,
        callback: () {
          Map<String, dynamic> dataobj = {"audit_id": row["audit_id"]};
          usercontroller.publishAuditStatus(context, data: dataobj,
              callback: () async {
            _loadData();
          });
        });
  }

  void _cancelAudit(dynamic row) {
    String reason = "";
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red X icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Icon(Icons.close, color: Colors.red, size: 24),
                ),
                SizedBox(height: 16),
                // Title
                Text("Are you sure you want to cancel this Audit ?",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333))),
                SizedBox(height: 16),
                // Reason label
                Text("What is the reason ?",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666))),
                SizedBox(height: 8),
                // Text input
                TextField(
                  maxLines: 5,
                  onChanged: (val) => reason = val,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFBBBBBB))),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 20),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 120,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF535353),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text("Cancel",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Delete button
                    GestureDetector(
                      onTap: () {
                        if (reason.trim().isEmpty) {
                          APIService(context).showToastMgs("Please enter a reason");
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        Map<String, dynamic> dObj = {
                          "audit_id": row["audit_id"] ?? row["id"],
                          "remarks": reason,
                          "type": "Cancel Audit",
                          "userid": usercontroller.userData.userId,
                        };
                        usercontroller.sendAuditComments(context, data: dObj,
                            callback: () {
                          _loadData();
                        }, errorcallback: (res) {});
                      },
                      child: Container(
                        width: 120,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF67AC5B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text("Delete",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Container(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Audit List",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF505050))),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Detailed overview of all audits",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF898989))),
                      // Filters row
                      Row(
                        children: [
                          _buildFilterDropdown("State:", stateOptions,
                              selectedState, (val) {
                            setState(() {
                              selectedState = val!;
                              selectedZone = "All";
                            });
                            _applyFilter();
                          }),
                          SizedBox(width: 12),
                          _buildFilterDropdown(
                              "Zone :", zoneOptions, selectedZone, (val) {
                            setState(() => selectedZone = val!);
                            _applyFilter();
                          }),
                          SizedBox(width: 12),
                          _buildFilterDropdown(
                              "",
                              financialYears
                                  .map((e) => e["label"] as String)
                                  .toList(),
                              financialYears.firstWhere((e) => e["value"] == year)["label"]!, (val) {
                            final selected = financialYears.firstWhere((e) => e["label"] == val);
                            setState(() {
                              year = selected["value"]!;
                              selectedState = "All";
                              selectedZone = "All";
                            });
                            _loadData();
                          }),
                        ],
                      ),
                    ],
                  ),
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
              margin: EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding / 2),
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

            // Pagination
            _buildPagination(),

            SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  // ─── Table Header ───────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF8D8D8D),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _headerCell("Audit ID", flex: 2),
          _headerCell("Audit Name", flex: 3),
          _headerCell("Zone", flex: 1),
          _headerCell("State", flex: 2),
          _headerCell("City", flex: 2),
          _headerCell("Assigned to", flex: 2),
          _headerCell("Sched. Date", flex: 2),
          _headerCell("End Date", flex: 2),
          _headerCell("Status", flex: 2),
          _headerCell("Report", flex: 3, isLast: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 2, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  right: BorderSide(color: Color(0xFFBCBCBC), width: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
      ),
    );
  }

  // ─── Table Row ──────────────────────────────────────────────────────────────

  Widget _buildTableRow(Map<String, dynamic> row, int index) {
    final status = _getStatus(row);
    final statusLabel = status["label"] ?? "-";
    final statusColorStr = status["color"] ?? "grey";
    final statusColor = _statusColor(statusColorStr);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _dataCell(_getAuditId(row), flex: 2),
          _dataCell(_getAuditName(row), flex: 3),
          _dataCell((row["zone"] ?? "-").toString(), flex: 1),
          _dataCell((row["state"] ?? "-").toString(), flex: 2),
          _dataCell((row["city"] ?? "-").toString(), flex: 2),
          _dataCell(_getAssignedTo(row), flex: 2),
          _dataCell(_getSchedDate(row), flex: 2),
          _dataCell(_getEndDate(row), flex: 2),
          // Status badge
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                    right:
                        BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
              ),
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
                            fontWeight: FontWeight.w400,
                            color: statusColor)),
                  ),
                ],
              ),
            ),
          ),
          // Report / Action buttons
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: _buildActionButtons(row),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String value, {int flex = 2}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Text(value,
            style: TextStyle(fontSize: 12, color: Color(0xFF505050)),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ─── Pagination ─────────────────────────────────────────────────────────────

  Widget _buildPagination() {
    if (_totalPages <= 1) return SizedBox.shrink();

    // Show max 5 page numbers at a time, centered on current page
    int startPage = (currentPage - 2).clamp(1, _totalPages);
    int endPage = (startPage + 4).clamp(1, _totalPages);
    if (endPage - startPage < 4) {
      startPage = (endPage - 4).clamp(1, _totalPages);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _pageButton(Icons.chevron_left, currentPage > 1, () {
            setState(() => currentPage--);
          }),
          // Page numbers
          ...List.generate(endPage - startPage + 1, (i) {
            final page = startPage + i;
            final isActive = page == currentPage;
            return GestureDetector(
              onTap: () => setState(() => currentPage = page),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? Color(0xFF01ADEF) : Colors.white,
                  border: Border.all(
                      color:
                          isActive ? Color(0xFF01ADEF) : Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Text("$page",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color:
                              isActive ? Colors.white : Color(0xFF4D4F5C))),
                ),
              ),
            );
          }),
          // Next button
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
          color: Colors.white,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Color(0xFF808495) : Color(0xFFCCCCCC)),
      ),
    );
  }

  // ─── Filter Dropdown ────────────────────────────────────────────────────────

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
            icon: Icon(Icons.arrow_drop_down,
                size: 20, color: Color(0xFF505050)),
            style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
            items: items
                .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
