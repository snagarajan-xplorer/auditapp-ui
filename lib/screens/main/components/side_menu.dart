import 'package:audit_app/constants.dart';
import 'package:audit_app/controllers/menu_app_controller.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/services/api_service.dart';
import '../../../controllers/usercontroller.dart';
import '../../../models/screenarguments.dart';
import './../../../providers/languagemodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF505050),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSecondary),
              child: Image.asset("assets/images/logo.png"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Audit Status Section
                  ExpansionTile(
                    initiallyExpanded: true,
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
                      DrawerListTile(
                        id: 0,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "Dashboard",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 0;
                            Navigator.pushNamed(context, "/dashboard");
                          } else {
                            widget.onCallback!(0);
                          }
                        },
                      ),
                      DrawerListTile(
                        id: 1,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "Scheduled",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 1;
                            Navigator.pushNamed(context, "/scheduledaudit",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(1);
                          }
                        },
                      ),
                      DrawerListTile(
                        id: 2,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "Un Scheduled",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 2;
                            Navigator.pushNamed(context, "/auditlist",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(2);
                          }
                        },
                      ),
                    ],
                  ),

                  // Activity-Wise Section
                  ExpansionTile(
                    title: Text(
                      "Heat Map",
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
                      ExpansionTile(
                        title: Text(
                          "Activity-Wise",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB9B9B9),
                              fontWeight: FontWeight.w100,
                              height: 19 / 16),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        backgroundColor: Color(0xFF505050),
                        collapsedBackgroundColor: Color(0xFF505050),
                        children: [
                          DrawerListTile(
                            id: 3,
                            selectedIndex: usercontroller.selectedIndex,
                            title: "All India",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedIndex = 3;
                                Navigator.pushNamed(context, "/dashboard");
                              } else {
                                widget.onCallback!(3);
                              }
                            },
                          ),
                          DrawerListTile(
                            id: 4,
                            selectedIndex: usercontroller.selectedIndex,
                            title: "Region",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedIndex = 4;
                                Navigator.pushNamed(context, "/dashboard");
                              } else {
                                widget.onCallback!(4);
                              }
                            },
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text(
                          "Map-Wise",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB9B9B9),
                              fontWeight: FontWeight.w100,
                              height: 19 / 16),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        backgroundColor: Color(0xFF505050),
                        collapsedBackgroundColor: Color(0xFF505050),
                        children: [
                          DrawerListTile(
                            id: 5,
                            selectedIndex: usercontroller.selectedIndex,
                            title: "All India (State wise)",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedIndex = 5;
                                Navigator.pushNamed(context, "/all-india-state-activity");
                              } else {
                                widget.onCallback!(5);
                              }
                            },
                          ),
                          DrawerListTile(
                            id: 6,
                            selectedIndex: usercontroller.selectedIndex,
                            title: "Red Report (NC)",
                            press: () {
                              if (widget.enableAction!) {
                                usercontroller.selectedIndex = 6;
                                Navigator.pushNamed(context, "/dashboard");
                              } else {
                                widget.onCallback!(6);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Reports Section
                  ExpansionTile(
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
                      if (menuAccessRole
                              .indexOf(usercontroller.userData.role!) !=
                          -1)
                        DrawerListTile(
                          id: 7,
                          selectedIndex: usercontroller.selectedIndex,
                          title: "Published Report",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedIndex = 7;
                              Navigator.pushNamed(context, "/user",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(7);
                            }
                          },
                        ),
                      DrawerListTile(
                        id: 8,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "Red Report",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 8;
                            Navigator.pushNamed(context, "/user",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(8);
                          }
                        },
                      ),
                      DrawerListTile(
                        id: 9,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "NCC Report",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 9;
                            Navigator.pushNamed(context, "/user",
                                arguments: ScreenArgument(
                                    argument: ArgumentData.USER, mapData: {}));
                          } else {
                            widget.onCallback!(9);
                          }
                        },
                      ),
                    ],
                  ),

                  // Settings Section
                  ExpansionTile(
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
                              .indexOf(usercontroller.userData.role!) !=
                          -1)
                        DrawerListTile(
                          id: 10,
                          selectedIndex: usercontroller.selectedIndex,
                          title: "Create Profaids Users",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedIndex = 10;
                              Navigator.pushNamed(context, "/client",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.CLIENT,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(10);
                            }
                          },
                        ),
                      if (menuAccessRole
                              .indexOf(usercontroller.userData.role!) !=
                          -1)
                        DrawerListTile(
                          id: 11,
                          selectedIndex: usercontroller.selectedIndex,
                          title: "Create Template",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedIndex = 11;
                              Navigator.pushNamed(context, "/user",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(11);
                            }
                          },
                        ),
                      if (menuAccessRole
                              .indexOf(usercontroller.userData.role!) !=
                          -1)
                        DrawerListTile(
                          id: 12,
                          selectedIndex: usercontroller.selectedIndex,
                          title: "Create Brand",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedIndex = 12;
                              Navigator.pushNamed(context, "/user",
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

                  // Audit Section
                  ExpansionTile(
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
                              .indexOf(usercontroller.userData.role!) !=
                          -1)
                        DrawerListTile(
                          id: 13,
                          selectedIndex: usercontroller.selectedIndex,
                          title: "Create Audit",
                          press: () {
                            if (widget.enableAction!) {
                              usercontroller.selectedIndex = 13;
                              Navigator.pushNamed(context, "/templatelist",
                                  arguments: ScreenArgument(
                                      argument: ArgumentData.USER,
                                      mapData: {}));
                            } else {
                              widget.onCallback!(13);
                            }
                          },
                        ),
                      DrawerListTile(
                        id: 14,
                        selectedIndex: usercontroller.selectedIndex,
                        title: "Audit List",
                        press: () {
                          if (widget.enableAction!) {
                            usercontroller.selectedIndex = 14;
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
          ],
        ),
      ),
    );
  }
}

class DrawerListTile extends StatefulWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.id,
    this.svgSrc,
    required this.press,
    required this.selectedIndex,
    this.titleStyle,
  }) : super(key: key);
  final int id, selectedIndex;
  final String title;
  final String? svgSrc;
  final VoidCallback press;
  final TextStyle? titleStyle;

  @override
  State<DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: widget.id == widget.selectedIndex ? true : false,
      selectedColor: Color(0xFF505050),
      selectedTileColor: Colors.blue.withOpacity(0.3),
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
    );
  }
}
