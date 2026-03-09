import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.svgSrc,
    required this.amountOfFiles,
    required this.numOfFiles, this.enableChild=false, this.children, this.showPadding=true, this.color,
  });

  final String title, svgSrc, amountOfFiles;
  final int numOfFiles;
  final bool? enableChild;
  final bool? showPadding;
  final Color? color;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: defaultPadding),
      padding: showPadding! ? EdgeInsets.all(defaultPadding):EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: primaryColor.withValues(alpha: 0.15)),
        borderRadius: const BorderRadius.all(
          Radius.circular(defaultPadding),
        ),
      ),
      child: Row(
        children:enableChild! ? children!: [
          SizedBox(

            height: 20,
            width: 20,
            child: SvgPicture.asset(svgSrc,colorFilter:  ColorFilter.mode(
              color!, // Change this to any color you want
              BlendMode.srcIn, // Ensures the color applies properly
            )),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                ],
              ),
            ),
          ),
          Text(amountOfFiles)
        ],
      ),
    );
  }
}
