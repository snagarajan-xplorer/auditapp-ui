import 'package:get/get.dart';
import '../../../controllers/usercontroller.dart';
import '../../../models/screenarguments.dart';
import './../../../responsive.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'file_info_card.dart';

class MyFiles extends StatelessWidget {
  final List<dynamic> droparr;
  final String selectedItem;
  final String valueKey;
  final String role;
  final Function(String) callback;
  const MyFiles({
    super.key, required this.droparr, required this.selectedItem, required this.valueKey, required this.callback, required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Column(
      children: [

        Responsive(
          mobile: FileInfoCardGridView(
            crossAxisCount: size.width < 650 ? 2 : 4,
            childAspectRatio: size.width < 650 && size.width > 350 ? 1.3 : 1,
          ),
          tablet: FileInfoCardGridView(),
          desktop: FileInfoCardGridView(
            childAspectRatio: size.width < 1400 ? 1.1 : 1.4,
          ),
        ),
      ],
    );
  }
}

class FileInfoCardGridView extends StatelessWidget {
   FileInfoCardGridView({
    super.key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
  });

  final int crossAxisCount;
  final double childAspectRatio;

  final UserController usercontroller = Get.put(UserController());
//Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: usercontroller.countList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => InkWell(
        onTap: (){
          Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {"path":usercontroller.countList[index].path}));
        },
        child: FileInfoCard(info: usercontroller.countList[index]),),
    );
  }
}
