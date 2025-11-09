import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../widget/outlinebutton.dart';
import 'main/layoutscreen.dart';
import 'dart:js' as js;

class TemplateEditScreen extends StatefulWidget {
  const TemplateEditScreen({super.key});

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {

  ScreenArgument? pageargument;
  bool showAudit = false;
  dynamic auditObj = {};
  UserController usercontroller = Get.put(UserController());
  String totalMark = "";
  String answerMark = "";
  String totalPer = "0";

  Future<void> processAuditCategories() async {
    num ans = 0;
    num totalans = 0;
    await Future.forEach(auditObj["categorys"], (ele) async {
      dynamic element = ele;

      if (element["answer"] != null) {
        String ansStr = element["answer"].toString();
        ans += (num.tryParse(ansStr) ?? 0);
        String totalStr = element["total"].toString();
        totalans += (num.tryParse(totalStr) ?? 0);
        totalMark = totalans.toString();
        answerMark = ans.toString();
        int? v1 = int.tryParse(answerMark);
        int? v2 = int.tryParse(totalMark);
        int? v3 = int.tryParse(element["answer"].toString());
        int? v4 = int.tryParse(element["total"].toString());
        if (v1 != null && v2 != null && v2 != 0) {
          int percentage = ((v1 / v2) * 100).round();
          totalPer = percentage.toString();
        } else {
          totalPer = "0";
        }
        if (v3 != null && v4 != null && v4 != 0) {
          int percentage = ((v3 / v4) * 100).round();
          element["percentage"] = percentage.toString();
        } else {
          element["percentage"] = "0";
        }
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 200))
        .then((onValue){
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      Map<String,dynamic> data = {
        "id":pageargument?.mapData["id"]
      };
      usercontroller.getAuditQuestion(context, data: data, callback: (res) async {
        auditObj = res;
        await processAuditCategories();
        showAudit = true;
        setState(() {});
      });
    });
  }
  Widget questionComp(cate){
    int id = 1;
    return Column(
      children: cate.map<Widget>((item){
        return questionChild((id++),item,cate.length);
      }).toList(),
    );
  }
  Widget questionChild(id,quest,len){
    Color selectedColor = usercontroller.scoreArr[0]["color"];
    List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == quest["answer"].toString()).toList();
    if(arr.length != 0){
      selectedColor = arr[0]["color"];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(id.toString()+"."+quest["question"],style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),textAlign: TextAlign.left,),
        ),
        SizedBox(height: 20,),
        Center(child: Text("Your Score")),
        SizedBox(height: 10,),
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: quest["answer"].toString().trim().isEmpty?Colors.white:selectedColor,
                borderRadius: BorderRadius.all(Radius.circular(25)),
                border: Border.all(color: Colors.grey.shade400,width: 1.0)
            ),
            child: Center(
              child: Text(quest["answer"],style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800
              )),
            ),
          ),
        ),
        SizedBox(height: 10,),
        Text(quest["reviews"] ?? "",maxLines: 5,),
        SizedBox(height: 20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                flex: 2,
                child: Visibility(
                    visible: quest["proofdocuments"].length == 0 ? false : true,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      runAlignment: WrapAlignment.start,
                      children: quest["proofdocuments"].map<Widget>((imgelement)=>Container(
                        width: 90,
                        height: 90,
                        margin: EdgeInsets.only(left: 5,right: 5),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(IMG_URL+imgelement["image"],


                                  )),
                              borderRadius: BorderRadius.circular(8)
                          ),
                        ),
                      )).toList(),
                    )
                )
            ),
            SizedBox(width: 15,),
            Flexible(
                flex: 1,
                child: Visibility(
                    visible: quest["selecteddropdown"].length == 0 ? false : true,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      runAlignment: WrapAlignment.start,
                      children: quest["selecteddropdown"].map<Widget>((element)=>Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(element["dropdownname"]),
                            SizedBox(width: 7,),
                            Text(element["selectedoption"],style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold
                            ),),
                          ],
                        ),
                      )).toList(),
                    )
                )
            )
          ],
        ),
        Visibility(
            visible: id == len ? false:true,
            child: Divider(height: 20,thickness: 1,color: Colors.grey.shade500,)
        )
      ],
    );
  }
  Widget getBranchDetails(){
    return BoxContainer(
        showTitle: true,
        title: AppTranslations.of(context)!.text("key_details"),
        width: double.infinity,
        height: double.infinity,
        child: showAudit == true ? SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTranslations.of(context)!.text("key_auditno"),style: headingTextStyle,),
              Text(auditObj["audit_no"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text(AppTranslations.of(context)!.text("key_auditname"),style: headingTextStyle,),
              Text(auditObj["auditname"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text(AppTranslations.of(context)!.text("key_city"),style: headingTextStyle,),
              Text(auditObj["city"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text(AppTranslations.of(context)!.text("key_state"),style: headingTextStyle,),
              Text(auditObj["state"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text(AppTranslations.of(context)!.text("key_zone"),style: headingTextStyle,),
              Text(auditObj["zone"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("Branch Details - ",style: headTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("Manager Name",style: headingTextStyle,),
              Text(auditObj["branch"][0]["managername"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("ID Number",style: headingTextStyle,),
              Text(auditObj["branch"][0]["idcardno"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("Mobile Number",style: headingTextStyle,),
              Text(auditObj["branch"][0]["phoneno"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("Email ID",style: headingTextStyle,),
              Text(auditObj["branch"][0]["emailid"],style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
              Text("Joining Date",style: headingTextStyle,),
              Text(Jiffy.parse(auditObj["branch"][0]["joining_date"]).format(pattern: "dd/MM/yyyy"),style: labelTextStyle,),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ):Container()
    );
  }
  launchURLPage() async {
    // final Uri url = Uri.parse(API_URL+"export?id="+auditObj["id"].toString());
    // await launchUrl(
    //   url,
    //   webOnlyWindowName: '_blank',
    // );
    js.context.callMethod('open', [API_URL+"export?type=2&id="+auditObj["reporturl"].toString(),"_blank"]);
  }

  @override
  Widget build(BuildContext context) {
    int id = 1;
    return LayoutScreen(
      child: Padding(
        padding: const EdgeInsets.only(left: defaultPadding,right: defaultPadding,top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
                flex: 7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Responsive.isDesktop(context) ?
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BoxContainer(
                          width: 650,
                          height: 100,
                          child: DataTableTheme(
                              data:  DataTableThemeData(
                                  dataRowHeight: 30.0,
                                  horizontalMargin: 8,
                                  headingRowAlignment:MainAxisAlignment.spaceBetween,
                                  headingRowHeight: 30// Adjust row height
                              ),
                              child: DataTable2(
                                  headingRowHeight: 35,
                                  columnSpacing: 12,
                                  horizontalMargin: 12,
                                  minWidth: 600,

                                  columns: [
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_15"),style: headingTextStyle,)),),
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_14"),style: headingTextStyle,)),),
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_16"),style: headingTextStyle,)),)
                                  ]
                                  , rows: [
                                DataRow(cells: [
                                  DataCell(Container(child: Center(child: Text(answerMark,style: paragTextStyle,)))),
                                  DataCell(Container(child: Center(child: Text(totalMark,style: paragTextStyle,)))),
                                  DataCell(Container(child: Center(child: SizedBox(width:50,child: StatusComp(status: "",statusvalue: totalPer.toString()+"%",percentage: int.tryParse(totalPer.toString()),))
                                  )))
                                ])
                              ]
                              )
                          ),
                        ),
                        ButtonComp(height:buttonHeight,icon:Icon(Icons.download),label: AppTranslations.of(context)!.text("key_btn_export"), onPressed: ()=>launchURLPage())
                      ],
                    ) : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ButtonComp(height:buttonHeight,icon:Icon(Icons.download),label: AppTranslations.of(context)!.text("key_btn_export"), onPressed: ()=>launchURLPage()),
                        SizedBox(height: 15,),
                        BoxContainer(
                          width: 650,
                          height: 100,
                          child: DataTableTheme(
                              data:  DataTableThemeData(
                                  dataRowHeight: 30.0,
                                  horizontalMargin: 8,
                                  headingRowAlignment:MainAxisAlignment.spaceBetween,
                                  headingRowHeight: 30// Adjust row height
                              ),
                              child: DataTable2(
                                  headingRowHeight: 35,
                                  columnSpacing: 12,
                                  horizontalMargin: 12,
                                  minWidth: 600,

                                  columns: [
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_15"),style: headingTextStyle,)),),
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_14"),style: headingTextStyle,)),),
                                    DataColumn(label: Center(child: Text(AppTranslations.of(context)!.text("key_message_16"),style: headingTextStyle,)),)
                                  ]
                                  , rows: [
                                DataRow(cells: [
                                  DataCell(Container(child: Center(child: Text(answerMark,style: paragTextStyle,)))),
                                  DataCell(Container(child: Center(child: Text(totalMark,style: paragTextStyle,)))),
                                  DataCell(Container(child: Center(child: SizedBox(width:50,child: StatusComp(status: "",statusvalue: totalPer.toString()+"%",percentage: int.tryParse(totalPer.toString()),))
                                  )))
                                ])
                              ]
                              )
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: defaultPadding,),
                    BoxContainer(
                        height: MediaQuery.of(context).size.height-250,
                        width: double.infinity,
                        child: showAudit == false ? Container() : Accordion(
                          headerBorderColor: Colors.blueGrey,

                          headerBorderColorOpened: Colors.black54,
                          headerBorderWidth: 1,
                          headerBackgroundColorOpened: Colors.white12,
                          contentBackgroundColor: Colors.white,
                          contentBorderColor: Colors.green,
                          contentBorderWidth: 1,
                          contentHorizontalPadding: 20,
                          scaleWhenAnimating: false,
                          openAndCloseAnimation: true,
                          headerPadding:
                          const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                          sectionOpeningHapticFeedback: SectionHapticFeedback.none,
                          sectionClosingHapticFeedback: SectionHapticFeedback.light,
                          children: auditObj["categorys"].map<AccordionSection>((item)=>AccordionSection(
                            isOpen: true,
                            rightIcon: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.arrow_downward_outlined,color: Colors.black,
                              ),
                            ),
                            headerBorderColorOpened: Colors.blue,
                            headerBorderColor:Colors.black54,
                            headerBorderWidth: 1,
                            contentBorderWidth: 1,
                            headerBackgroundColor: Colors.white12,
                            headerBackgroundColorOpened: Colors.blue.shade50,
                            header: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item["categoryname"]+" - "+item["heading"], style: headTextStyle),
                                SizedBox(height: 5,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Text(AppTranslations.of(context)!.text("key_message_15"),style: headingTextStyle,),
                                            Text(item["answer"],style: paragTextStyle,)
                                          ],
                                        )
                                    ),
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Text(AppTranslations.of(context)!.text("key_message_14"),style: headingTextStyle,),
                                            Text(item["total"],style: paragTextStyle,)
                                          ],
                                        )
                                    ),
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Text(AppTranslations.of(context)!.text("key_message_16"),style: headingTextStyle,),
                                            SizedBox(width:50,child: StatusComp(status: "",statusvalue: item["percentage"].toString()+"%",percentage: int.tryParse(item["percentage"].toString()),))
                                          ],
                                        )
                                    )
                                  ],
                                )
                              ],
                            ),
                            content: questionComp(item["questions"]),
                            contentHorizontalPadding: 20,
                            contentBorderColor: Colors.black54,
                          )).toList(),
                        )
                    ),
                    // if (Responsive.isMobile(context))
                    //   SizedBox(width: defaultPadding),
                    // if (Responsive.isMobile(context))
                    //   getBranchDetails(),
                  ],
                )
            ),
            if (!Responsive.isMobile(context))
              SizedBox(width: defaultPadding),
            if (!Responsive.isMobile(context))
              Flexible(
                  flex: 3,
                  child: getBranchDetails()
              ),
          ],
        ),
      ),
    );
  }
}
