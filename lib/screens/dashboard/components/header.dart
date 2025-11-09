import 'package:flutter/cupertino.dart';

import '../../../controllers/usercontroller.dart';
import '../../../theme/themes.dart';
import './../../../controllers/menu_app_controller.dart';
import './../../../responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../../constants.dart';

class Header extends StatelessWidget {
  final VoidCallback callback;
  final bool? showBackbutton;
  final VoidCallback? backEvent;
  final String? previousScreenName;
  const Header({
    Key? key, required this.callback, this.showBackbutton=false, this.previousScreenName="", this.backEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!Responsive.isDesktop(context))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: (){
                  print("Click Menu");
                  callback();},
              ),
              Visibility(
                  visible: showBackbutton!,
                  child: IconButton(onPressed: (){
                    if(backEvent != null){
                      backEvent!();
                    }else{
                      Navigator.of(context).pop();
                    }

                  }, icon: Icon(CupertinoIcons.back))
              ),
            ],
          ),
        if (Responsive.isDesktop(context))
            Visibility(
              visible: showBackbutton!,
                child: IconButton(onPressed: (){
                  if(backEvent != null){
                    backEvent!();
                  }else{
                    Navigator.of(context).pop();
                  }
                }, icon: Icon(CupertinoIcons.back))
            ),
        if (Responsive.isDesktop(context) && showBackbutton!)
          InkWell(
            onTap: (){
              if(backEvent != null){
                backEvent!();
              }else{
                Navigator.of(context).pop();
              }
            },
            child: Container(
                padding: EdgeInsets.only(top: 7),
                child: Text(previousScreenName!,style: Theme.of(context).textTheme.titleMedium,)),
          ),

        Flexible(
          flex: 1,
            child: Container()
        ),
        ProfileCard()
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
   ProfileCard({
    Key? key,
  }) : super(key: key);
  UserController usercontroller = Get.put(UserController());
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: defaultPadding),
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(usercontroller.userData.name! ?? ""),
                Text(usercontroller.userData.rolename! ?? "",style: TextStyle(fontSize: smallFontSize),)
              ],
            ),
          ),
          usercontroller.userData.image == null ? Container(
            width: 30,
            height: 30,
            child: Center(
              child: Text(usercontroller.userData.name.toString().toUpperCase().substring(0,2),style: TextStyle(
                color: Colors.white,
                fontSize: paragraphFontSize
              ),),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              color: kPrimaryColor,

            ),
          ):Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              border: Border.all(color: Colors.grey,width: 1),
              image: DecorationImage(
                  image: NetworkImage(IMG_URL+usercontroller.userData.image!),
                fit: BoxFit.fill
              )

            ),
          ),
          //if (!Responsive.isMobile(context))

        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search",
        fillColor: Theme.of(context).canvasColor,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        suffixIcon: InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.all(defaultPadding * 0.75),
            margin: EdgeInsets.symmetric(horizontal: defaultPadding / 2),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: SvgPicture.asset("assets/icons/Search.svg"),
          ),
        ),
      ),
    );
  }
}
