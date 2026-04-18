import 'package:audit_app/constants.dart';
import '../../../controllers/usercontroller.dart';
import '../../../models/screenarguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class SideMenu extends StatefulWidget {
  final bool? enableAction;
  final Function(int)? onCallback;
  const SideMenu({super.key, this.enableAction = true, this.onCallback});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  UserController usercontroller = Get.put(UserController());

  /// Route-aware menu key resolution.
  ///
  /// Maps each route to its valid menu keys (first = default).
  /// If [selectedMenuKey] is inconsistent with the current URL,
  /// it auto-corrects to the default key for that route.
  /// This ensures the sidebar always reflects the actual page —
  /// even on direct URL entry, deep links, or back/forward navigation.
  static const _routeMenuKeys = <String, List<String>>{
    '/dashboard': ['dashboard'],
    '/published-report': ['reports-published'],
    '/summary-report': ['reports-published'],
    '/heatmap-region': ['heatmap-region'],
    '/heatmap-activity-wise': ['heatmap-allindia'],
    '/scheduledaudit': ['scheduled'],
    '/unscheduledaudit': ['unscheduled'],
    '/assignedaudit': ['assigned-audit'],
    '/all-india-state-wise-audit': ['map-allindia-state'],
    '/red-report': ['map-red-report'],
    '/user': ['settings-users'],
    '/red-report-list': ['reports-red'],
    '/nc-report-list': ['reports-ncc'],
    '/templatelist': ['settings-template'],
    '/createbrand': ['settings-brand'],
    '/createaudit': ['audit-create'],
    '/auditlist': ['audit-list'],
    '/client-audit-status': ['client-audit-status'],
  };

  String _resolveMenuKey() {
    final currentRoute = Get.currentRoute;
    final currentKey = usercontroller.selectedMenuKey;

    final validKeys = _routeMenuKeys[currentRoute];
    if (validKeys != null) {
      // Current key is valid for this route — keep it
      if (validKeys.contains(currentKey)) return currentKey;
      // Out-of-sync — fall back to the default key for this route
      usercontroller.selectedMenuKey = validKeys.first;
      return validKeys.first;
    }

    return currentKey;
  }

  @override
  Widget build(BuildContext context) {
    final menuKey = _resolveMenuKey();
    final isAuditor = usercontroller.userData.role == 'JrA';
    final isClient = usercontroller.userData.role == 'CL';

    // Dynamically determine which sections should be expanded based on selected menu key
    const auditStatusKeys = ['dashboard', 'scheduled', 'unscheduled', 'assigned-audit'];
    const heatmapActivityWiseKeys = ['heatmap-allindia', 'heatmap-region'];
    const heatmapMapWiseKeys = ['map-allindia-state', 'map-red-report'];
    const heatmapKeys = [...heatmapActivityWiseKeys, ...heatmapMapWiseKeys];
    const reportsSubKeys = ['reports-published', 'reports-red', 'reports-ncc'];
    const settingsKeys = ['settings-users', 'settings-template', 'settings-brand'];
    const auditKeys = ['audit-create', 'audit-list'];

    bool isAuditStatusExpanded = auditStatusKeys.contains(menuKey);
    bool isReportsExpanded = [...heatmapKeys, ...reportsSubKeys].contains(menuKey);
    bool isReportsActivityWiseExpanded = heatmapActivityWiseKeys.contains(menuKey);
    bool isReportsMapWiseExpanded = heatmapMapWiseKeys.contains(menuKey);
    bool isReportsSubExpanded = reportsSubKeys.contains(menuKey);
    bool isSettingsExpanded = settingsKeys.contains(menuKey);
    bool isAuditExpanded = auditKeys.contains(menuKey);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF505050),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 158,
              width: 280,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSecondary),
              child: SvgPicture.asset("assets/images/can-logo.svg", width: 160, height: 78),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (isClient)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF777777))),
                        color: menuKey == 'client-audit-status' ? Color(0xFF02B2EB) : Color(0xFF505050),
                      ),
                      child: ListTile(
                        title: Text(
                          "Audit Status",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              height: 16 / 19),
                        ),
                        onTap: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedMenuKey = 'client-audit-status';
                            Navigator.pushNamed(context, "/client-audit-status");
                          } else {
                            widget.onCallback!(0);
                          }
                        },
                      ),
                    ),
                  if (!isClient)
                  // Audit Status Section
                  ExpansionTile(
                    initiallyExpanded: isAuditStatusExpanded,
                    shape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    collapsedShape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    title: Text(
                      "Audit Status",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                          height: 16 / 19),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    backgroundColor: Color(0xFF505050),
                    collapsedBackgroundColor: Color(0xFF505050),
                    children: [
                      if (!isAuditor)
                      DrawerListTile(
                        menuKey: 'dashboard',
                        selectedMenuKey: menuKey,
                        title: "Dashboard",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedMenuKey = 'dashboard';
                            Navigator.pushNamed(context, "/dashboard");
                          } else {
                            widget.onCallback!(0);
                          }
                        },
                      ),
                      if (!isAuditor)
                      DrawerListTile(
                        menuKey: 'scheduled',
                        selectedMenuKey: menuKey,
                        title: "Scheduled",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedMenuKey = 'scheduled';
                            Navigator.pushNamed(context, "/scheduledaudit",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(1);
                          }
                        },
                      ),
                      if (!isAuditor)
                      DrawerListTile(
                        menuKey: 'unscheduled',
                        selectedMenuKey: menuKey,
                        title: "Un-scheduled",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedMenuKey = 'unscheduled';
                            Navigator.pushNamed(context, "/unscheduledaudit",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(2);
                          }
                        },
                      ),
                      // TODO: Restore role check after testing → if (usercontroller.userData.role == 'JrA')
                      if (usercontroller.userData.role == 'JrA')  
                        DrawerListTile(
                          menuKey: 'assigned-audit',
                          selectedMenuKey: menuKey,
                          title: "Assigned Audit",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedMenuKey = 'assigned-audit';
                              Navigator.pushNamed(context, "/assignedaudit",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER, mapData: {}));
                            } else {
                              widget.onCallback!(2);
                            }
                          },
                        ),
                    ],
                  ),
                if (!isAuditor)
                // Reports Section
                  ExpansionTile(
                    initiallyExpanded: isReportsExpanded,
                    shape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    collapsedShape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    title: Text(
                      "Reports",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 19 / 16),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    backgroundColor: Color(0xFF505050),
                    collapsedBackgroundColor: Color(0xFF505050),
                    children: [
                      // Heat Map - Activity Wise
                      ExpansionTile(
                        initiallyExpanded: isReportsActivityWiseExpanded,
                        title: Text(
                          "Heat Map - Activity Wise",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 19 / 14),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        backgroundColor: Color(0xFF505050),
                        collapsedBackgroundColor: Color(0xFF505050),
                        children: [
                          DrawerListTile(
                            menuKey: 'heatmap-allindia',
                            selectedMenuKey: menuKey,
                            title: "All India",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'heatmap-allindia';
                                Navigator.pushNamed(context, "/heatmap-activity-wise");
                              } else {
                                widget.onCallback!(2);
                              }
                            },
                          ),
                          DrawerListTile(
                            menuKey: 'heatmap-region',
                            selectedMenuKey: menuKey,
                            title: "Region",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'heatmap-region';
                                Navigator.pushNamed(context, "/heatmap-region");
                              } else {
                                widget.onCallback!(3);
                              }
                            },
                          ),
                        ],
                      ),
                      // Heat Map - Map-Wise
                      ExpansionTile(
                        initiallyExpanded: isReportsMapWiseExpanded,
                        title: Text(
                          "Heat Map - Map-Wise",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 19 / 14),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        backgroundColor: Color(0xFF505050),
                        collapsedBackgroundColor: Color(0xFF505050),
                        children: [
                          DrawerListTile(
                            menuKey: 'map-allindia-state',
                            selectedMenuKey: menuKey,
                            title: "All India (State wise)",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'map-allindia-state';

                                // Prepare a basic payload
                                final y = DateTime.now().year;
                                final fy = "FY$y-${(y + 1).toString().substring(2)}";
                                
                                var map = {
                                  "financial_year": fy,
                                  "userid": usercontroller.userData.userId,
                                  "role": usercontroller.userData.role,
                                  "client": usercontroller.userData.clientid,
                                  "client_id": usercontroller.selectedClientId,
                                };

                                Navigator.pop(context);

                                usercontroller.getAllIndiaStateWiseAudit(
                                    context,
                                    data: map, callback: (res) {
                                  Get.toNamed("/all-india-state-wise-audit");
                                });
                              } else {
                                widget.onCallback!(4);
                              }
                            },
                          ),
                          DrawerListTile(
                            menuKey: 'map-red-report',
                            selectedMenuKey: menuKey,
                            title: "Red Report",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'map-red-report';
                                Navigator.pop(context);
                                Get.toNamed("/red-report");
                              } else {
                                widget.onCallback!(5);
                              }
                            },
                          ),
                        ],
                      ),
                      // Report
                      ExpansionTile(
                        initiallyExpanded: isReportsSubExpanded,
                        title: Text(
                          "Report",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 19 / 14),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        backgroundColor: Color(0xFF505050),
                        collapsedBackgroundColor: Color(0xFF505050),
                        children: [
                          if (menuAccessRole
                                  .contains(usercontroller.userData.role!))
                            DrawerListTile(
                              menuKey: 'reports-published',
                              selectedMenuKey: menuKey,
                              title: "Published",
                              press: () {
                                if (widget.enableAction!) {
                                  usercontroller.selectedMenuKey = 'reports-published';
                                  Navigator.pushNamed(context, "/published-report");
                                } else {
                                  widget.onCallback!(6);
                                }
                              },
                            ),
                          DrawerListTile(
                            menuKey: 'reports-red',
                            selectedMenuKey: menuKey,
                            title: "Red",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'reports-red';
                                Navigator.pushNamed(context, "/red-report-list");
                              } else {
                                widget.onCallback!(7);
                              }
                            },
                          ),
                          DrawerListTile(
                            menuKey: 'reports-ncc',
                            selectedMenuKey: menuKey,
                            title: "NC",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedMenuKey = 'reports-ncc';
                                Navigator.pushNamed(context, "/nc-report-list");
                              } else {
                                widget.onCallback!(8);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (!isAuditor && !isClient)
                  // Settings Section
                  ExpansionTile(
                    initiallyExpanded: isSettingsExpanded,
                    shape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    collapsedShape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 19 / 16),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    backgroundColor: Color(0xFF505050),
                    collapsedBackgroundColor: Color(0xFF505050),
                    children: [
                      if (menuAccessRole
                              .contains(usercontroller.userData.role!))
                        DrawerListTile(
                          menuKey: 'settings-users',
                          selectedMenuKey: menuKey,
                          title: "Create User",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedMenuKey = 'settings-users';
                              Navigator.pushNamed(context, "/user",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(10);
                            }
                          },
                        ),
                      if (menuAccessRole
                              .contains(usercontroller.userData.role!))
                        DrawerListTile(
                          menuKey: 'settings-template',
                          selectedMenuKey: menuKey,
                          title: "Create Template",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedMenuKey = 'settings-template';
                              Navigator.pushNamed(context, "/templatelist",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(11);
                            }
                          },
                        ),
                      if (menuAccessRoleAdmin
                              .contains(usercontroller.userData.role!))
                        DrawerListTile(
                          menuKey: 'settings-brand',
                          selectedMenuKey: menuKey,
                          title: "Create Client",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedMenuKey = 'settings-brand';
                              Navigator.pushNamed(context, "/createbrand",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(12);
                            }
                          },
                        ),
                    ],
                  ),

                  if (!isAuditor && !isClient)
                  // Audit Section
                  ExpansionTile(
                    initiallyExpanded: isAuditExpanded,
                    shape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    collapsedShape: Border(bottom: BorderSide(color: Color(0xFF777777))),
                    title: Text(
                      "Audit",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 19 / 16),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    backgroundColor: Color(0xFF505050),
                    collapsedBackgroundColor: Color(0xFF505050),
                    children: [
                      if (menuAccessRole
                              .contains(usercontroller.userData.role!))
                        DrawerListTile(
                          menuKey: 'audit-create',
                          selectedMenuKey: menuKey,
                          title: "Create Audit",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedMenuKey = 'audit-create';
                              Navigator.pushNamed(context, "/createaudit",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(13);
                            }
                          },
                        ),
                      DrawerListTile(
                        menuKey: 'audit-list',
                        selectedMenuKey: menuKey,
                        title: "Audit List",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedMenuKey = 'audit-list';
                            Navigator.pushNamed(context, "/auditlist",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(14);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                "Powered by Profaids Consulting",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerListTile extends StatefulWidget {
  const DrawerListTile({
    super.key,
    required this.title,
    required this.menuKey,
    required this.selectedMenuKey,
    this.svgSrc,
    required this.press,
    this.titleStyle,
  });
  final String menuKey;
  final String selectedMenuKey;
  final String title;
  final String? svgSrc;
  final VoidCallback press;
  final TextStyle? titleStyle;

  @override
  State<DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.menuKey == widget.selectedMenuKey;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: isSelected
            ? Color(0xFF02B2EB)
            : _isHovered
                ? Color(0xFF626262)
                : Colors.transparent,
        child: ListTile(
        onTap: widget.press,
        horizontalTitleGap: 0.0,
        contentPadding:
            EdgeInsets.only(left: widget.svgSrc != null ? 16 : 32, right: 16),
        leading: widget.svgSrc != null
            ? SvgPicture.asset(
                widget.svgSrc!,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 28,
              )
            : null,
        title: Text(
          widget.title,
          style: widget.titleStyle ??
              TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                height: 16 / 14,
              ),
        ),
      ),
    ),
  );
  }
}
