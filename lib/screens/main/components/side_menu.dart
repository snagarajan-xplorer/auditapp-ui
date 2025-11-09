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
  const SideMenu({super.key, this.enableAction=true, this.onCallback});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  UserController usercontroller = Get.put(UserController());


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSecondary
            ),

            child: Image.asset("assets/images/logo.png"),
          ),
          DrawerListTile(
            id: 0,
            selectedIndex:usercontroller.selectedIndex,
            title: "Dashboard",
            svgSrc: "assets/icons/dashboard_icon.svg",
            press: () {
              if(widget.enableAction!){
                usercontroller.selectedIndex = 0;
                Navigator.pushNamed(context, "/dashboard");
              }else{
                widget.onCallback!(0);
                //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
              }

              //Get.toNamed("/dashboard",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
            },
          ),
          DrawerListTile(
            id: 1,
            selectedIndex:usercontroller.selectedIndex,
            title: "All Audit",
            svgSrc: "assets/icons/audit_icon.svg",
            press: () {

              if(widget.enableAction!){
                usercontroller.selectedIndex = 1;
                Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
              }else{
                widget.onCallback!(1);
                //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
              }
              //Get.toNamed("/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
            },
          ),

          if(menuAccessRole.indexOf(usercontroller.userData.role!) != -1)
            DrawerListTile(
              id: 2,
              selectedIndex:usercontroller.selectedIndex,
              title: "Client Info",
              svgSrc: "assets/icons/client_icon.svg",
              press: () {

                if(widget.enableAction!){
                  usercontroller.selectedIndex = 2;
                  Navigator.pushNamed(context, "/client",arguments: ScreenArgument(argument: ArgumentData.CLIENT,mapData: {}));
                }else{
                  widget.onCallback!(2);
                  //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
                }
                //Get.toNamed("/client",arguments: ScreenArgument(argument: ArgumentData.CLIENT,mapData: {}));
              },
            ),

          if(menuAccessRole.indexOf(usercontroller.userData.role!) != -1)
            DrawerListTile(
              id: 3,
              selectedIndex:usercontroller.selectedIndex,
              title: "Profaids Users",
              svgSrc: "assets/icons/profaidsuser_icon.svg",
              press: () {

                if(widget.enableAction!){
                  usercontroller.selectedIndex = 3;
                  //Get.toNamed("/user",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
                  Navigator.pushNamed(context, "/user",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
                }else{
                  widget.onCallback!(3);
                  //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
                }
              },
            ),

          // DrawerListTile(
          //   title: "Question",
          //   svgSrc: "assets/icons/menu_store.svg",
          //   press: () {
          //     Navigator.pushNamed(context, "/addquestion",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
          //   },
          // ),
          if(menuAccessRole.indexOf(usercontroller.userData.role!) != -1)
            DrawerListTile(
              id: 4,
              selectedIndex:usercontroller.selectedIndex,
              title: "Create Template",
              svgSrc: "assets/icons/createtemplate_icon.svg",
              press: () {

                if(widget.enableAction!){
                  usercontroller.selectedIndex = 4;
                  Navigator.pushNamed(context, "/templatelist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
                }else{
                  widget.onCallback!(4);
                  //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
                }
              },
            ),

          DrawerListTile(
            id: 5,
            selectedIndex:usercontroller.selectedIndex,
            title: "Logout",
            svgSrc: "assets/icons/logout_icon.svg",
            press: () {
              if(widget.enableAction!){
                APIService(context).showWindowAlert(title:"",desc: AppTranslations.of(context)!.text("key_message_09"),showCancelBtn: true,callback: (){
                  usercontroller.logout(context, data: {}, callback: (){
                    Navigator.pushNamed(context, "/login");
                    //Get.offNamed("/login");
                  });
                });
              }else{
                widget.onCallback!(5);
                //APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){});
              }
            },
          ),
          // DrawerListTile(
          //   title: "Theme",
          //   svgSrc: "assets/icons/menu_setting.svg",
          //   press: () {
          //     final provider = context.read<LanguageModel>();
          //     final currenttheme = provider.themeMode;
          //     print(currenttheme);
          //     final theme = currenttheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
          //     Provider.of<LanguageModel>(context, listen: false).setThemeModeAsync(themeMode: theme);
          //   },
          // ),
        ],
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
    required this.svgSrc,
    required this.press, required this.selectedIndex,
  }) : super(key: key);
  final int id,selectedIndex;
  final String title, svgSrc;
  final VoidCallback press;


  @override
  State<DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: widget.id == widget.selectedIndex?true:false,
      selectedColor: Color(0x0000346e),
      selectedTileColor:Colors.blue.withOpacity(0.3),
      onTap:widget.press,
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        widget.svgSrc,
        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
        height: 28,
      ),
      title: Text(
        widget.title,
        style: TextStyle(color: Colors.white),
      ),
    );;
  }
}


