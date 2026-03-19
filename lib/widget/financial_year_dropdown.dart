import 'package:flutter/material.dart';

class FinancialYearDropdown extends StatelessWidget {
  /// Currently selected FY value, e.g. "FY2025-26".
  /// When null the first generated year is shown.
  final String? value;

  /// Called when the user picks a different year.
  final ValueChanged<String> onChanged;

  /// Number of financial years to generate (default 5).
  final int yearCount;

  /// Optional fixed list of items (label/value maps).
  /// When provided, auto-generation is skipped.
  final List<Map<String, dynamic>>? items;

  const FinancialYearDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.yearCount = 5,
    this.items,
  });

  /// Builds the standard Indian FY list starting from the current FY.
  static List<Map<String, String>> generateFinancialYears({int count = 5}) {
    final now = DateTime.now();
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    return List.generate(count, (i) {
      final y = fyStartYear - i;
      final label = "FY$y-${(y + 1).toString().substring(2)}";
      return {"label": label, "value": label};
    });
  }

  @override
  Widget build(BuildContext context) {
    final fyList = items ?? generateFinancialYears(count: yearCount);

    if (fyList.isEmpty) return const SizedBox.shrink();

    final selected = value ?? fyList.first["value"]!;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC9C9C9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selected,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down,
            size: 20, color: Color(0xFF505050)),
        style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
        items: fyList.map((item) {
          return DropdownMenuItem<String>(
            value: item["value"],
            child: Text(item["label"]!),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
