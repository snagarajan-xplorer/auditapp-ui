import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../responsive.dart';

class PageContainerComp extends StatelessWidget {
  final Widget child;
  final String title;
  final String? buttonName;
  final bool? showTitle;
  final bool? isBGTransparent;
  final bool? showButton;
  final bool? enableScroll;
  final double? padding;
  final VoidCallback? callback;
  final Widget? header;
  const PageContainerComp({super.key, required this.child, required this.title, this.showTitle = false, this.showButton = false, this.callback, this.isBGTransparent=false, this.padding=defaultPadding, this.enableScroll=true, this.header, this.buttonName="Add New"});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(

          // padding: const EdgeInsets.only(left: defaultPadding,right: defaultPadding,top: defaultPadding),
          // child: Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Visibility(
          //       visible: showTitle!,
          //       child: Text(
          //         title,
          //         style: Theme.of(context).textTheme.titleLarge,
          //       ),
          //     ),
          //     Container(
          //       height: buttonHeight,
          //       child: Row(
          //         children: [
          //           header ?? Container(),
          //           Visibility(
          //             visible: showButton!,
          //             child:  ButtonComp(label: buttonName!,width:200,height: buttonHeight, onPressed:(){
          //               callback!();
          //             }),
          //           )
          //         ],
          //       ),
          //     ),
          //
          //   ],
          // ),
        ),
        Flexible(
          flex: 12,
            child: Container(
              margin: EdgeInsets.only(left: 46, right: 36),
              child: Padding(
                padding: EdgeInsets.all(padding!),
                child: BoxContainer(
                  width:double.infinity,
                  height: double.infinity,
                  isBGTransparent: isBGTransparent,
                  child: enableScroll!?SingleChildScrollView(
                    primary: false,

                    child: child,
                  ):child
                ),
              ),
            )
        )
      ],
    );
  }
}
