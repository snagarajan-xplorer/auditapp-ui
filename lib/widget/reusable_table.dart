import 'package:flutter/material.dart';
import '../constants.dart';

// ─── Column definition ──────────────────────────────────────────────────────

/// Describes a single column in a [ReusableTable].
///
/// * [label]  – header text.
/// * [flex]   – flex weight used by `Expanded`.
/// * [key]    – data-map key to read a plain text value from a row.
///             Ignored when [cellBuilder] is supplied.
/// * [cellBuilder] – optional custom builder for this column's data cell.
///                   Receives the entire row so it can render anything
///                   (status badges, action buttons, delete icons …).
/// * [isLast] – when `true` the right-side separator is omitted.
class TableColumnDef {
  final String label;
  final int flex;
  final String? key;
  final Widget Function(dynamic row, int index)? cellBuilder;
  final bool isLast;
  final String? headerGroup;

  const TableColumnDef({
    required this.label,
    this.flex = 2,
    this.key,
    this.cellBuilder,
    this.isLast = false,
    this.headerGroup,
  });
}

// ─── Reusable table widget ──────────────────────────────────────────────────

/// A drop-in, styled table with built-in pagination used across the 2.0 screens.
///
/// **Usage**:
/// ```dart
/// ReusableTable(
///   columns: [ TableColumnDef(label: 'Name', flex: 3, key: 'name'), ... ],
///   rows: myDataList,
///   isLoading: isLoading,
///   currentPage: currentPage,
///   pageSize: 10,
///   onPageChanged: (page) => setState(() => currentPage = page),
/// )
/// ```
class ReusableTable extends StatelessWidget {
  /// Column definitions (headers + cell mapping).
  final List<TableColumnDef> columns;

  /// The *already-filtered* data list.  Pagination is applied internally.
  final List<dynamic> rows;

  /// Show a centered spinner instead of rows.
  final bool isLoading;

  /// 1-based current page index.
  final int currentPage;

  /// Rows per page  (default 10).
  final int pageSize;

  /// Called when the user taps a page button.
  final ValueChanged<int> onPageChanged;

  /// Maximum number of page-number buttons to show (0 = show all).
  final int maxVisiblePages;

  /// Header font weight (allows screens to customise).
  final FontWeight headerFontWeight;

  /// Vertical padding inside data cells.
  final double cellVerticalPadding;

  /// Font size inside data cells.
  final double cellFontSize;

  /// Horizontal padding inside header/data cells.
  final double cellHorizontalPadding;

