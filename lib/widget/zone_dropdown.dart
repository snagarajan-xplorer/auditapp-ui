import 'package:audit_app/controllers/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ZoneDropdown extends StatefulWidget {
  /// Currently selected zone value.
  final String value;

  /// Fires when the user picks a different zone.
  final ValueChanged<String?> onChanged;

  final String label;

  final List<dynamic>? allData;

  final String? stateFilter;

  final String zoneKey;

  final String stateKey;

  final bool includeAll;

  final bool fromApi;

  const ZoneDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '',
    this.allData,
    this.stateFilter,
    this.zoneKey = 'zone',
    this.stateKey = 'state',
    this.includeAll = true,
    this.fromApi = false,
  });

  @override
  State<ZoneDropdown> createState() => _ZoneDropdownState();
}

class _ZoneDropdownState extends State<ZoneDropdown> {
  List<String> _apiZones = [];
  bool _apiLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromApi) _fetchZones();
  }

  void _fetchZones() {
    setState(() => _apiLoading = true);
    final uc = Get.find<UserController>();
    uc.getZone(context, callback: (zoneList) {
      if (!mounted) return;
      final zones = List<String>.from(zoneList);
      setState(() {
        _apiZones = zones;
        _apiLoading = false;
      });
      if (zones.isNotEmpty && !zones.contains(widget.value)) {
        final initial = widget.includeAll ? 'All' : zones.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChanged(initial);
        });
      }
    });
  }

  List<String> _buildItems() {
    if (widget.fromApi) {
      return widget.includeAll ? ['All', ..._apiZones] : _apiZones;
    }

    final data = widget.allData;
    if (data == null || data.isEmpty) {
      return widget.includeAll ? const ['All'] : const [];
    }

    final zones = data
        .where((a) =>
            widget.stateFilter == null ||
            widget.stateFilter == 'All' ||
            (a[widget.stateKey] ?? '').toString() == widget.stateFilter)
        .map((a) => (a[widget.zoneKey] ?? '').toString())
        .where((z) => z.isNotEmpty && z != '-')
        .toSet()
        .toList()
      ..sort();

    return widget.includeAll ? ['All', ...zones] : zones;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromApi && _apiLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    final effectiveValue = items.contains(widget.value) ? widget.value : items.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label,
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
            value: effectiveValue,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down,
                size: 20, color: Color(0xFF505050)),
            style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
            items: items
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
