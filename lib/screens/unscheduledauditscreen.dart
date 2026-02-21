import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main/layoutscreen.dart';
import '../constants.dart';

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
  List<dynamic> get _pagedRecords {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, allRecords.length);
    return allRecords.sublist(start, end);
  }

  int get _totalPages =>
      allRecords.isEmpty ? 0 : (allRecords.length / pageSize).ceil();

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
                        Text("Un Scheduled Audit Details",
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
                  _buildFyDropdown(),
                ],
              ),
            ),

            // ── Table ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding),
              child: isLoading
                  ? const SizedBox(
                      height: 300,
                      child:
                          Center(child: CircularProgressIndicator()))
                  : allRecords.isEmpty
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text("No records found",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF898989))),
                          ))
                      : Column(
                          children: [
                            _buildTableHeader(),
                            ..._pagedRecords
                                .asMap()
                                .entries
                                .map((e) =>
                                    _buildTableRow(e.value, e.key))
                                .toList(),
                          ],
                        ),
            ),

            _buildPagination(),

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  // ── Table header ─────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8D8D8D),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _headerCell("Client",          flex: 4),
          _headerCell("Zone",            flex: 2),
          _headerCell("State",           flex: 3),
          _headerCell("City",            flex: 2),
          _headerCell("Location",        flex: 3),
          _headerCell("Type of Location",flex: 3),
          _headerCell("Created by",      flex: 3),
          _headerCell("Audit Status",    flex: 3),
          _headerCell("Delete",          flex: 2, isLast: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 2, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  right: BorderSide(color: Color(0xFFBCBCBC), width: 1)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white)),
      ),
    );
  }

  // ── Table row ─────────────────────────────────────────────────────────────
  Widget _buildTableRow(dynamic row, int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _dataCell(row["client"]           ?? "-", flex: 4),
          _dataCell(row["zone"]             ?? "-", flex: 2),
          _dataCell(row["state"]            ?? "-", flex: 3),
          _dataCell(row["city"]             ?? "-", flex: 2),
          _dataCell(row["location"]         ?? "-", flex: 3),
          _dataCell(row["type_of_location"] ?? "-", flex: 3),
          _dataCell(row["created_by"]       ?? "-", flex: 3),
          // Audit Status — green "Create Audit" button
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: Color(0xFFE0E0E0), width: 1)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  elevation: 0, 
                ),
                child: const Text("Schedule Audit",
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400)),
              ),
            ),
          ),
          // Delete icon
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFF505050), size: 20),
                onPressed: () => _confirmDelete(row),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String value, {int flex = 2}) {
    final display = value.length > 13 ? '${value.substring(0, 13)}...' : value;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
              right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
        ),
        child: Tooltip(
          message: value,
          preferBelow: true,
          child: Text(display,
              style: const TextStyle(fontSize: 12, color: Color(0xFF505050)),
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding, vertical: 12),
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
                  color: isActive
                      ? const Color(0xFF01ADEF)
                      : Colors.white,
                  border: Border.all(
                      color: isActive
                          ? const Color(0xFF01ADEF)
                          : const Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Text("$page",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF4D4F5C))),
                ),
              ),
            );
          }),
          _pageButton(Icons.chevron_right, currentPage < _totalPages,
              () {
            setState(() => currentPage++);
          }),
        ],
      ),
    );
  }

  Widget _pageButton(
      IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD7DAE2)),
          color: Colors.white,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? const Color(0xFF808495)
                : const Color(0xFFCCCCCC)),
      ),
    );
  }

  // ── FY Dropdown ───────────────────────────────────────────────────────────
  Widget _buildFyDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC9C9C9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedFinancialYear,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down,
            size: 20, color: Color(0xFF505050)),
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF505050)),
        items: financialYears
            .map((e) => DropdownMenuItem<String>(
                value: e["value"] as String,
                child: Text(e["label"] as String)))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => selectedFinancialYear = val);
            _loadData();
          }
        },
      ),
    );
  }
}
