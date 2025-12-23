import '../../constants.dart';
import '../dashboard/components/header.dart';
import './../../controllers/menu_app_controller.dart';
import './../../responsive.dart';
import './../../screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class LayoutScreen extends StatefulWidget {
  final Widget child;
  final bool? showBackbutton;
  final bool? enableAction;
  final VoidCallback? backEvent;
  final Function(int)? onCallback;
  final String? previousScreenName;
  LayoutScreen({super.key, required this.child, this.showBackbutton = false,  this.previousScreenName="", this.backEvent, this.enableAction=true, this.onCallback});

  @override
  State<LayoutScreen> createState() => _LayoutscreenState();
}

class _LayoutscreenState extends State<LayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SideMenu(enableAction: widget.enableAction,onCallback: (id){widget.onCallback!(id);}),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // We want this side menu only for large screen
            if (Responsive.isDesktop(context))
              Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.5),
                  child: SideMenu(enableAction: widget.enableAction,onCallback: (id){widget.onCallback!(id);},),
                ),
              ),
            Flexible(
              // It takes 5/6 part of the screen
              flex: 5,
              fit: FlexFit.loose,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Header(
                  showBackbutton:widget.showBackbutton,
                    backEvent: widget.backEvent,
                    previousScreenName: widget.previousScreenName,
                    callback: (){
                    print("yes callback");

                    _scaffoldKey.currentState?.openDrawer();
                  },),
                  Expanded(child: widget.child)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

