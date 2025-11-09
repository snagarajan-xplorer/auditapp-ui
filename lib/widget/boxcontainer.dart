import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/outlinebutton.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
class BoxContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final double? padding;
  final String? title;
  final bool? showTitle;
  final bool? showImage;
  final bool? isBGTransparent;
  final String? imgPath;
  final bool? showButton;
  final String? buttonName;
  final VoidCallback? callback;
  const BoxContainer({super.key, required this.child, this.height=300, this.width=300, this.title="", this.showTitle=false, this.showImage = false, this.imgPath, this.showButton = false, this.buttonName = "", this.callback,  this.isBGTransparent=false, this.padding=defaultPadding});

  @override
  Widget build(BuildContext context) {
    return showImage! ? withImage(context) : withoutImage(context);
  }
  Widget withImage(context){
    return Container(
        height: height,
        width: width,
        child: Center(
          child: Stack(
            children: [

              Positioned(
                top: 50,
                  child: withoutImage(context)
              ),
              Positioned(
                top: 0,
                  child: Visibility(
                    visible: showImage! ? true : false,
                      child: SizedBox(
                        width: width,
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(width: 2,color: bgColor),
                              borderRadius: BorderRadius.all(Radius.circular(50)),
                              image: DecorationImage(image: imgPath!.isEmpty ? AssetImage("assets/images/person.jpeg") : NetworkImage(imgPath!)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 7,
                                  offset: Offset(0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                  )
              ),

            ],
          ),
        ),
    );
  }
  Widget withoutImage(context){
    return Container(
        height: height,
        width: width,
        padding: EdgeInsets.all(padding! ),
        decoration: isBGTransparent == false ?BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 3,
              blurRadius: 3,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ):null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                    visible: showTitle!,
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                ),
                Visibility(
                    visible: showButton!,
                    child: ButtonComp(label: buttonName!,width: 120,height: buttonHeight, onPressed: (){})
                ),
              ],
            ),
            Visibility(
                visible: showTitle!,
                child: SizedBox(height: defaultPadding)
            ),
            Flexible(
              flex: 5,
                child: SizedBox(
                  height: double.infinity,
                  child: child,
                )
            )
          ],
        )
    );
  }
}
