import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';

class SummaryReportScreen extends StatefulWidget {
  const SummaryReportScreen({super.key});

  @override
  State<SummaryReportScreen> createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  late final UserController usercontroller;

  bool isLoading = true;
  Map<String, dynamic> reportData = {};
  Map<String, dynamic> rowData = {};
  final Set<int> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is ScreenArgument && args.mapData != null) {
        rowData = Map<String, dynamic>.from(args.mapData!);
        _loadReport();
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  void _loadReport() {
    final auditId = rowData["id"] ?? rowData["audit_id"];
    if (auditId == null) {
      setState(() => isLoading = false);
      return;
    }

    usercontroller.getPublishedSummaryReport(context,
        data: {"audit_id": auditId}, callback: (res) {
      if (mounted) {
        setState(() {
          reportData = res;
          isLoading = false;
        });
      }
    });
  }

  void _downloadReport() {
    final url = reportData["reporturl"];
    if (url == null || url.toString().isEmpty) return;
    final downloadUrl = '${API_URL}export?key=$url';
    launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final auditNo = reportData["audit_no"] ?? rowData["audit_no"] ?? "-";

    return LayoutScreen(
      showBackbutton: false,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportData.isEmpty
              ? const Center(
                  child: Text("No report data found",
                      style: TextStyle(fontSize: 16, color: Color(0xFF898989))))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 34, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildBackButton(),
                      const SizedBox(height: 12),
                      _buildHeader(auditNo),
                      const SizedBox(height: 24),
                      _buildSummaryTable(),
                      const SizedBox(height: 24),
                      _buildAuditInfoFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 16, color: Color(0xFF02B2EB)),
          SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF02B2EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String auditNo) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Summary Report - Audit ID ($auditNo)",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF505050))),
            const SizedBox(height: 18),
            const Text("Audit results at a glance",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w100,
                    color: Color(0xFF898989))),
          ],
        ),
        GestureDetector(
          onTap: _downloadReport,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF02B2EB), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, color: Color(0xFF02B2EB), size: 18),
                SizedBox(width: 6),
                Text("Download Report",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF02B2EB))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _badgeColorForPercentage(num pct) {
    if (pct >= 90) return const Color(0xFF5EC2FF);
    if (pct >= 75) return const Color(0xFFFFB552);
    if (pct >= 50) return const Color(0xFFA4DD5A);
    if (pct >= 25) return const Color(0xFFFFFD55);
    return const Color(0xFFD1D1D1);
  }

  Widget _buildSummaryTable() {
    final summary = (reportData["summary"] as List?) ?? [];
    if (summary.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 900;
        final tableWidget = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _summaryHeaderRow(),
              ...summary.asMap().entries.expand((e) {
                final idx = e.key;
                final item = e.value;
                final isExpanded = _expandedCategories.contains(idx);
                final subItems = (item["sub_items"] as List?) ?? [];
                return [
                  _summaryDataRow(item, idx, subItems.isNotEmpty),
                  if (isExpanded)
                    ...subItems
                        .asMap()
                        .entries
                        .map((se) => _summarySubRow(se.value, idx, se.key)),
                ];
              }),
              _summaryTotalRow(summary),
            ],
          ),
        );

        if (minTableWidth <= constraints.maxWidth) return tableWidget;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minTableWidth, child: tableWidget),
        );
      },
    );
  }

  Widget _summaryHeaderRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8D8D8D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCell("#", 1),
            _headerCell("Activity", 2),
            _headerCell("Activity in Brief", 5),
            _headerCell("Applicable\nRating", 2),
            _headerCell("Secured\nRating", 2),
            _headerCell("Secured\n%", 1),
            _headerCell("Color\nBadge", 1, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, int flex, {bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  right: BorderSide(color: Color(0xFFBCBCBC), width: 1)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }

  Widget _summaryDataRow(dynamic item, int index, bool hasChildren) {
    final applicable = (item["total"] as num?) ?? 0;
    final secured = (item["answer"] as num?) ?? 0;
    final pct = (item["percentage"] as num?) ?? 0;
    final badgeColor = _badgeColorForPercentage(pct);
    final isExpanded = _expandedCategories.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFE8F4FD) : null,
        border: const Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hasChildren
                  ? () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(index);
                        } else {
                          _expandedCategories.add(index);
                        }
                      });
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                      right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasChildren)
                      Icon(
                        isExpanded
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        color: const Color(0xFF29B6F6),
                        size: 18,
                      ),
                    if (hasChildren) const SizedBox(width: 4),
                    Text("${index + 1}.0",
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF505050))),
                  ],
                ),
              ),
            ),
          ),
          _dataCell(item["heading"]?.toString() ?? "-", 2,
              align: TextAlign.left),
          _dataCell(item["categoryname"]?.toString() ?? "-", 5,
              align: TextAlign.left),
          _dataCell(
              "${applicable is double ? applicable.toInt() : applicable}", 2),
          _dataCell("${secured is double ? secured.toInt() : secured}", 2),
          _dataCell("$pct%", 1),
          _badgeCell(badgeColor),
        ],
      ),
    );
  }

  Widget _summarySubRow(dynamic subItem, int parentIndex, int subIndex) {
    final applicable = (subItem["total"] as num?) ?? 4;
    final secured = (subItem["answer"] as num?) ?? 0;
    final pct = (subItem["percentage"] as num?) ?? 0;
    final badgeColor = _badgeColorForPercentage(pct);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border:
            Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
              ),
              child: Center(
                child: Text("${parentIndex + 1}.${subIndex + 1}",
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF707070))),
              ),
            ),
          ),
          _dataCell("", 2, align: TextAlign.left),
          _dataCell(subItem["question"]?.toString() ?? "-", 5,
              align: TextAlign.left),
          _dataCell(
              "${applicable is double ? applicable.toInt() : applicable}", 2),
          _dataCell("${secured is double ? secured.toInt() : secured}", 2),
          _dataCell("$pct%", 1),
          _badgeCell(badgeColor),
        ],
      ),
    );
  }

  Widget _summaryTotalRow(List<dynamic> summary) {
    num computedApplicable = 0;
    num computedSecured = 0;

    for (var item in summary) {
      computedApplicable += (item["total"] as num?) ?? 0;
      computedSecured += (item["answer"] as num?) ?? 0;
    }

    final totalApplicable =
        (reportData["total_total"] as num?) ?? computedApplicable;
    final totalSecured =
        (reportData["total_answer"] as num?) ?? computedSecured;
    final overallPct = (reportData["overall_pct"] as num?) ??
        (totalApplicable > 0
            ? ((totalSecured / totalApplicable) * 100)
            : 0);
    final badgeColor = _badgeColorForPercentage(overallPct);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border:
            Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        children: [
          _dataCell("", 1, bold: true),
          _dataCell("Total", 2, align: TextAlign.left, bold: true),
          _dataCell("", 5),
          _dataCell(
              "${totalApplicable is double ? totalApplicable.toInt() : totalApplicable}",
              2,
              bold: true),
          _dataCell(
              "${totalSecured is double ? totalSecured.toInt() : totalSecured}",
              2,
              bold: true),
          _dataCell("$overallPct%", 1, bold: true),
          _badgeCell(badgeColor),
        ],
      ),
    );
  }

  Widget _dataCell(String value, int flex,
      {bool isLast = false,
      TextAlign align = TextAlign.center,
      bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Text(value,
            textAlign: align,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF505050))),
      ),
    );
  }

  Widget _badgeCell(Color color) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Container(
          height: 33,
          decoration: BoxDecoration(color: color),
        ),
      ),
    );
  }

  Widget _buildAuditInfoFooter() {
    final infoItems = [
      {"label": "Audit ID", "value": reportData["audit_no"]?.toString() ?? "-"},
      {"label": "Zone", "value": reportData["zone"]?.toString() ?? "-"},
      {"label": "State", "value": reportData["state"]?.toString() ?? "-"},
      {"label": "City", "value": reportData["city"]?.toString() ?? "-"},
      {
        "label": "Audited by",
        "value": reportData["auditor_name"]?.toString() ?? "-"
      },
      {
        "label": "Audited on",
        "value": _formatDateStr(reportData["start_date"])
      },
      {
        "label": "Published on",
        "value": reportData["publish_date"]?.toString() ?? "-"
      },
      {
        "label": "Published by",
        "value": reportData["publisher_name"]?.toString() ?? "-"
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minInfoWidth = 900;
        final infoWidget = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF8D8D8D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: infoItems.map((item) {
                    return Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: item != infoItems.last
                            ? const BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Color(0xFFBCBCBC), width: 1)),
                              )
                            : null,
                        child: Text(item["label"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Row(
                children: infoItems.map((item) {
                  return Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: item != infoItems.last
                          ? const BoxDecoration(
                              border: Border(
                                  right: BorderSide(
                                      color: Color(0xFFE0E0E0), width: 0.8)),
                            )
                          : null,
                      child: Text(item["value"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF505050))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

        if (minInfoWidth <= constraints.maxWidth) return infoWidget;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minInfoWidth, child: infoWidget),
        );
      },
    );
  }

  String _formatDateStr(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return "-";
    try {
      final dt = DateTime.parse(raw.toString());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
