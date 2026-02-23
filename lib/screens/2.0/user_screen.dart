import 'package:audit_app/controllers/usercontroller.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/LocalStorage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';

class UserScreenV2 extends StatefulWidget {
  const UserScreenV2({super.key});

  @override
  State<UserScreenV2> createState() => _UserScreenV2State();
}

class _UserScreenV2State extends State<UserScreenV2> {
  UserController usercontroller = Get.put(UserController());

  // Data state
  bool isLoading = false;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  int currentPage = 1;
  final int pageSize = 10;

  // Client ID → Name lookup
  Map<String, String> clientNameMap = {};

  // Page argument
  ScreenArgument? pageArgument;
  String pageTitle = "Profaids Users";
  String pageSubtitle = "Profaids Account Controller";
  bool isUserMode = true; // true = User, false = Client

  @override
  void initState() {
    super.initState();
    if (usercontroller.userData.role == null) {
      usercontroller.loadInitData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Resolve page argument
    pageArgument = ModalRoute.of(context)?.settings.arguments as ScreenArgument? ??
        ScreenArgument();

    if (pageArgument?.argument != null) {
      await LocalStorage.setStringData(
          "arguments",
          pageArgument?.argument == ArgumentData.USER ? "User" : "Client");
    } else {
      String? str = await LocalStorage.getStringData("arguments");
      pageArgument = ScreenArgument(
          argument: str == "User" ? ArgumentData.USER : ArgumentData.CLIENT,
          mapData: {});
    }

    isUserMode = pageArgument?.argument != ArgumentData.CLIENT;

    if (isUserMode) {
      pageTitle = "Profaids Users";
      pageSubtitle = "Profaids Account Controller";
    } else {
      pageTitle = "Profaids Clients";
      pageSubtitle = "Client Account Controller";
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // First fetch client list to build ID → Name map
    await usercontroller.getClientList(context,
        data: {
          "role": usercontroller.userData.role,
          "client_id": usercontroller.userData.clientid,
        },
        loader: false,
        callback: (clientList) {
      clientNameMap = {};
      for (var c in clientList) {
        final id = c["clientid"]?.toString() ?? "";
        final name = c["clientname"]?.toString() ?? "";
        if (id.isNotEmpty) {
          clientNameMap[id] = name;
        }
      }
    });

    String role = isUserMode ? "ALL" : "CL";

    usercontroller.getUserList(context, data: {
      "role": role,
      "status": "ALL",
      "client": usercontroller.userData.clientid,
      "userRole": usercontroller.userData.role,
    }, callback: (res) {
      allUsers = [];
      for (var element in res) {
        final userMap = Map<String, dynamic>.from(element);
        userMap["statusLabel"] = userMap["status"] == "A" ? "Active" : "In Active";
        userMap["statusColor"] = userMap["status"] == "A" ? "green" : "red";

        // Resolve client IDs to brand names
        if (userMap["client"] != null) {
          List<String> ids = [];
          if (userMap["client"] is List) {
            ids = (userMap["client"] as List).map((e) => e.toString()).toList();
          } else if (userMap["client"] is String) {
            final str = userMap["client"].toString().trim();
            if (str.isNotEmpty) {
              ids = str.split(",").map((e) => e.trim()).toList();
            }
          }

          if (ids.isEmpty) {
            userMap["brandDisplay"] = "-";
          } else {
            // Check if all IDs map to all clients → show "All"
            final names = ids
                .map((id) => clientNameMap[id] ?? id)
                .toList();
            if (clientNameMap.isNotEmpty && names.length == clientNameMap.length) {
              userMap["brandDisplay"] = "All";
            } else {
              userMap["brandDisplay"] = names.join(", ");
            }
          }
        } else {
          userMap["brandDisplay"] = "-";
        }

        if (isUserMode) {
          // Exclude CL and SA roles for user list
          if (["CL", "SA"].indexOf(userMap["role"].toString()) == -1) {
            allUsers.add(userMap);
          }
        } else {
          if (userMap["role"] == "CL") {
            allUsers.add(userMap);
          }
        }
      }

      filteredUsers = List.from(allUsers);
      if (mounted) setState(() => isLoading = false);
    });
  }

  void _onCreateNewUser() {
    Navigator.pushNamed(context, "/createuser", arguments: pageArgument);
  }

  void _onEditUser(Map<String, dynamic> data) {
    Map<String, dynamic> editData = Map<String, dynamic>.from(data);

    if (isUserMode) {
      if (editData["joiningdate"] != null &&
          editData["joiningdate"].toString().isNotEmpty) {
        try {
          editData["joiningdate"] =
              Jiffy.parse(editData["joiningdate"].toString()).dateTime;
        } catch (_) {}
      }
    } else {
      if (editData["client"] != null) {
        editData["client"] = editData["client"].toString();
      }
    }

    ScreenArgument editArg = ScreenArgument(
        argument: pageArgument?.argument,
        mapData: pageArgument?.mapData,
        mode: "Edit",
        editData: editData);

    Navigator.pushNamed(context, "/createuser", arguments: editArg);
  }

  List<TableColumnDef> get _columns {
    if (isUserMode) {
      return [
        TableColumnDef(label: "Name", flex: 2, key: "name"),
        TableColumnDef(label: "Email", flex: 3, key: "email"),
        TableColumnDef(label: "Mobile", flex: 2, key: "mobile"),
        TableColumnDef(label: "State", flex: 2, key: "state"),
        TableColumnDef(label: "City", flex: 2, key: "city"),
        TableColumnDef(label: "Role", flex: 2, key: "rolename"),
        TableColumnDef(label: "Brand", flex: 2, key: "brandDisplay"),
        TableColumnDef(
          label: "Status",
          flex: 2,
          cellBuilder: (row, _) {
            return statusBadgeCell(
              label: row["statusLabel"] ?? "-",
              color: row["statusColor"] ?? "grey",
            );
          },
        ),
        TableColumnDef(
          label: "Action",
          flex: 2,
          isLast: true,
          cellBuilder: (row, _) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: () => _onEditUser(Map<String, dynamic>.from(row)),
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  label: const Text("Edit",
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E77D0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    elevation: 0,
                  ),
                ),
              ),
            );
          },
        ),
      ];
    } else {
      // Client mode
      return [
        TableColumnDef(label: "Company Name", flex: 3, key: "companyname"),
        TableColumnDef(label: "Name", flex: 2, key: "name"),
        TableColumnDef(label: "Email", flex: 3, key: "email"),
        TableColumnDef(label: "Mobile", flex: 2, key: "mobile"),
        TableColumnDef(
          label: "Status",
          flex: 2,
          cellBuilder: (row, _) {
            return statusBadgeCell(
              label: row["statusLabel"] ?? "-",
              color: row["statusColor"] ?? "grey",
            );
          },
        ),
        TableColumnDef(
          label: "Action",
          flex: 2,
          isLast: true,
          cellBuilder: (row, _) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: () => _onEditUser(Map<String, dynamic>.from(row)),
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  label: const Text("Edit",
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E77D0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    elevation: 0,
                  ),
                ),
              ),
            );
          },
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Create New User button
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title area
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pageTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF505050))),
                      const SizedBox(height: 4),
                      Text(pageSubtitle,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF898989))),
                    ],
                  ),
                  // Create New User button
                  if (menuAccessRole
                          .indexOf(usercontroller.userData.role ?? '') !=
                      -1)
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _onCreateNewUser,
                        icon: const Icon(Icons.add_box_outlined,
                            size: 18, color: Colors.white),
                        label: Text(
                            isUserMode
                                ? "Create New User"
                                : "Create New Client",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white,fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF67AC5B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 0),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Table + Pagination
            ReusableTable(
              columns: _columns,
              rows: filteredUsers,
              isLoading: isLoading,
              currentPage: currentPage,
              pageSize: pageSize,
              maxVisiblePages: 8,
              cellVerticalPadding: 18,
              cellHorizontalPadding: 10,
              headerFontWeight: FontWeight.w500,
              onPageChanged: (page) => setState(() => currentPage = page),
            ),

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
