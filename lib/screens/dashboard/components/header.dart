import 'package:flutter/cupertino.dart';

import '../../../controllers/usercontroller.dart';
import './../../../responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants.dart';

class Header extends StatefulWidget {
  final VoidCallback callback;
  final bool? showBackbutton;
  final VoidCallback? backEvent;
  final String? previousScreenName;
  const Header({
    Key? key,
    required this.callback,
    this.showBackbutton = false,
    this.previousScreenName = "",
    this.backEvent,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Menu button (mobile) and Brand Dropdown
          Expanded(
            child: Row(
              children: [
                if (!Responsive.isDesktop(context))
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      print("Click Menu");
                      widget.callback();
                    },
                  ),
                if (Responsive.isDesktop(context) && widget.showBackbutton!)
                  IconButton(
                    onPressed: () {
                      if (widget.backEvent != null) {
                        widget.backEvent!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(CupertinoIcons.back),
                  ),
                if (Responsive.isDesktop(context) && widget.showBackbutton!)
                  InkWell(
                    onTap: () {
                      if (widget.backEvent != null) {
                        widget.backEvent!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.only(top: 7),
                      child: Text(
                        widget.previousScreenName!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (!widget.showBackbutton!)
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(left: 50),
                      constraints: BoxConstraints(maxWidth: 500),
                      child: BrandDropdown(),
                    ),
                  ),
              ],
            ),
          ),
          // Right side - Profile Card
          Container(
            margin: EdgeInsets.only(right: 36),
            child: ProfileCard(),
          )
        ],
      ),
    );
  }
}

class BrandDropdown extends StatefulWidget {
  const BrandDropdown({Key? key}) : super(key: key);

  @override
  State<BrandDropdown> createState() => _BrandDropdownState();
}

class _BrandDropdownState extends State<BrandDropdown> {
  UserController usercontroller = Get.put(UserController());
  List<dynamic> clientArr = [];
  String selectedClientId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    if (menuAccessRole.indexOf(usercontroller.userData.role!) != -1) {
      usercontroller.getClientList(
        context,
        data: {
          "role": usercontroller.userData.role,
          "client_id": usercontroller.userData.clientid
        },
        callback: (res) {
          setState(() {
            clientArr = res;
            if (clientArr.isNotEmpty) {
              selectedClientId = clientArr[0]["clientid"].toString();
              usercontroller.selectedClientId = selectedClientId;
            }
            isLoading = false;
          });
        },
      );
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (menuAccessRole.indexOf(usercontroller.userData.role!) == -1) {
      return Container();
    }

    if (isLoading) {
      return Text(
        "Loading...",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Color(0xFF505050),
        ),
      );
    }

    if (clientArr.isEmpty) {
      return SizedBox();
    }

    return DropdownButtonFormField<String>(
      value: selectedClientId,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      items: clientArr.map<DropdownMenuItem<String>>((client) {
        return DropdownMenuItem<String>(
          value: client["clientid"].toString(),
          child: Text(
            client["clientname"].toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF505050),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClientId = value!;
          usercontroller.selectedClientId = value;
        });
      },
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 24),
      isExpanded: true,
      isDense: false,
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserController usercontroller = Get.put(UserController());

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding / 2,
        vertical: defaultPadding / 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Company name and role
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                usercontroller.userData.name ?? "",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 1),
              Text(
                usercontroller.userData.rolename ?? "",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                  color: Color(0xFF898989),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          // Profile image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(21.0)),
              color: Colors.red,
            ),
            child: usercontroller.userData.image == null
                ? Center(
                    child: Text(
                      usercontroller.userData.name
                          .toString()
                          .toUpperCase()
                          .substring(0, 2),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(21.0),
                    child: Image.network(
                      IMG_URL + usercontroller.userData.image!,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
