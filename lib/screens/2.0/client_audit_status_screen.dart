import 'dart:async';
import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/widget/financial_year_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../responsive.dart';
import '../../widget/reusable_table.dart';

class ClientAuditStatusScreen extends StatefulWidget {
  const ClientAuditStatusScreen({super.key});

  @override
  State<ClientAuditStatusScreen> createState() =>
      _ClientAuditStatusScreenState();
}

class _ClientAuditStatusScreenState extends State<ClientAuditStatusScreen> {
  late final UserController usercontroller;
  StreamSubscription<String>? _clientSub;

  String selectedTab = "All";
  String year = "";
  List<Map<String, dynamic>> financialYears = [];

  static const Map<String, Map<String, String>> _statusMap = {
    'P': {'label': 'Published', 'color': 'green'},
    'IP': {'label': 'Inprogress', 'color': 'orange'},
    'PG': {'label': 'Inprogress', 'color': 'orange'},
    'C': {'label': 'Review', 'color': 'pink'},
    'S': {'label': 'Upcoming', 'color': 'purple'},
    'CL': {'label': 'Cancelled', 'color': 'red'},
  };

  static const List<String> _tabs = [
    "All",
    "Published",
    "Scheduled",
    "Cancelled"
  ];

  bool isLoading = false;
  List<Map<String, dynamic>> allAudits = [];
  List<Map<String, dynamic>> filteredAudits = [];
  int currentPage = 1;
  static const int pageSize = 10;

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    _clientSub = usercontroller.onClientChanged.listen((_) {
      if (mounted && ModalRoute.of(context)!.isCurrent) _loadData();
    });
    if (usercontroller.userData.role == null) {
      usercontroller.loadInitData();
    }

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

  @override
  void dispose() {
    _clientSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    Map<String, dynamic> data = {
      "client": usercontroller.userData.clientid,
      "userid": usercontroller.userData.userId,
      "role": usercontroller.userData.role,
      "month": "All",
      "year": year,
      "client_id": usercontroller.selectedClientId,
    };

    usercontroller.getAuditList(context, data: data, callback: (res) {
      allAudits = res
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
      _applyFilter();
      if (mounted) setState(() => isLoading = false);
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && isLoading) setState(() => isLoading = false);
    });
  }

  void _applyFilter() {
    List<Map<String, dynamic>> result = List.from(allAudits);

    if (selectedTab == "Published") {
      result = result.where((a) => _getRawStatus(a) == "P").toList();
    } else if (selectedTab == "Scheduled") {
      result = result.where((a) {
        final s = _getRawStatus(a);
        return s == "S" || s == "IP" || s == "PG" || s == "C";
      }).toList();
    } else if (selectedTab == "Cancelled") {
      result = result.where((a) => _getRawStatus(a) == "CL").toList();
    }

    setState(() {
      filteredAudits = result;
      currentPage = 1;
    });
  }

  String _getRawStatus(Map<String, dynamic> row) {
    final raw = row["status"];
    if (raw is Map) {
      return const {
            'Upcoming': 'S',
            'Inprogress': 'PG',
            'Published': 'P',
            'Review': 'C',
            'Completed': 'C',
            'Cancelled': 'CL',
          }[(raw["label"] ?? "").toString()] ??
          "";
    }
    return (raw ?? "").toString();
  }

  Map<String, String> _getStatus(Map<String, dynamic> row) {
    final rawStr = _getRawStatus(row);
    return _statusMap[rawStr] ?? {"label": rawStr, "color": "grey"};
  }

  String _formatDate(Map<String, dynamic> row, String key) {
    try {
      final raw = row["${key}_raw"] ?? row[key];
      if (raw == null || raw.toString().isEmpty) return "-";
      return Jiffy.parseFromDateTime(DateTime.parse(raw.toString()))
          .format(pattern: "MMM dd, yyyy");
    } catch (_) {
      return (row[key] ?? "-").toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Audit Status",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))),
                  const SizedBox(height: 4),
                  const Text("Detailed overview of all audits",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                          color: Color(0xFF898989))),
                  const SizedBox(height: 18),
                  Responsive.isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabs(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FinancialYearDropdown(
                                  value: year,
                                  items: financialYears,
                                  onChanged: (val) {
                                setState(() {
                                  year = val;
                                  selectedTab = "All";
                                });
                                _loadData();
                              }),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTabs(),
                            FinancialYearDropdown(
                                value: year,
                                items: financialYears,
                                onChanged: (val) {
                              setState(() {
                                year = val;
                                selectedTab = "All";
                              });
                              _loadData();
                            }),
                          ],
                        ),
                ],
              ),
            ),
            ReusableTable(
              columns: Responsive.isMobile(context)
                  ? [
                      TableColumnDef(
                          label: "Audit ID", flex: 2, key: "audit_no"),
                      TableColumnDef(
                          label: "Location", flex: 3, key: "location"),
                      TableColumnDef(
                          label: "Auditor", flex: 2, key: "auditor_name"),
                      TableColumnDef(
                        label: "Status",
                        flex: 2,
                        isLast: true,
                        cellBuilder: (row, _) {
                          final s = _getStatus(row);
                          return statusBadgeCell(
                            label: s["label"] ?? "-",
                            color: s["color"] ?? "grey",
                            showBorder: false,
                          );
                        },
                      ),
                    ]
                  : [
                      TableColumnDef(
                          label: "Audit ID", flex: 2, key: "audit_no"),
                      TableColumnDef(
                        label: "Sched. Date",
                        flex: 2,
                        cellBuilder: (row, _) =>
                            _plainCell(_formatDate(row, "scheduled_date")),
                      ),
                      TableColumnDef(
                        label: "Start Date",
                        flex: 2,
                        cellBuilder: (row, _) =>
                            _plainCell(_formatDate(row, "start_date")),
                      ),
                      TableColumnDef(
                        label: "End Date",
                        flex: 2,
                        cellBuilder: (row, _) =>
                            _plainCell(_formatDate(row, "end_date")),
                      ),
                      TableColumnDef(label: "Zone", flex: 2, key: "zone"),
                      TableColumnDef(label: "State", flex: 2, key: "state"),
                      TableColumnDef(label: "City", flex: 2, key: "city"),
                      TableColumnDef(
                          label: "Location", flex: 2, key: "location"),
                      TableColumnDef(
                          label: "Type of Location",
                          flex: 2,
                          key: "type_of_location"),
                      TableColumnDef(
                          label: "Auditor", flex: 2, key: "auditor_name"),
                      TableColumnDef(
                        label: "Status",
                        flex: 2,
                        isLast: true,
                        cellBuilder: (row, _) {
                          final s = _getStatus(row);
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
              maxVisiblePages: 8,
              headerFontWeight: FontWeight.w700,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _tabs.map((tab) {
        final isSelected = tab == selectedTab;
        return GestureDetector(
          onTap: () {
            setState(() => selectedTab = tab);
            _applyFilter();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? const Color(0xFF02B2EB)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF02B2EB)
                    : const Color(0xFF898989),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _plainCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: const BoxDecoration(
        border:
            Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
      ),
      child: Text(value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF505050)),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    );
  }
}
