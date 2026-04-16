import 'dart:math';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/app_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../../responsive.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AuditDetailsScreen extends StatefulWidget {
  const AuditDetailsScreen({super.key});

  @override
  State<AuditDetailsScreen> createState() => _AuditDetailsScreenState();
}

class _AuditDetailsScreenState extends State<AuditDetailsScreen> {
  late final UserController usercontroller;

  bool isLoading = true;
  Map<String, dynamic> auditData = {};

  // Passed from audit list
  Map<String, dynamic> rowData = {};

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is ScreenArgument) {
        if (args.editData != null) {
          rowData = Map<String, dynamic>.from(args.editData!);
        } else if (args.mapData != null) {
          rowData = Map<String, dynamic>.from(args.mapData!);
        }
        if (rowData.isNotEmpty) {
          _loadAuditDetail();
        } else {
          setState(() => isLoading = false);
        }
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
            Navigator.pushNamed(context, "/auditcategorylist",
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
            width: min(500, MediaQuery.of(context).size.width - 40),
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
                  child: const Icon(Icons.close, color: Color(0xFFDD0000), size: 18),
                ),
                const SizedBox(height: 16),
                const Text("Are you sure you want to cancel this Audit?",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF505050))),
                const SizedBox(height: 16),
                AppFormStyles.fieldLabel('What is the reason?'),
                TextField(
                  maxLines: 5,
                  onChanged: (val) => reason = val,
                  decoration: AppFormStyles.inputDecoration(),
                ),
                const SizedBox(height: 20),
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

  /* void _deleteAudit() {
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
  } */

  bool get _isAuditCompleted {
    final status = _resolveStatusCode();
    return status == "C" || status == "P";
  }

  void _downloadAuditSheet({String copyType = 'admin'}) {
    final reportUrl = auditData["reporturl"] ?? rowData["reporturl"] ?? "";
    if (reportUrl.toString().isEmpty) {
      APIService(context).showToastMgs(_isAuditCompleted ? "No audit report available" : "No audit sheet available");
      return;
    }
    final type = _isAuditCompleted ? 2 : 1;
    final copyParam = _isAuditCompleted ? "&copy=$copyType" : "";
    launchUrl(Uri.parse("${API_URL}export?type=$type&id=$reportUrl$copyParam"));
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
              padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 50, vertical: 16),
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
                  const SizedBox(height: 12),
                  // Title
                  const Text("Audit Details",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))),
                  const SizedBox(height: 20),

                  // Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFC9C9C9), width: 1),
                    ),
                    padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Responsive.isMobile(context)
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildCompanyLogo(),
                                  const SizedBox(height: 16),
                                  _buildDownloadButton(),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Audit Name", _getField("auditname")),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Audit ID", _getField("audit_no")),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Audit Date", _getFormattedDate()),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Audit assigned by", _getField("assigned_by")),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Audit time", _getFormattedTime()),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Assigned to", _getField("assigned_to")),
                                  const SizedBox(height: 24),
                                  _buildInfoField("Auditor", _getField("auditor_name")),
                                  const SizedBox(height: 24),
                                  _buildStatusField(),
                                ],
                              )
                            : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                _buildCompanyLogo(),
                                SizedBox(height: 26),
                                _buildDownloadButton(),
                              ],
                            ),SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoField("Audit Name", _getField("auditname")),
                                  SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoField("Audit ID", _getField("audit_no"))),
                                      Expanded(child: _buildInfoField("Audit Date", _getFormattedDate())),
                                    ],
                                  ),
                                  SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoField("Audit assigned by", _getField("assigned_by"))),
                                      Expanded(child: _buildInfoField("Audit time", _getFormattedTime())),
                                    ],
                                  ),
                                  SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoField("Assigned to", _getField("assigned_to"))),
                                      Expanded(child: _buildInfoField("Auditor", _getField("auditor_name"))),
                                    ],
                                  ),
                                  SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatusField()),
                                      Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 44),

                        Center(child: _buildActionButtons()),
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
    final imagePath = _getField("image", "");
    final logoPath = logo.isNotEmpty ? logo : imagePath;

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
                imgUrl(logoPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _logoPlaceholder(),
              ),
            )
          : _logoPlaceholder(),
    );
  }

  Widget _logoPlaceholder() {
    return Center(
      child: Icon(Icons.business, size: 48, color: const Color(0xFFCCCCCC)),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF898989))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF505050))),
      ],
    );
  }

  Widget _buildStatusField() {
    final statusCode = _resolveStatusCode();
    final statusLabel =
        auditData["status_label"] ?? _mapStatusLabel(statusCode);
    final statusColorName =
        auditData["status_color"] ?? _mapStatusColor(statusCode);
    final color = _statusColor(statusColorName.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Status",
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888))),
        const SizedBox(height: 4),
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
            const SizedBox(width: 6),
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

  bool get _hasAdminOverride {
    return auditData["has_admin_override"] == true;
  }

  Widget _buildDownloadButton() {
    if (_isAuditCompleted) {
      final label = _isAdmin ? "Download Auditor Report" : "Download Audit Report";
      final copyType = _hasAdminOverride ? 'admin' : 'auditor';
      return _buildDownloadButtonWidget(label, () => _downloadAuditSheet(copyType: copyType));
    }
    return _buildDownloadButtonWidget("Download Audit Sheet", _downloadAuditSheet);
  }

  Widget _buildDownloadButtonWidget(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF02B2EB), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
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

  /// Resolve status to a raw code string (e.g. "S", "P", "PG") regardless of
  /// whether the source is a raw code or a Map {"label":...,"color":...}.
  String _resolveStatusCode() {
    // Prefer freshly-fetched API data
    final apiStatus = auditData["status"];
    if (apiStatus is String && apiStatus.isNotEmpty) return apiStatus;

    // Fallback to row data passed from navigation
    final rowStatus = rowData["status"];
    if (rowStatus is String && rowStatus.isNotEmpty) return rowStatus;
    if (rowStatus is Map) {
      final label = (rowStatus["label"] ?? "").toString();
      return const {
        'Upcoming': 'S',
        'Inprogress': 'PG',
        'Published': 'P',
        'Review': 'C',
        'Completed': 'C',
        'Cancelled': 'CL',
      }[label] ?? 'S';
    }
    return "S";
  }

  bool get _isAdmin => menuAccessRoleAdmin.contains(usercontroller.userData.role);

  Widget _buildActionButtons() {
    final statusStr = _resolveStatusCode();

    if (_isAdmin) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          if (statusStr != "CL" && statusStr != "P")
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/auditcategorylist",
                    arguments: ScreenArgument(
                        argument: ArgumentData.USER,
                        mode: "Edit",
                        mapData: rowData)).then((_) {
                  _loadAuditDetail();
                });
              },
              child: Container(
                width: 200,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF535353),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("Edit",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
            ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 12,
      children: [
        if (statusStr == "S" || statusStr == "PG" || statusStr == "IP")
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

        if ((statusStr == "C" || statusStr == "P") && usercontroller.userData.role == "JrA")
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/auditcategorylist",
                  arguments: ScreenArgument(
                      argument: ArgumentData.USER, mode: "View", mapData: rowData));
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
