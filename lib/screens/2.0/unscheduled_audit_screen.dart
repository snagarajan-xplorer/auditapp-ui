import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

class UnScheduledAuditScreen extends StatefulWidget {
  const UnScheduledAuditScreen({super.key});

  @override
  State<UnScheduledAuditScreen> createState() => _UnScheduledAuditScreenState();
}

class _UnScheduledAuditScreenState extends State<UnScheduledAuditScreen> {
  UserController usercontroller = Get.put(UserController());

  // Filter state
  String selectedFinancialYear = "";
  List<Map<String, dynamic>> financialYears = [];

  // Table data
  bool isLoading = false;
  List<dynamic> allRecords = [];
  int currentPage = 1;
  final int pageSize = 10;


  @override
  void initState() {
    super.initState();

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

  // ── API: load table rows ─────────────────────────────────────────────────
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

    final data = {
      "year": yearParam,
      "userid": usercontroller.userData.userId,
      "role": role,
      if (!isAdminRole) "client": usercontroller.userData.clientid,
      if (!isAdminRole)
        "client_id": usercontroller.userData.clientid?.isNotEmpty == true
            ? usercontroller.userData.clientid!.first
            : null,
    };
    await usercontroller.getUnScheduledAuditDetails(context, data: data,
        callback: (list, total) {
      if (mounted) {
        setState(() {
          allRecords = list;
          isLoading = false;
          currentPage = 1;
        });
      }
    });
    if (mounted && isLoading) setState(() => isLoading = false);
  }

  // ── API: delete row ──────────────────────────────────────────────────────
  Future<void> _confirmDelete(dynamic row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red X icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFDD0000), width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                "Are you sure ?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF505050),
                ),
              ),
              const SizedBox(height: 12),
              // Description lines
              const Text(
                "Do you really want to delete these unscheduled audit?",
                style: TextStyle(fontSize: 14, color: Color(0xFF898989)),
              ),
              const SizedBox(height: 6),
              const Text(
                "This process cannot be undone",
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(height: 28),
              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF535353),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67AC5B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text("Delete",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await usercontroller.deleteUnScheduledAudit(
        context,
        data: {"id": row["id"]},
        callback: (success) {
          if (success) _loadData();
        },
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Un-scheduled Audit Details",
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
                  // FY dropdown
                  TableFilterDropdown(
                    items: financialYears.map((e) => e["label"] as String).toList(),
                    value: financialYears.firstWhere(
                        (e) => e["value"] == selectedFinancialYear)["label"]!,
                    onChanged: (val) {
                      if (val != null) {
                        final selected = financialYears.firstWhere((e) => e["label"] == val);
                        setState(() => selectedFinancialYear = selected["value"]!);
                        _loadData();
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Table + Pagination ─────────────────────────────────────────
            ReusableTable(
              columns: [
                TableColumnDef(label: "Client", flex: 4, key: "client"),
                TableColumnDef(label: "Zone", flex: 2, key: "zone"),
                TableColumnDef(label: "State", flex: 3, key: "state"),
                TableColumnDef(label: "City", flex: 2, key: "city"),
                TableColumnDef(label: "Location", flex: 3, key: "location"),
                TableColumnDef(label: "Type of Location", flex: 3, key: "type_of_location"),
                TableColumnDef(label: "Created by", flex: 3, key: "created_by"),
                TableColumnDef(
                  label: "Audit Status", flex: 3,
                  cellBuilder: (row, _) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                          right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/createaudit', arguments: {
                          "client_id":        row["client_id"],
                          "client":           row["client"],
                          "zone":             row["zone"],
                          "state":            row["state"],
                          "city":             row["city"],
                          "location":         row["location"],
                          "type_of_location": row["type_of_location"],
                          "unscheduled_id":   row["id"],
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67AC5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      child: const Text("Schedule Audit",
                          maxLines: 1, softWrap: false,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
                    ),
                  ),
                ),
                TableColumnDef(
                  label: "Delete", flex: 2, isLast: true,
                  cellBuilder: (row, _) => Center(
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF505050), size: 20),
                      onPressed: () => _confirmDelete(row),
                    ),
                  ),
                ),
              ],
              rows: allRecords,
              isLoading: isLoading,
              currentPage: currentPage,
              pageSize: pageSize,
              cellVerticalPadding: 20,
              cellHorizontalPadding: 12,
              cellFontSize: 13,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
