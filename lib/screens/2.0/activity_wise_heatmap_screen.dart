import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/usercontroller.dart';
import '../../constants.dart';
import '../../widget/financial_year_dropdown.dart';
import '../../widget/reusable_table.dart';
import '../main/layoutscreen.dart';

class ActivityWiseHeatmapScreen extends StatefulWidget {
  const ActivityWiseHeatmapScreen({super.key});

  @override
  State<ActivityWiseHeatmapScreen> createState() =>
      _ActivityWiseHeatmapScreenState();
}

class _ActivityWiseHeatmapScreenState extends State<ActivityWiseHeatmapScreen> {
  late final UserController usercontroller;

  List<Map<String, dynamic>> financialYears = [];
  String selectedFinancialYear = "";
  bool isLoading = true;

  // API response data
  List<dynamic> zones = [];
  Map<String, dynamic> allIndia = {};
  List<String> activities = [];
  int currentPage = 1;
  static const int pageSize = 10;



  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    _initFinancialYears();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchActivitiesList();
        _fetchHeatmapData();
      }
    });
  }

  void _fetchActivitiesList() {
    usercontroller.getActivitiesList(context, callback: (list) {
      if (!mounted || list.isEmpty) return;
      if (activities.isEmpty) {
        setState(() => activities = list);
      }
    });
  }

  void _initFinancialYears() {
    final now = DateTime.now();
    int startYear = now.month < 4 ? now.year - 1 : now.year;
    for (int i = 0; i < 5; i++) {
      int y = startYear - i;
      String label = "FY$y-${(y + 1).toString().substring(2)}";
      financialYears.add({"label": label, "value": label});
    }
    selectedFinancialYear = financialYears.first["value"];
  }

  void _fetchHeatmapData() {
    if (!mounted) return;
    setState(() => isLoading = true);
    usercontroller.getActivityWiseHeatmap(context, data: {
      "financial_year": selectedFinancialYear,
    }, callback: (res) {
      if (!mounted) return;
      if (res != null && res is Map<String, dynamic>) {
        final newActivities = List<String>.from(res['activities'] ?? []);
        setState(() {
          zones = res['zones'] ?? [];
          allIndia = res['all_india'] ?? {};
          if (newActivities.isNotEmpty) activities = newActivities;
          isLoading = false;
        });
      } else {
        setState(() {
          zones = [];
          allIndia = {};
          isLoading = false;
        });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      child: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: defaultPadding),
              _buildHeatmapTable(),
              const SizedBox(height: 32),
              if (!isLoading) _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Heatmap – Activity Wise (All India)",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF505050),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "See the Risk. Strengthen the Control",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w100,
                    color: Color(0xFF898989),
                  ),
                ),
              ],
            ),
          ),
          FinancialYearDropdown(
            value: selectedFinancialYear,
            items: financialYears,
            onChanged: (value) {
              if (value != selectedFinancialYear) {
                selectedFinancialYear = value;
                _fetchHeatmapData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapTable() {
    final List<Map<String, dynamic>> tableRows = zones
        .map<Map<String, dynamic>>((z) => Map<String, dynamic>.from(z))
        .toList();
    if (allIndia.isNotEmpty) {
      final indiaRow = Map<String, dynamic>.from(allIndia);
      indiaRow['zone'] = 'All India';
      indiaRow['_isAllIndia'] = true;
      tableRows.add(indiaRow);
    }

    return ReusableTable(
      columns: [
        TableColumnDef(
          label: "Zone",
          flex: 2,
          cellBuilder: (row, _) {
            final isAllIndia = row['_isAllIndia'] == true;
            return _plainCell(
              isAllIndia ? "All India" : (row['zone'] ?? '-').toString(),
              bold: isAllIndia,
            );
          },
        ),
        TableColumnDef(
          label: "States & UTs",
          flex: 2,
          cellBuilder: (row, _) => _plainCell(
            '${row['total_states'] ?? '-'}',
            bold: row['_isAllIndia'] == true,
          ),
        ),
        TableColumnDef(
          label: "Locations",
          flex: 2,
          cellBuilder: (row, _) => _plainCell(
            '${row['total_locations'] ?? '-'}',
            bold: row['_isAllIndia'] == true,
          ),
        ),
        ...activities.asMap().entries.map((entry) {
          final activity = entry.value;
          final isLast = entry.key == activities.length - 1;
          return TableColumnDef(
            label: activity,
            flex: 2,
            isLast: isLast,
            headerGroup: "Activities",
            cellBuilder: (row, _) {
              final activityList =
                  List<dynamic>.from(row['activities'] ?? []);
              final activityData = activityList.firstWhere(
                (a) => a['heading'] == activity,
                orElse: () => {'score': null},
              );
              return _scoreBadgeCell(activityData['score']);
            },
          );
        }),
      ],
      rows: tableRows,
      isLoading: isLoading,
      currentPage: currentPage,
      pageSize: pageSize,
      onPageChanged: (page) => setState(() => currentPage = page),
      headerFontWeight: FontWeight.w700,
    );
  }

  Widget _plainCell(String value, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF505050),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _scoreBadgeCell(dynamic score) {
    final color = colorForScore(score);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.center,
      child: Container(
        height: 33,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Activities Legend",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF505050),
            ),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFC9C9C9), width: 1),
            defaultColumnWidth: const FlexColumnWidth(),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
            },
            children: [
                // Header: Color Badge | Not Complied | Partly... | Complied | N/A
                TableRow(
                  children: [
                    _legendHeaderCell("Color Badge"),
                    _legendColorCell(scoreColors[0], "Not Complied"),
                    _legendColorCell(scoreColors[1], "Partly Complied"),
                    _legendColorCell(scoreColors[2], "Partly Complied"),
                    _legendColorCell(scoreColors[3], "Partly Complied"),
                    _legendColorCell(scoreColors[4], "Complied"),
                    _legendColorCell(const Color(0xFFC9C9C9), "Not Applicable"),
                  ],
                ),
                // Score row
                TableRow(
                  children: [
                    _legendHeaderCell("Score"),
                    _legendScoreCell("0", scoreColors[0]),
                    _legendScoreCell("1", scoreColors[1]),
                    _legendScoreCell("2", scoreColors[2]),
                    _legendScoreCell("3", scoreColors[3]),
                    _legendScoreCell("4", scoreColors[4]),
                    _legendTextCell("N/A"),
                  ],
                ),
                // Performance range row
                TableRow(
                  children: [
                    _legendHeaderCell("Performance Range"),
                    _legendTextCell("Upto 20%"),
                    _legendTextCell("21% to 50%"),
                    _legendTextCell("51% to 75%"),
                    _legendTextCell("76% to 99%"),
                    _legendTextCell("100%"),
                    _legendTextCell("N/A"),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legendHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFFFFF),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF08284E),
        ),
      ),
    );
  }

  Widget _legendColorCell(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  Widget _legendScoreCell(String score, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.center,
      child: Text(
        score,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  Widget _legendTextCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      color: Color(0xFFFFFFFF),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF000000)),
      ),
    );
  }
}
