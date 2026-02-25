import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import 'dart:js' as js;

class AuditDetailsScreen extends StatefulWidget {
  const AuditDetailsScreen({super.key});

  @override
  State<AuditDetailsScreen> createState() => _AuditDetailsScreenState();
}

class _AuditDetailsScreenState extends State<AuditDetailsScreen> {
  UserController usercontroller = Get.put(UserController());

  bool isLoading = true;
  Map<String, dynamic> auditData = {};

  // Passed from audit list
  Map<String, dynamic> rowData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is ScreenArgument && args.editData != null) {
        rowData = Map<String, dynamic>.from(args.editData!);
        _loadAuditDetail();
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  void _loadAuditDetail() {
    final auditId = rowData["id"] ?? rowData["audit_id"];
    if (auditId == null) {
      setState(() => isLoading = false);
      return;
    }

    Map<String, dynamic> data = {"audit_id": auditId};

    usercontroller.getAuditDetailById(context, data: data, callback: (res) {
      if (mounted) {
        setState(() {
          auditData = res;
          isLoading = false;
        });
      }
    });
  }

  void _startAudit() {
    final auditId = auditData["id"] ?? rowData["id"] ?? rowData["audit_id"];
    if (auditId == null) return;

    APIService(context).showWindowAlert(
      title: "Start Audit",
      desc: "Are you sure you want to start this audit?",
      showCancelBtn: true,
      callback: () {
        Map<String, dynamic> data = {"audit_id": auditId};
        usercontroller.startAudit(context, data: data, callback: (success) {
          if (success) {
            // Navigate to v2 stepper audit flow
            Navigator.pushNamed(context, "/auditcategorylist-v2",
                arguments: ScreenArgument(
                    argument: ArgumentData.USER, mapData: rowData));
          }
        });
      },
    );
  }

  void _cancelAudit() {
    final auditId = auditData["id"] ?? rowData["id"] ?? rowData["audit_id"];
    if (auditId == null) return;

    String reason = "";
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFDD0000), width: 1),
                  ),
                  child: Icon(Icons.close, color: Color(0xFFDD0000), size: 18),
                ),
                SizedBox(height: 16),
                Text("Are you sure you want to cancel this Audit?",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF505050))),
                SizedBox(height: 16),
                Text("What is the reason?",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF898989))),
                SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  onChanged: (val) => reason = val,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFC9C9C9))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFC9C9C9))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFC9C9C9))),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 120,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF535353),
                          borderRadius: BorderRadius.circular(4),
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
                    GestureDetector(
                      onTap: () {
                        if (reason.trim().isEmpty) {
                          APIService(context)
                              .showToastMgs("Please enter a reason");
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        Map<String, dynamic> dObj = {
                          "audit_id": auditId,
                          "remarks": reason,
                          "type": "Cancel Audit",
                          "userid": usercontroller.userData.userId,
                        };
                        usercontroller.sendAuditComments(context, data: dObj,
                            callback: () {
                          Navigator.pop(context);
                        }, errorcallback: (res) {});
                      },
                      child: Container(
                        width: 120,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF67AC5B),
                          borderRadius: BorderRadius.circular(4),
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteAudit() {
    final auditId = auditData["id"] ?? rowData["id"] ?? rowData["audit_id"];
    if (auditId == null) return;

    APIService(context).showWindowAlert(
      title: "Delete Audit",
      desc: "Are you sure you want to permanently delete this audit? This action cannot be undone.",
      showCancelBtn: true,
      callback: () {
        Map<String, dynamic> data = {"audit_id": auditId};
        usercontroller.deleteAudit(context, data: data, callback: (success) {
          if (success) {
            Navigator.pop(context);
          }
        });
      },
    );
  }

  void _downloadAuditSheet() {
    final reportUrl = auditData["reporturl"] ?? rowData["reporturl"] ?? "";
    if (reportUrl.toString().isEmpty) {
      APIService(context).showToastMgs("No audit sheet available");
      return;
    }
    js.context
        .callMethod('open', ["${API_URL}export?type=1&id=$reportUrl", "_blank"]);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getField(String key, [String fallback = "-"]) {
    return (auditData[key] ?? rowData[key] ?? fallback).toString();
  }

  String _getFormattedDate() {
    final formatted = auditData["formatted_date"];
    if (formatted != null && formatted.toString().isNotEmpty) {
      return formatted.toString();
    }
    try {
      final raw = auditData["start_date"] ?? rowData["start_date"];
      if (raw == null) return "-";
      return Jiffy.parseFromDateTime(DateTime.parse(raw.toString()))
          .format(pattern: "dd/MM/yyyy");
    } catch (_) {
      return "-";
    }
  }

  String _getFormattedTime() {
    final formatted = auditData["formatted_time"];
    if (formatted != null && formatted.toString().isNotEmpty) {
      return formatted.toString();
    }
    return (auditData["timevalue"] ?? rowData["timevalue"] ?? "-").toString();
  }

  Color _statusColor(String colorName) {
    switch (colorName) {
      case "green":
        return const Color(0xFF67AC5B);
      case "orange":
        return const Color(0xFFF29500);
      case "purple":
        return const Color(0xFF9654CE);
      case "red":
        return const Color(0xFFDD0000);
      case "pink":
        return const Color(0xFFAC5B5B);
      default:
        return const Color(0xFF505050);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: true,
      previousScreenName: "Audit List",
      backEvent: () => Navigator.pop(context),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: Color(0xFF02B2EB)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF02B2EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  // Title
                  Text("Audit Details",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))),
                  SizedBox(height: 20),

                  // Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFC9C9C9), width: 1),
                    ),
                    padding: EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Logo + Audit Name / ID / Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                // Company Logo
                                _buildCompanyLogo(),
                                SizedBox(height: 26),
                                _buildDownloadButton(),
                              ],
                            ),SizedBox(width: 40),
                            // Download Audit Sheet button
                            // Audit details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Audit Name
                                  _buildInfoField(
                                      "Audit Name", _getField("auditname")),
                                  SizedBox(height: 40),

                                  // Audit ID + Audit Date
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildInfoField("Audit ID",
                                              _getField("audit_no"))),
                                      Expanded(
                                          child: _buildInfoField(
                                              "Audit Date", _getFormattedDate())),
                                    ],
                                  ),
                                  SizedBox(height: 40),

                                  // Assigned by + Audit time
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildInfoField(
                                              "Audit assigned by",
                                              _getField("assigned_by"))),
                                      Expanded(
                                          child: _buildInfoField("Audit time",
                                              _getFormattedTime())),
                                    ],
                                  ),
                                  SizedBox(height: 40),

                                  // Auditor + Status
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildInfoField("Auditor",
                                              _getField("auditor_name"))),
                                      Expanded(child: _buildStatusField()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 44),

                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildCompanyLogo() {
    final logo = _getField("company_logo", "");
    final imgUrl = _getField("image", "");
    final logoPath = logo.isNotEmpty ? logo : imgUrl;

    return Container(
      width: 225,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFC9C9C9), width: 1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: logoPath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                "$IMG_URL$logoPath",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _logoPlaceholder(),
              ),
            )
          : _logoPlaceholder(),
    );
  }

  Widget _logoPlaceholder() {
    return Center(
      child: Icon(Icons.business, size: 48, color: Color(0xFFCCCCCC)),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF898989))),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF505050))),
      ],
    );
  }

  Widget _buildStatusField() {
    final statusLabel =
        auditData["status_label"] ?? _mapStatusLabel(auditData["status"]);
    final statusColorName =
        auditData["status_color"] ?? _mapStatusColor(auditData["status"]);
    final color = _statusColor(statusColorName.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Status",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888))),
        SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text(statusLabel.toString(),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ],
    );
  }

  String _mapStatusLabel(dynamic status) {
    const map = {
      'S': 'Upcoming',
      'PG': 'Inprogress',
      'IP': 'Inprogress',
      'C': 'Review',
      'P': 'Published',
      'CL': 'Cancelled',
    };
    return map[status?.toString()] ?? status?.toString() ?? '-';
  }

  String _mapStatusColor(dynamic status) {
    const map = {
      'S': 'purple',
      'PG': 'orange',
      'IP': 'orange',
      'C': 'pink',
      'P': 'green',
      'CL': 'red',
    };
    return map[status?.toString()] ?? 'grey';
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _downloadAuditSheet,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF02B2EB), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Download Audit Sheet",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF29B6F6))),
            SizedBox(width: 8),
            Icon(Icons.download, color: Color(0xFF29B6F6), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = auditData["status"] ?? rowData["status"] ?? "S";
    final statusStr = status.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel Audit button — for non-cancelled, non-published
        if (statusStr != "CL" && statusStr != "P")
          GestureDetector(
            onTap: _cancelAudit,
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF535353),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text("Cancel Audit",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),

        if (statusStr != "CL" && statusStr != "P") SizedBox(width: 30),

        // Start Audit button — only for Scheduled/Upcoming
        if (statusStr == "S" || statusStr == "PG")
          GestureDetector(
            onTap: _startAudit,
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF02B2EB),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text("Start Audit",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),

        // View Audit button — for Published
        if (statusStr == "P")
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/auditdetails",
                  arguments: ScreenArgument(
                      argument: ArgumentData.USER, mapData: rowData));
            },
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Color(0xFF29B6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text("View Audit",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