  const ReusableTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.isLoading,
    required this.currentPage,
    required this.onPageChanged,
    this.pageSize = 10,
    this.maxVisiblePages = 0,
    this.headerFontWeight = FontWeight.w400,
    this.cellVerticalPadding = 18,
    this.cellFontSize = 13,
    this.cellHorizontalPadding = 10,
  });

  // ── derived ───────────────────────────────────────────────────────────────

  int get _totalPages => rows.isEmpty ? 1 : (rows.length / pageSize).ceil();

  List<dynamic> get _pagedRows {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: defaultPadding / 2),
          child: isLoading
              ? const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              : rows.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text("No records found",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF898989))),
                      ),
                    )
                  : Column(
                      children: [
                        _buildTableHeader(),
                        ..._pagedRows
                            .asMap()
                            .entries
                            .map((e) => _buildTableRow(e.value, e.key)),
                      ],
                    ),
        ),

        // Pagination
        _buildPagination(),
      ],
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    final hasGroups = columns.any((c) => c.headerGroup != null);
    if (!hasGroups) return _buildSingleRowHeader();
    return _buildGroupedHeader();
  }

  Widget _buildSingleRowHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8D8D8D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: columns.map((col) => _headerCell(col)).toList(),
      ),
    );
  }

  Widget _buildGroupedHeader() {
    const double topHeight = 40;
    const double bottomHeight = 36;
    const double fullHeight = topHeight + bottomHeight;
    const Color headerBg = Color(0xFF8D8D8D);
    const Color borderColor = Color(0xFFBCBCBC);

    final List<_HeaderSegment> segments = [];
    for (final col in columns) {
      if (col.headerGroup == null) {
        segments.add(_HeaderSegment(columns: [col], groupLabel: null));
      } else if (segments.isNotEmpty &&
          segments.last.groupLabel == col.headerGroup) {
        segments.last.columns.add(col);
      } else {
        segments
            .add(_HeaderSegment(columns: [col], groupLabel: col.headerGroup));
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((seg) {
          final totalFlex =
              seg.columns.fold<int>(0, (sum, c) => sum + c.flex);
          final isLastSeg = seg.columns.last.isLast;

          if (seg.groupLabel == null) {
            final col = seg.columns.first;
            return Expanded(
              flex: col.flex,
              child: Container(
                height: fullHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: col.isLast
                      ? null
                      : const Border(
                          right:
                              BorderSide(color: borderColor, width: 1)),
                ),
                child: Text(
                  col.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: headerFontWeight,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }

          return Expanded(
            flex: totalFlex,
            child: Column(
              children: [
                Container(
                  height: topHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          const BorderSide(color: borderColor, width: 1),
                      right: isLastSeg
                          ? BorderSide.none
                          : const BorderSide(
                              color: borderColor, width: 1),
                    ),
                  ),
                  child: Text(
                    seg.groupLabel!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: headerFontWeight,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: bottomHeight,
                  child: Row(
                    children: seg.columns.map((col) {
                      return Expanded(
                        flex: col.flex,
                        child: Container(
                          height: bottomHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: col.isLast
                                ? null
                                : const Border(
                                    right: BorderSide(
                                        color: borderColor, width: 1)),
                          ),
                          child: Text(
                            col.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: headerFontWeight,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _headerCell(TableColumnDef col) {
    return Expanded(
      flex: col.flex,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 12, horizontal: cellHorizontalPadding),
        decoration: BoxDecoration(
          border: col.isLast
              ? null
              : const Border(
                  right: BorderSide(color: Color(0xFFBCBCBC), width: 1)),
        ),
        child: Text(
          col.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: headerFontWeight,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── data row ──────────────────────────────────────────────────────────────

  Widget _buildTableRow(dynamic row, int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columns.map((col) {
          // If the column has a custom cell builder, use it.
          if (col.cellBuilder != null) {
            return Expanded(flex: col.flex, child: col.cellBuilder!(row, index));
          }
          // Default: plain text cell read from the row map via [key].
          final value = _resolveValue(row, col.key);
          return _dataCell(value, col);
        }).toList(),
        ),
      ),
    );
  }

  String _resolveValue(dynamic row, String? key) {
    if (key == null) return "-";
    if (row is Map) return (row[key] ?? "-").toString();
    return "-";
  }

  Widget _dataCell(String value, TableColumnDef col) {
    return Expanded(
      flex: col.flex,
      child: Tooltip(
        message: value,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: cellVerticalPadding, horizontal: cellHorizontalPadding),
          decoration: BoxDecoration(
            border: col.isLast
                ? null
                : const Border(
                    right:
                        BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: cellFontSize, color: const Color(0xFF505050)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  // ── pagination ────────────────────────────────────────────────────────────

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    int startPage = 1;
    int endPage = _totalPages;

    if (maxVisiblePages > 0 && _totalPages > maxVisiblePages) {
      final half = maxVisiblePages ~/ 2;
      startPage = (currentPage - half).clamp(1, _totalPages);
      endPage = (startPage + maxVisiblePages - 1).clamp(1, _totalPages);
      if (endPage - startPage < maxVisiblePages - 1) {
        startPage = (endPage - maxVisiblePages + 1).clamp(1, _totalPages);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageButton(Icons.chevron_left, currentPage > 1, () {
            onPageChanged(currentPage - 1);
          }),
          ...List.generate(endPage - startPage + 1, (i) {
            final page = startPage + i;
            final isActive = page == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(page),
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
                  child: Text(
                    "$page",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF4D4F5C),
                    ),
                  ),
                ),
              ),
            );
          }),
          _pageButton(Icons.chevron_right, currentPage < _totalPages, () {
            onPageChanged(currentPage + 1);
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
}

class _HeaderSegment {
  final List<TableColumnDef> columns;
  final String? groupLabel;
  _HeaderSegment({required this.columns, required this.groupLabel});
}

// ─── Shared filter dropdown ─────────────────────────────────────────────────

/// The styled dropdown used across the 2.0 filter bars.
class TableFilterDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;

  const TableFilterDropdown({
    super.key,
    this.label = '',
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF505050),
                  fontWeight: FontWeight.w400)),
          const SizedBox(width: 8),
        ],
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC9C9C9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down,
                size: 20, color: Color(0xFF505050)),
            style:
                const TextStyle(fontSize: 14, color: Color(0xFF505050)),
            items: items
                .map((item) =>
                    DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Status color helper ────────────────────────────────────────────────────

/// Converts a string color name (from the API) to a [Color].
Color statusColor(String color) {
  switch (color) {
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

// ─── Status badge cell ──────────────────────────────────────────────────────

/// A colored-dot + label cell commonly used for status columns.
Widget statusBadgeCell({
  required String label,
  required String color,
  double verticalPadding = 18,
  double horizontalPadding = 10,
  bool showBorder = true,
}) {
  final dotColor = statusColor(color);
  return Container(
    padding: EdgeInsets.symmetric(
        vertical: verticalPadding, horizontal: horizontalPadding),
    decoration: showBorder
        ? const BoxDecoration(
            border: Border(
                right: BorderSide(color: Color(0xFFE0E0E0), width: 0.8)),
          )
        : null,
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: dotColor,
            ),
          ),
        ),
      ],
    ),
  );
}
