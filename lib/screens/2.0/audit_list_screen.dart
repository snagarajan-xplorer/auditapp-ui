import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

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
    // Safety: if callback never fires, stop loading after a timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && isLoading) setState(() => isLoading = false);
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

  // ─── Data field helpers (normalize raw getAuditList fields) ─────────────────

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
              Navigator.pushNamed(context, "/createaudit",
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
      // return _actionButton("Edit", Color(0xFF535353), () {
      //   Navigator.pushNamed(context, "/createaudit",
      //       arguments: ScreenArgument(
      //           argument: ArgumentData.USER,
      //           mode: "Edit",
      //           mapData: allAudits,
      //           editData: row));
      // });
      return Row(
        children: [
          Expanded(
            child: _actionButton("Edit", Color(0xFF535353), () {
              Navigator.pushNamed(context, "/createaudit",
                  arguments: ScreenArgument(
                      argument: ArgumentData.USER,
                      mode: "Edit",
                      mapData: allAudits,
                      editData: row));
            }, flexible: true),
          ),
          SizedBox(width: 5),
          Expanded(
            child: _actionButton("Start", Color(0xFF67AC5B), () {
              Navigator.pushNamed(context, "/auditcategorylist-v2",
                  arguments: ScreenArgument(
                      argument: ArgumentData.USER,
                      mapData: row));
            }, flexible: true),
          ),
        ],
      );
    }

    // Cancelled → Delete
    if (statusLabel == "Cancelled" || rawStatus == "CL") {
      return _actionButton("Cancelled", Color(0xFFC9C9C9), () {
      });
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
                        child: Text("Confirm",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Permanent delete button
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteAudit(dynamic row) {
    APIService(context).showWindowAlert(
        title: "Delete Audit",
        desc: "Are you sure you want to permanently delete this audit? This action cannot be undone.",
        showCancelBtn: true,
        callback: () {
          Map<String, dynamic> dObj = {
            "audit_id": row["id"] ?? row["audit_id"],
          };
          usercontroller.deleteAudit(context, data: dObj, callback: (success) {
            if (success) {
              _loadData();
            }
          });
        });
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
                          TableFilterDropdown(
                              label: "State:",
                              items: stateOptions,
                              value: selectedState,
                              onChanged: (val) {
                            setState(() {
                              selectedState = val!;
                              selectedZone = "All";
                            });
                            _applyFilter();
                          }),
                          SizedBox(width: 12),
                          TableFilterDropdown(
                              label: "Zone :",
                              items: zoneOptions,
                              value: selectedZone,
                              onChanged: (val) {
                            setState(() => selectedZone = val!);
                            _applyFilter();
                          }),
                          SizedBox(width: 12),
                          TableFilterDropdown(
                              items: financialYears
                                  .map((e) => e["label"] as String)
                                  .toList(),
                              value: financialYears.firstWhere((e) => e["value"] == year)["label"]!,
                              onChanged: (val) {
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

            // Table + Pagination
            ReusableTable(
              columns: [
                TableColumnDef(label: "Audit ID", flex: 3, key: "audit_no"),
                TableColumnDef(
                  label: "Audit Name", flex: 2,
                  cellBuilder: (row, _) => _truncatedNameCell(_getAuditName(row)),
                ),
                TableColumnDef(label: "Zone", flex: 2, key: "zone"),
                TableColumnDef(label: "State", flex: 2, key: "state"),
                TableColumnDef(label: "City", flex: 2, key: "city"),
                TableColumnDef(
                  label: "Assigned to", flex: 2,
                  cellBuilder: (row, _) => _plainCell(_getAssignedTo(row)),
                ),
                TableColumnDef(
                  label: "Sched. Date", flex: 2,
                  cellBuilder: (row, _) => _plainCell(_getSchedDate(row)),
                ),
                TableColumnDef(
                  label: "End Date", flex: 2,
                  cellBuilder: (row, _) => _plainCell(_getEndDate(row)),
                ),
                TableColumnDef(
                  label: "Status", flex: 2,
                  cellBuilder: (row, _) {
                    final s = _getStatus(row);
                    return statusBadgeCell(
                      label: s["label"] ?? "-",
                      color: s["color"] ?? "grey",
                    );
                  },
                ),
                TableColumnDef(
                  label: "Report", flex: 3, isLast: true,
                  cellBuilder: (row, _) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: _buildActionButtons(row),
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

            SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  // ─── Cell helpers (used by column cellBuilders) ────────────────────────────

  Widget _truncatedNameCell(String value) {
    final firstWord = value.split(' ').first;
    final displayText = value.contains(' ') ? '$firstWord...' : value;
    return Tooltip(
      message: value,
      waitDuration: Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Text(displayText,
            style: TextStyle(fontSize: 13, color: Color(0xFF505050)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    );
  }

  Widget _plainCell(String value) {
    return Tooltip(
      message: value,
      waitDuration: Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Text(value,
            style: TextStyle(fontSize: 13, color: Color(0xFF505050)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    );
  }
}
