import 'package:flutter/material.dart';
import 'main/layoutscreen.dart';
import '../constants.dart';

class ScheduledAuditScreen extends StatefulWidget {
  const ScheduledAuditScreen({super.key});

  @override
  State<ScheduledAuditScreen> createState() => _ScheduledAuditScreenState();
}

class _ScheduledAuditScreenState extends State<ScheduledAuditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedState = "All";
  String selectedZone = "South";
  String selectedYear = "FY2024-25";

  final List<String> states = ["All", "Karnataka", "Tamilnadu", "Gujarat", "Andhra Pradesh", "Telangana", "Delhi"];
  final List<String> zones = ["All", "North", "South", "East", "West"];
  final List<String> years = ["FY2024-25", "FY2023-24", "FY2022-23", "FY2021-22", "FY2020-21"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Container(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scheduled Audit Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF505050),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Detailed overview of all audits",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF898989),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs and Filters Row
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              child: Row(
                children: [
                  // Tabs
                  Expanded(
                    flex: 3,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Color(0xFF01ADEF),
                      unselectedLabelColor: Color(0xFF505050),
                      indicatorColor: Color(0xFF01ADEF),
                      indicatorWeight: 3,
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: [
                        Tab(text: "All"),
                        Tab(text: "Published"),
                        Tab(text: "In Progress"),
                        Tab(text: "Upcoming"),
                        Tab(text: "Cancelled"),
                      ],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Filters
                  Row(
                    children: [
                      _buildFilterDropdown("State:", states, selectedState, (value) {
                        setState(() => selectedState = value!);
                      }),
                      SizedBox(width: 12),
                      _buildFilterDropdown("Zone:", zones, selectedZone, (value) {
                        setState(() => selectedZone = value!);
                      }),
                      SizedBox(width: 12),
                      _buildFilterDropdown("", years, selectedYear, (value) {
                        setState(() => selectedYear = value!);
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Content Area (TabBarView)
            Container(
              height: MediaQuery.of(context).size.height - 300,
              color: Color(0xFFF5F5F5),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent("All Audits"),
                  _buildTabContent("Published Audits"),
                  _buildTabContent("In Progress Audits"),
                  _buildTabContent("Upcoming Audits"),
                  _buildTabContent("Cancelled Audits"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value, void Function(String?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF505050),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 8),
        ],
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFC9C9C9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF505050)),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF505050),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 16, color: Color(0xFF898989)),
      ),
    );
  }
}

