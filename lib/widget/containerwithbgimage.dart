import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/outlinebutton.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

class ContainerBgImage extends StatelessWidget {

  final double? height;
  final double? width;

  final String? imgPath;

  const ContainerBgImage({super.key, this.height, this.width, this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        width: width,

        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          image: DecorationImage(
              image: NetworkImage(imgPath!),
              fit: BoxFit.contain
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 3,
              blurRadius: 3,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        )

    );
  }
}
