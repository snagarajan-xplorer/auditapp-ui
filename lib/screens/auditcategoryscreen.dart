import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/datatablecontainer.dart';
import 'package:audit_app/widget/norecordcomp.dart';
import 'package:audit_app/widget/pagecontainercomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
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
import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../responsive.dart';
import '../widget/outlinebutton.dart';
import '../widget/scrollviewcomp.dart';
import '../widget/statuscomp.dart';
import 'main/layoutscreen.dart';
import 'dart:js' as js;

class AuditCategoryScreen extends StatefulWidget {
  const AuditCategoryScreen({super.key});

  @override
  State<AuditCategoryScreen> createState() => _AuditCategoryScreenState();
}

class _AuditCategoryScreenState extends State<AuditCategoryScreen> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  GlobalKey<FormBuilderState> formKey02 = GlobalKey<FormBuilderState>();
  List<dynamic> userdata = [];
  double wdt = 950;
  ScreenArgument? pageargument;
  UserController usercontroller = Get.put(UserController());
  final _controller = new PageController(
      keepPage: false
  );
  final _questioncontroller = new PageController(
      keepPage: false
  );
  int answerQuest = 0;
  bool enableAction = true;
  bool showNextBtn = true;
  bool showQuestion = false;
  bool showAudit = false;
  bool showImage = false;
  bool acknowlodgeImage = false;
  bool acknowlodgeBtn = false;
  List<int> childs = [1,0,0,0];
  static const _kCurve = Curves.ease;
  List<GlobalKey> _pageKeys = [GlobalKey(),GlobalKey(),GlobalKey(),GlobalKey()];
  double _currentPageHeight = 460; // Default height

  static const _kDuration = const Duration(milliseconds: 300);

  dynamic auditObj = {};
  dynamic categoryObj = {};
  List<dynamic> questionArray = [];
  List<Widget> questionChildArray = [];
  Color selectedColor = Colors.transparent;
  int activeStep = 0;
  int pageStep = 0;
  int totalpage = 0;

  String imgPath = "";
  Uint8List? _imageBytes; // To store the image data
  String? _imageName; //
  List<Uint8List>? _imageBytesList; // To store the image data
  List<String>? _imageNameList; //
  int countFile = 0;
  int totalFile = 0;
  String totalMark = "0";
  String answerMark = "0";
  String totalPer = "0";
  List<String> extension = [".doc",".docx",".xls",".xlsx",".ppt",".pptx",".pdf",".png",".jpeg",".jpg"];

  Future<void> processAuditCategories() async {
    num ans = 0;
    num totalans = 0;
    int ansValue = 0;
    int totalValue = 0;
    await Future.forEach(auditObj["categorys"], (ele) async {
      dynamic element = ele;
      // if (element["answer"] != null) {
      //   if(element["answer"].toString().trim().isNotEmpty){
      //     String ansStr = element["answer"].toString().trim();
      //     ans += (num.tryParse(ansStr) ?? 0);
      //     String totalStr = element["total"].toString();
      //     totalans += (num.tryParse(totalStr) ?? 0);
      //     totalMark = totalans.toString();
      //     answerMark = ans.toString();
      //     int? v1 = int.tryParse(answerMark);
      //     int? v2 = int.tryParse(totalMark);
      //     if (v1 != null && v2 != null && v2 != 0) {
      //       int percentage = ((v1 / v2) * 100).round();
      //       totalPer = percentage.toString();
      //     } else {
      //       totalPer = "0";
      //     }
      //   }
      // }
      List<dynamic> attendQuestion = element["questions"].where((quest)=>quest["answer"].toString().trim().toString().isNotEmpty).toList();

      attendQuestion.forEach((ele){
        if(ele["answer"] != "N/A"){
          String str = (ele["answer"] ?? "0");
          int d = int.tryParse(str) ?? 0;
          ansValue = ansValue + d;
          totalValue = totalValue + 4;
        }
      });
    });
    totalMark = totalValue.toString();
    answerMark = ansValue.toString();
    int? v1 = int.tryParse(answerMark);
    int? v2 = int.tryParse(totalMark);
    int? percentage = ((v1!/v2!)*100).round();
    totalPer = percentage.toString();
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 200))
        .then((onValue){
      if(usercontroller.userData.role == null){
        usercontroller.loadInitData();
        usercontroller.selectedIndex = 1;
        Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
      }
      pageargument =  ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      Map<String,dynamic> data = {
        "id":pageargument?.mapData["id"]
      };
      usercontroller.getAuditQuestion(context, data: data, callback: (res){
        auditObj = res;
        showAudit = true;
        num ans = 0;
        num totalans = 0;
        int ansValue = 0;
        int totalValue = 0;
        auditObj["categorys"].forEach((element){
          element["submitAns"] = element["answer"].toString().trim().isNotEmpty ? element["answer"].toString().trim() :"";
          element["questions"].forEach((eleObj){
            eleObj["submitAns"] = eleObj["answer"].toString().trim().isNotEmpty ? eleObj["answer"].toString().trim() :"";
          });

          if(element["answer"].toString().trim().isNotEmpty){
            String ansStr = element["answer"].toString().trim();
            ans = ans+(num.tryParse(ansStr) ?? 0);
            String totalStr = element["total"].toString();
            totalans = totalans+(num.tryParse(totalStr) ?? 0);
            totalMark = totalans.toString();
            answerMark = ans.toString();
            int? v1 = int.tryParse(answerMark);
            int? v2 = int.tryParse(totalMark);
            if(v2 != 0){
              int? percentage = ((v1!/v2!)*100).round();
              totalPer = percentage.toString();
            }else{
              totalPer = "";
            }

          }
          List<dynamic> attendQuestion = element["questions"].where((quest)=>quest["answer"].toString().trim().toString().isNotEmpty).toList();

          attendQuestion.forEach((ele){
            if(ele["answer"] != "N/A"){
              String str = (ele["answer"] ?? "0");
              int d = int.tryParse(str) ?? 0;
              ansValue = ansValue + d;
              totalValue = totalValue + 4;

            }
          });

          setCategoryStatus(element);
        });

        totalMark = totalValue.toString();
        answerMark = ansValue.toString();
        int? v1 = int.tryParse(answerMark);
        int? v2 = int.tryParse(totalMark);
        int? percentage = ((v1!/v2!)*100).round();
        totalPer = percentage.toString();
        Future.delayed(Duration(milliseconds: 400))
        .then((eleobj) {
          if (activeStep == 0) {
            if (auditObj["branch"].length != 0) {
              String date = auditObj["branch"][0]["joining_date"].toString();
              auditObj["branch"][0]["joining_date"] = Jiffy
                  .parse(date)
                  .dateTime;
              formKey.currentState!.patchValue(auditObj["branch"][0]);
            }
          }
        });


          setState(() {});
      });
    });
  }
  void _updatePageHeight(int index) {
    if (_pageKeys[index].currentContext != null) {
      final RenderBox renderBox = _pageKeys[index].currentContext!.findRenderObject() as RenderBox;

    }
    setState(() {
      _currentPageHeight = Responsive.isDesktop(context)?450:500;
      if(index == 1){
        _currentPageHeight = Responsive.isDesktop(context)?650:((auditObj["categorys"].length*260)+90);
      }else if(index == 2){
        _currentPageHeight = Responsive.isDesktop(context)?MediaQuery.of(context).size.height:MediaQuery.of(context).size.height+200;
      }else if(index == 3){
        _currentPageHeight = 520;
      }
      print("index ${index} / ${_currentPageHeight}");
    });
  }
  setCategoryStatus(dynamic element){
    element["complete"] = false;
    if(element["total"].toString().trim().isNotEmpty){
      num total = num.tryParse(element["total"].toString()) ?? 0;
      num count = total/4;
      List<dynamic> arr = element["questions"].where((eleobj)=>eleobj["answer"].toString().trim().isNotEmpty).toList();
      print("cont ${arr.length} == ${element['questions'].length}");
      if(arr.length == element["questions"].length){
        element["complete"] = true;
      }
      setState(() {});
    }
  }

  Widget mobileView(fileInfo) {
    return BoxContainer(
        height: 150,
        child: Container(height: 150,)
    );
  }
  gotoPage(){
    _controller.animateToPage(
        activeStep,
        duration: _kDuration,
        curve: _kCurve
    );
    setState(() {

    });
  }
  Widget getAuditComp(element){
    String status = AppTranslations.of(context)!.text("key_start");
    if(element["status"] == "IP"){
      status = AppTranslations.of(context)!.text("key_progress");
    }else if(element["status"] == "C"){
      status = AppTranslations.of(context)!.text("key_complete");
    }else if(element["status"] == "P"){
      status = AppTranslations.of(context)!.text("key_publish");
    }

    String totalQuestion = element["questions"].length.toString();
    List<dynamic> attendQuestion = element["questions"].where((quest)=>quest["answer"].toString().trim().toString().isNotEmpty).toList();
    int ansValue = 0;
    int totalValue = 0;
    attendQuestion.forEach((ele){
      if(ele["answer"] != "N/A"){
        String str = (ele["answer"] ?? "0");
        int d = int.tryParse(str) ?? 0;
        ansValue = ansValue + d;
        totalValue = totalValue + 4;
      }
    });
    element["answer"] = ansValue.toString();
    element["total"] = totalValue.toString();

    num score = element["answer"].toString().isEmpty ? 0 : (num.tryParse(element["answer"].toString()) ?? 0);
    num total = (num.tryParse(element["total"].toString()) ?? 0);
    String value = "";
    if(score != 0 && total != 0){
      int avarge = ((score/total)*100).round();
      value = avarge.toString();
    }

    String answeredQuestion = attendQuestion.length == 0 ? "0" : attendQuestion.length.toString();
    return BoxContainer(
        padding: 10,
        width: 320,
        height: 250,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  height: 70,
                  child: Text(element["categoryname"],style: headingTextStyle,textAlign: TextAlign.center,),
                ),
              ),

              Flexible(
                  flex: 1,
                  child: Visibility(
                      visible: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppTranslations.of(context)!.text("key_average"),style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14
                                  ),),
                                  SizedBox(width:50,child: value.toString().trim().isEmpty?Container():StatusComp(status: "",statusvalue: value.toString()+"%",percentage: int.tryParse((value.toString() ?? "0")),))
                                ],
                              )
                          ),
                          Visibility(
                              visible: true,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(AppTranslations.of(context)!.text("key_message_17"),style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14
                                  ),),
                                  Text(element["answer"].toString().trim().isEmpty? "-/-":element["answer"]+"/"+element["total"],style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14
                                  ),maxLines: 4,)
                                ],
                              )
                          )
                        ],
                      )
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(child: Row(
                      children: [
                        answeredQuestion == totalQuestion ? Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Center(child: Icon(Icons.check_circle,size: 20,color: Colors.green,)),
                        ) : Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Center(child: Icon(Icons.circle_sharp,size: 20,color: Colors.grey,)),
                        ),
                        SizedBox(width: 8,),
                        Center(child: Text(answeredQuestion+"/"+totalQuestion,style: headingSmallTextStyle,))
                      ],
                    )),
                  ),
                  Container(
                    width: 120,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(child: Text(element["heading"],style: headingSmallTextStyle,)),
                  ),
                ],
              ),
              SizedBox(
                height: defaultPadding,
              ),
              ButtonComp(
                width: 100,
                onPressed: (){
                  categoryObj = element;
                  questionArray = [];
                  questionArray = element["questions"];
                  questionChildArray = [];
                  for(var mid = 0;mid <questionArray.length;mid++){
                    questionArray[mid]["index"] = mid;

                    questionArray[mid]["isSaved"] = questionArray[mid]["submitAns"].toString().trim().isNotEmpty ? true : false;
                    questionChildArray.add(questionComp(questionArray[mid]));
                  }
                  pageStep = 0;
                  int d = questionArray.indexWhere((element)=>element["answer"].toString().trim().isNotEmpty);
                  print("dfsdfsd ${d}");
                  if(d != -1){
                    pageStep = d+1;
                  }
                  if(pageStep >= questionArray.length-1){
                    pageStep = 0;
                  }
                  if(answeredQuestion == totalQuestion){
                    pageStep = 0;
                  }
                  totalpage = questionArray.length;
                  childs[1] = 2;
                  activeStep = 2;
                  if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                    selectedColor = Colors.transparent;
                  }else{
                    List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["submitAns"].toString().trim()).toList();
                    if(arr.length != 0){
                      selectedColor = arr[0]["color"];
                    }
                  }
                  showNextBtn = true;
                  List<dynamic> attendQuestion2 = categoryObj["questions"].where((quest)=>quest["answer"].toString().trim().toString().isNotEmpty).toList();
                  answerQuest = attendQuestion2.length;
                  gotoPage();
                  Future.delayed(Duration(milliseconds: 20))
                      .then((v){
                    _questioncontroller.animateToPage(
                        pageStep,
                        duration: _kDuration,
                        curve: _kCurve
                    );
                  });

                  //childs[activeStep] = 1;
                  setState(() {});

                }, label: answeredQuestion == "0" ? AppTranslations.of(context)!.text("key_start") : AppTranslations.of(context)!.text("key_edit"),

              )
            ],
          ),
        )
    );
  }
  Widget categoryChild(){
    return showAudit == false?SizedBox():Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
            flex: 10,
            fit: FlexFit.loose,
            child: Container(
              // height: auditObj["categorys"].length * 270,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                direction: Axis.horizontal,
                children: auditObj["categorys"].map<Widget>((element)=>getAuditComp(element)).toList(),
              ),
            )
        ),
        SizedBox(height: 10,),
        Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Visibility(
                visible: acknowlodgeBtn,
                child: ButtonComp(label: AppTranslations.of(context)!.text("key_btn_acknowledge"), onPressed: (){
                  activeStep = 3;
                  childs[1] = 2;
                  childs[2] = 1;
                  setState(() {});
                  gotoPage();
                  Future.delayed(Duration(milliseconds: 500))
                      .then((value){
                    formKey02.currentState!.patchValue({
                      "name":usercontroller.userData.name,
                      "email":usercontroller.userData.email,
                      "mobileno":usercontroller.userData.mobile,
                    });
                  });
                })
            )
        )
      ],
    );
  }
  fileUploadProcess(question){
    Map<String,dynamic> dataObj = {
      "type":"audit",
      "audit_id":question["audit_id"],
      "questionid":question["questionid"]
    };
    usercontroller.uploadImage(context,bytes: _imageBytesList![countFile], filename: _imageNameList![countFile] ?? "", data: dataObj, callback:(res01){
      if(res01.containsKey("data")){
        question["proofdocuments"].add(res01["data"]);
      }
      setState(() {});
      if(countFile < totalFile - 1){
        countFile++;
        fileUploadProcess(question);
      }
    });
  }
  Widget questionComp(dynamic question){
    return BoxContainer(
      width: wdt-50,
      height: double.infinity,
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
                flex: 5,
                child: Container(


                  padding: EdgeInsets.all(8),
                  width: double.infinity,

                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      border: Border.all(color: Colors.grey.shade400,width: 1.0)
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(question["question"],style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      ),),
                      SizedBox(height: 20,),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: question["answer"].toString().trim().isEmpty?Colors.white:selectedColor,
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            border: Border.all(color: Colors.grey.shade400,width: 1.0)
                        ),
                        child: Center(
                          child: Text(question["answer"],style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800
                          )),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Text(AppTranslations.of(context)!.text("key_score")),
                      SizedBox(height: 10,),
                      Wrap(
                        children: usercontroller.scoreArr.map((element) => Container(
                          width: 80,
                          height: 50,
                          margin: EdgeInsets.only(top: 7,bottom: 7),
                          color: element["color"],
                          child: InkWell(
                            onTap: (){
                              question["answer"] = element["value"];
                              print(question);

                              selectedColor = element["color"];
                              enableAction = false;
                              setState(() {});
                              // if(element["value"].toString() != "N/A"){
                              //
                              //   List<dynamic> qarray = questionArray.where((eleobj)=>eleobj["answer"].toString().trim().isNotEmpty && !eleobj["answer"].toString().trim().contains("N/A")).toList();
                              //   num total = 0;
                              //   num ans = 0;
                              //   qarray.forEach((eleobj){
                              //     ans = ans+(num.tryParse(eleobj["answer"].toString()) ?? 0);
                              //     total = total+4;
                              //   });
                              //   categoryObj["answer"] = ans.toString();
                              //   categoryObj["total"] = total.toString();
                              //   setState(() {});
                              // }else{
                              //   if(categoryObj["answer"].toString().trim().isEmpty){
                              //     categoryObj["answer"] = " ";
                              //   }
                              //   if(categoryObj["total"].toString().trim().isEmpty){
                              //     categoryObj["total"] = " ";
                              //   }
                              // }

                            },
                            child: Center(
                              child: Text(element["value"].toString(),style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800
                              ),),
                            ),
                          ),
                        )).toList(),
                      ),
                      Wrap(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            child: Text("0 : <20% compliance",style: headingSmallTextStyle,),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            child: Text("1 : >20-49% complaince",style: headingSmallTextStyle,),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            child: Text("2 : >49%-75% complaince",style: headingSmallTextStyle,),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            child: Text("3 : >75%-99% compliance",style: headingSmallTextStyle,),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            child: Text("4 : Full Compliance",style: headingSmallTextStyle,),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
            ),
            SizedBox(height: 10,),
            FormBuilderTextField(
              name: "reviews",
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              initialValue: question["reviews"],
              validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                  errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (value){
                question["reviews"] = value;
                setState(() {});
              },
              decoration:  InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: AppTranslations.of(context)!.text("key_review"),
                    children: [
                      TextSpan(
                          style: TextStyle(color: Colors.red),
                          text: ''
                      )
                    ],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                contentPadding: EdgeInsets.only(left: 20,top: 25),
                counterText: "",
                errorMaxLines: 3,
                border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.red, width: 1.0)),

              ),
            ),
            SizedBox(height: 10,),
            FormBuilderTextField(
              name: "clientremarks",
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              initialValue: question["clientremarks"],
              validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                  errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (value){
                question["clientremarks"] = value;
                setState(() {});
              },
              decoration:  InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: AppTranslations.of(context)!.text("key_customer_review"),
                    children: [
                      TextSpan(
                          style: TextStyle(color: Colors.red),
                          text: ''
                      )
                    ],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                contentPadding: EdgeInsets.only(left: 20,top: 25),
                counterText: "",
                errorMaxLines: 3,
                border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.red, width: 1.0)),

              ),
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: question["dropdown"].map<Widget>((element2)=>Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: FormBuilderDropdown<dynamic>(
                    name: "zone",
                    initialValue: element2["selectedoption"],
                    items: element2["options"].map<DropdownMenuItem<dynamic>>((toElement)=>DropdownMenuItem(
                      value: toElement["optionvalue"],
                      child: Text(toElement["optionvalue"]),
                    )).toList(),
                    onChanged: (value){
                      print(value);
                      List<dynamic> arr = question["selecteddropdown"].where((item)=>item["dropdownid"] == element2["dropdownid"]).toList();
                      if(arr.length == 0){
                        var obj = {
                          "dropdownid": element2["dropdownid"],
                          "dropdownname":element2["dropdownname"],
                          "selectedoption":value
                        };
                        question["selecteddropdown"].add(obj);
                      }else{
                        arr[0]["selectedoption"] = value;
                      }
                    },
                    validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                        errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                    decoration:  InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: element2["dropdownname"],
                          children: [
                            TextSpan(
                                style: TextStyle(color: Colors.red),
                                text: ' *'
                            )
                          ],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      contentPadding: EdgeInsets.only(left: 20,top: 10),
                      counterText: "",
                      errorMaxLines: 3,
                      border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                          borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                      enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                          borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                      focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                          borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                      errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                          borderSide: BorderSide(color: Colors.red, width: 1.0)),
                      suffixIcon: null,

                    ),
                  ),
                ),
              )
              ).toList(),
            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Flexible(
                    flex:1,
                    child: SizedBox(
                      width: 150,
                     height: buttonHeight,
                      child: ElevatedButton.icon(onPressed: () async {
                        if(question["proofdocuments"].length == 10){
                          APIService(context).showToastMgs(AppTranslations.of(context)!.text("key_error_04"));
                          return;
                        }
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                           // Restrict to image files
                          allowMultiple: true,
                        );
                        _imageBytesList = [];
                        _imageNameList = [];
                        countFile = 0;
                        setState(() {});
                        if (result != null && result.files.isNotEmpty) {
                          totalFile = result.files.length;
                          setState(() {});
                          for(var kid = 0; kid < result.files.length; kid++){
                            var file = result.files[kid];
                            var index = file.name.lastIndexOf(".");
                            var ext = file.name.substring(index,file.name.length);
                             if(extension.indexOf(ext) == -1){
                               APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_28"),callback: (){});
                               return;
                             }
                            _imageBytesList!.add(file.bytes!);
                             _imageNameList!.add(file.name);
                          }
                          setState(() {});
                          fileUploadProcess(question);

                        }
                      }, icon:Icon(Icons.cloud_upload,size: 20,color: Colors.white,),label: Text(AppTranslations.of(context)!.text("key_btn_upload"),style: TextStyle(
                        color: Colors.white
                      ),)),
                    )
                ),
                Flexible(
                    flex:2,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      runAlignment: WrapAlignment.start,
                      children: question["proofdocuments"].map<Widget>((imgelement){
                        bool image = true;
                        String name = imgelement["image"].toString();
                        var index  = name.lastIndexOf(".");
                        var ext = name.substring(index,name.length);
                        String img = "assets/images/doc.png";
                        if(ext.contains("doc")){
                          image = false;
                          img = "assets/images/doc.png";
                        }else if(ext.contains("xls")){
                          image = false;
                          img = "assets/images/xls.png";
                        }else if(ext.contains("pdf")){
                          image = false;
                          img = "assets/images/pdf.png";
                        }else if(ext.contains("ppt")){
                          image = false;
                          img = "assets/images/ppt.png";
                        }

                        return Container(
                          width: 90,
                          height: 90,
                          margin: EdgeInsets.only(left: 5,right: 5),
                          child: Stack(
                            children: [

                              Positioned(
                                  left: 0,
                                  top:0,
                                  child: InkWell(
                                    onTap: (){
                                      js.context.callMethod('open', [IMG_URL+imgelement["image"].toString(),"_blank"]);
                                    },
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: image ? NetworkImage(IMG_URL+imgelement["image"],):AssetImage(img)
                                          ),
                                          borderRadius: BorderRadius.circular(8)
                                      ),
                                    ),
                                  )
                              ),
                              Positioned(
                                  right: 0,
                                  top:0,
                                  child: InkWell(
                                    onTap: (){
                                      APIService(context).showWindowAlert(title:"",desc:AppTranslations.of(context)!.text("key_are_you"),showCancelBtn: true,callback: (){
                                        Map<String,dynamic> obj = {
                                          "id":imgelement["id"],
                                          "audit_id":imgelement["audit_id"],
                                          "question_id":imgelement["question_id"]
                                        };
                                        usercontroller.removeUploadFile(context, data: obj, callback:(arr){
                                          question["proofdocuments"] = arr;
                                          setState(() {});
                                        });
                                      });

                                    },
                                    child: SvgPicture.asset(
                                      "assets/icons/close.svg",
                                      colorFilter: ColorFilter.mode(Colors.blue.shade900, BlendMode.srcIn),
                                      height: 24,
                                    ),
                                  )
                              ),

                            ],
                          ),
                        );
                      }).toList(),
                    )
                )

              ],
            ),


          ],
        ),
      ),
    );
  }
  Color getColor(element,index){
    Color c = Colors.grey.shade400;
    if(element["answer"].toString().trim().isEmpty){
      if(pageStep == index-1){
        c = Colors.blue.shade900;
      }
    }else{
      c = Colors.green.shade900;
      if(pageStep == index-1){
        c = Colors.blue.shade900;
      }
    }
    return c;
  }
  Widget questionChild(){
    int id = 0;
    return Container(
      height: _currentPageHeight,
      child: Center(
        child: Column(
          mainAxisSize:MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: wdt+40,
              height: Responsive.isMobile(context)?100:50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      flex:2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(categoryObj["categoryname"] ?? "",style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,fontSize: 15,fontWeight: FontWeight.w600
                        ),),
                      )
                  ),
                  Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text((answerQuest).toString()+"/"+questionArray.length.toString(),style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,fontSize: 15,fontWeight: FontWeight.w600
                        ),),
                      )
                  )
                ],
              ),
            ),
            SizedBox(
              height: defaultPadding,
            ),

            Flexible(
                flex: 10,
                child: SizedBox(
                  width: wdt+40,
                  child: questionArray.length != 0 ? Row(
                    mainAxisSize:MainAxisSize.min,
                    children: [
                      Flexible(
                        flex:10,
                          child: SizedBox(
                            child: PageView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: questionArray.length,
                              controller:_questioncontroller,
                              itemBuilder: (context,index){
                                dynamic d = questionArray[index];
                                return questionComp(d);
                              },
                            ),
                          )
                      ),
                      SizedBox(
                        child: Column(
                          mainAxisSize:MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: questionArray.map((element){
                            id++;
                            return InkWell(
                              onTap: (){
                                // if(element["answer"].toString().trim().isNotEmpty){
                                //
                                // }
                                if(questionArray[pageStep]["answer"].toString().trim().isNotEmpty){
                                  if(questionArray[pageStep]["submitAns"].toString().trim().isEmpty){
                                    APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){
                                      saveAnswerQuestion(onCallback: (id){
                                        pageStep = element["index"];
                                        if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                                          selectedColor = Colors.transparent;
                                        }else{
                                          List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString().trim()).toList();
                                          if(arr.length != 0){
                                            selectedColor = arr[0]["color"];
                                          }
                                        }
                                        print(questionArray[pageStep]);
                                        _questioncontroller.animateToPage(
                                            pageStep,
                                            duration: _kDuration,
                                            curve: _kCurve
                                        );
                                        setState(() {});
                                      });
                                    },showCancelBtn: true,okbutton:AppTranslations.of(context)!.text("key_btn_save") );
                                    return;
                                  }
                                }

                                pageStep = element["index"];
                                if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                                  selectedColor = Colors.transparent;
                                }else{
                                  List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString().trim()).toList();
                                  if(arr.length != 0){
                                    selectedColor = arr[0]["color"];
                                  }
                                }
                                print(questionArray[pageStep]);
                                _questioncontroller.animateToPage(
                                    pageStep,
                                    duration: _kDuration,
                                    curve: _kCurve
                                );
                                setState(() {});
                              },
                              child: Container(
                                width: pageStep == element["index"] ? 30 : 20,
                                height: 30,
                                margin: EdgeInsets.only(top: 4,bottom: 4),
                                decoration: BoxDecoration(
                                    color: getColor(element,id),
                                    borderRadius: BorderRadius.only(topRight:Radius.circular(10),bottomRight: Radius.circular(10) )
                                ),
                                child: Center(
                                  child: Text((id).toString(),style: TextStyle(
                                      color: Colors.white
                                  ),),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ):Container(),
                )
            ),
          ],
        ),
      ),
    );
  }
  Widget basicChild(){
    return Container(
      height: 400,

      child: Center(
        child: BoxContainer(
            width: wdt,
            height: double.infinity,
            child: Center(
              child: Container(
                width: wdt,

                child: FormBuilder(
                    key: formKey,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 815,
                          child: FormBuilderTextField(
                            name: "managername",
                            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            onChanged: (value){

                            },
                            decoration:  InputDecoration(
                              label: RichText(
                                text: TextSpan(
                                  text: AppTranslations.of(context)!.text("key_branch"),
                                  children: [
                                    TextSpan(
                                        style: TextStyle(color: Colors.red),
                                        text: ' *'
                                    )
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(left: 20,top: 10),
                              counterText: "",
                              errorMaxLines: 3,
                              border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: Colors.red, width: 1.0)),

                            ),
                          ),
                        ),
                        SizedBox(height: defaultPadding,),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 10,
                          runSpacing: 10,
                          direction: Axis.horizontal,
                          children: [
                            SizedBox(
                              width: 400,
                              child: FormBuilderTextField(
                                name: "idcardno",
                                validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                    errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                style: Theme.of(context).textTheme.bodyMedium,
                                onChanged: (value){

                                },
                                decoration:  InputDecoration(
                                  label: RichText(
                                    text: TextSpan(
                                      text: AppTranslations.of(context)!.text("key_idcard"),
                                      children: [
                                        TextSpan(
                                            style: TextStyle(color: Colors.red),
                                            text: ' *'
                                        )
                                      ],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.only(left: 20,top: 10),
                                  counterText: "",
                                  errorMaxLines: 3,
                                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                                  enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: Colors.red, width: 1.0)),

                                ),
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              child: FormBuilderDateTimePicker(
                                name: "joining_date",
                                initialDate: Jiffy.now().dateTime,
                                firstDate: Jiffy.now().subtract(years: 40).dateTime,
                                lastDate: Jiffy.now().dateTime,
                                validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                    errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                                timePickerInitialEntryMode: TimePickerEntryMode.dialOnly,
                                style: Theme.of(context).textTheme.bodyMedium,
                                inputType: InputType.date,
                                decoration:  InputDecoration(
                                  label: RichText(
                                    text: TextSpan(
                                      text: AppTranslations.of(context)!.text("key_joiningdate"),
                                      children: [
                                        TextSpan(
                                            style: TextStyle(color: Colors.red),
                                            text: ' *'
                                        )
                                      ],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.only(left: 20,top: 10),
                                  counterText: "",
                                  errorMaxLines: 3,
                                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                                  enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: Colors.red, width: 1.0)),
                                  suffixIcon: Icon(
                                    CupertinoIcons.calendar_badge_plus,
                                    size: 20.0,
                                  ),

                                ),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: defaultPadding,),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 10,
                          runSpacing: 10,
                          direction: Axis.horizontal,
                          children: [
                            SizedBox(
                              width: 400,
                              child: FormBuilderTextField(
                                name: "phoneno",
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                                  FormBuilderValidators.minLength(10,
                                      errorText: AppTranslations.of(context)!.text("key_error_03") ?? ""),
                                  FormBuilderValidators.maxLength(10,
                                      errorText: AppTranslations.of(context)!.text("key_error_03") ?? "")
                                ]),
                                style: Theme.of(context).textTheme.bodyMedium,
                                onChanged: (value){

                                },
                                decoration:  InputDecoration(
                                  label: RichText(
                                    text: TextSpan(
                                      text: AppTranslations.of(context)!.text("key_phoneno"),
                                      children: [
                                        TextSpan(
                                            style: TextStyle(color: Colors.red),
                                            text: ' *'
                                        )
                                      ],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.only(left: 20,top: 10),
                                  counterText: "",
                                  errorMaxLines: 3,
                                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                                  enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: Colors.red, width: 1.0)),

                                ),
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              child: FormBuilderTextField(
                                name: "emailid",
                                validator: FormBuilderValidators.compose(
                                    [
                                      FormBuilderValidators.required(
                                          errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                                      FormBuilderValidators.email(
                                          errorText: AppTranslations.of(context)!.text("key_error_02") ?? "")
                                    ]),
                                style: Theme.of(context).textTheme.bodyMedium,
                                onChanged: (value){

                                },
                                decoration:  InputDecoration(
                                  label: RichText(
                                    text: TextSpan(
                                      text: AppTranslations.of(context)!.text("key_username"),
                                      children: [
                                        TextSpan(
                                            style: TextStyle(color: Colors.red),
                                            text: ' *'
                                        )
                                      ],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.only(left: 20,top: 10),
                                  counterText: "",
                                  errorMaxLines: 3,
                                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                                  enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                                  errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                      borderSide: BorderSide(color: Colors.red, width: 1.0)),

                                ),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: defaultPadding,),
                        ButtonComp(
                            width: 200,
                            label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
                          if(formKey.currentState!.saveAndValidate()){
                            Map<String,dynamic> obj = Map.of(formKey.currentState!.value);
                            obj["joining_date"] = Jiffy.parseFromDateTime(obj["joining_date"]).dateTime.toIso8601String();
                            obj["audit_id"] = auditObj["id"];
                            usercontroller.saveAuditBranch(context, data: obj, callback:(){
                              List<dynamic> catearr = auditObj["categorys"].where((eleobj)=>eleobj["complete"] == true).toList();
                              print(" second ${auditObj["categorys"].length} == ${catearr.length}");
                              if(auditObj["categorys"].length == catearr.length){
                                childs[2] = 0;
                                childs[0] = 2;
                                childs[1] = 2;
                                activeStep = 1;
                                acknowlodgeBtn = true;
                                setState(() {});
                                gotoPage();


                                setState(() {});
                              }else{
                                Future.delayed(Duration(milliseconds: 200))
                                    .then((vale){
                                  childs[activeStep] = 2;

                                  activeStep = 1;
                                  setState(() {});
                                  gotoPage();
                                  childs[activeStep] = 1;
                                  setState(() {});
                                });
                              }

                            });

                            //formKey.currentState!.value["start_date"] =

                          }
                        })
                      ],

                    )
                ),
              ),
            )
        ),
      ),
    );
  }
  Widget acknowledgeChild(){
    return Container(
        width: wdt,
        height: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
                flex: 12,
                child: BoxContainer(
                  height: 450,
                  width: wdt,
                  child: FormBuilder(
                      key: formKey02,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          FormBuilderTextField(
                            name: "name",
                            enabled: false,
                            validator: FormBuilderValidators.compose([FormBuilderValidators.required(
                                errorText: AppTranslations.of(context)!.text("key_error_01") ?? "")]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            onChanged: (value){

                            },
                            decoration:  InputDecoration(
                              label: RichText(
                                text: TextSpan(
                                  text: AppTranslations.of(context)!.text("key_name"),
                                  children: [
                                    TextSpan(
                                        style: TextStyle(color: Colors.red),
                                        text: ' *'
                                    )
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(left: 20,top: 10),
                              counterText: "",
                              errorMaxLines: 3,
                              border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: Colors.red, width: 1.0)),

                            ),
                          ),
                          SizedBox(height: defaultPadding,),
                          FormBuilderTextField(
                            name: "email",
                            enabled: false,
                            validator: FormBuilderValidators.compose(
                                [
                                  FormBuilderValidators.required(
                                      errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                                  FormBuilderValidators.email(
                                      errorText: AppTranslations.of(context)!.text("key_error_02") ?? "")
                                ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            onChanged: (value){

                            },
                            decoration:  InputDecoration(
                              label: RichText(
                                text: TextSpan(
                                  text: AppTranslations.of(context)!.text("key_username"),
                                  children: [
                                    TextSpan(
                                        style: TextStyle(color: Colors.red),
                                        text: ' *'
                                    )
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(left: 20,top: 10),
                              counterText: "",
                              errorMaxLines: 3,
                              border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: Colors.red, width: 1.0)),

                            ),
                          ),

                          SizedBox(height: defaultPadding,),
                          FormBuilderTextField(
                            name: "mobileno",
                            enabled: false,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!.text("key_error_01") ?? ""),
                              FormBuilderValidators.minLength(10,
                                  errorText: AppTranslations.of(context)!.text("key_error_03") ?? ""),
                              FormBuilderValidators.maxLength(10,
                                  errorText: AppTranslations.of(context)!.text("key_error_03") ?? "")
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            onChanged: (value){

                            },
                            decoration:  InputDecoration(
                              label: RichText(
                                text: TextSpan(
                                  text: AppTranslations.of(context)!.text("key_phoneno"),
                                  children: [
                                    TextSpan(
                                        style: TextStyle(color: Colors.red),
                                        text: ' *'
                                    )
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(left: 20,top: 10),
                              counterText: "",
                              errorMaxLines: 3,
                              border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
                              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
                              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                                  borderSide: BorderSide(color: Colors.red, width: 1.0)),

                            ),
                          ),
                          SizedBox(height: defaultPadding,),
                          Container(
                            width: 300,
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 150,
                                  height: buttonHeight,
                                  child: ElevatedButton.icon(onPressed: () async {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                                      type: FileType.image, // Restrict to image files
                                      allowMultiple: false,
                                      withData: true,
                                    );

                                    if (result != null && result.files.isNotEmpty) {
                                      setState(() {
                                        showImage = false;
                                        acknowlodgeImage = true;
                                        _imageBytes = result.files.first.bytes; // Image data
                                        _imageName = result.files.first.name;  // File name
                                      });
                                      setState(() {});
                                    }
                                  }, icon:Icon(Icons.cloud_upload,size: 20,color: Colors.white,),label: Text(AppTranslations.of(context)!.text("key_btn_upload"),style: TextStyle(
                                      color: Colors.white
                                  ),)),
                                ),
                                Container(
                                  width: 90,
                                  child: acknowlodgeImage == true ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover, // Adjust the image display
                                  ):SizedBox(),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: defaultPadding,),
                          ButtonComp(
                              width: 200,

                              label: AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
                            if(acknowlodgeImage == false){
                              APIService(context).showWindowAlert(title:"",desc: AppTranslations.of(context)!.text("key_error_06"),callback: (){});
                              return;
                            }
                            Map<String,dynamic> obj = {};
                            obj["user_id"] = usercontroller.userData.userId;
                            obj["role"] = usercontroller.userData.role;
                            obj["audit_id"] = auditObj["id"];
                            obj["name"] = usercontroller.userData.name;
                            obj["email"] = usercontroller.userData.email;
                            obj["mobileno"] = usercontroller.userData.mobile;
                            usercontroller.saveAuditAcknowledge(context, data: obj, callback:(){
                              Map<String,dynamic> dataObj = {
                                "type":"acknowledge",
                                "audit_id":auditObj["id"],
                                "user_id":usercontroller.userData.userId
                              };
                              usercontroller.uploadImage(context,bytes: _imageBytes, filename: _imageName ?? "", data: dataObj, callback:(res01){
                                Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
                              });
                            });
                          }),
                          SizedBox(height: defaultPadding,),
                        ],

                      )
                  ),
                )
            )
          ],
        )
    );
  }
  void saveAnswerQuestion({required Function(int) onCallback}){
    Map<String,dynamic> data = {
      "audit_id":questionArray[pageStep]["audit_id"],
      "category_id":questionArray[pageStep]["category_id"],
      "questionid":questionArray[pageStep]["questionid"],
      "reviews":questionArray[pageStep]["reviews"],
      "clientremarks":questionArray[pageStep]["clientremarks"],
      "answer":questionArray[pageStep]["answer"],
      "cateanswer":categoryObj["answer"],
      "catetotal":categoryObj["total"],
      "selecteddropdown":questionArray[pageStep]["selecteddropdown"]
    };
    usercontroller.saveAuditQuestion(context, data: data, callback: () async {
      questionArray[pageStep]["submitAns"] = questionArray[pageStep]["answer"].toString().trim();
      enableAction = true;
      List<dynamic> qarray = questionArray.where((eleobj)=>eleobj["answer"].toString().trim().isNotEmpty && !eleobj["answer"].toString().trim().contains("N/A")).toList();
      num total = 0;
      num ans = 0;
      qarray.forEach((eleobj){
        ans = ans+(num.tryParse(eleobj["answer"].toString()) ?? 0);
        total = total+4;
      });
      categoryObj["answer"] = ans.toString();
      categoryObj["total"] = total.toString();
      await processAuditCategories();
      List ansList = questionArray.where((ele)=>ele["submitAns"].toString().trim().isNotEmpty).toList();
      answerQuest = ansList.length;
      if(ansList.length == questionArray.length){
        showNextBtn = false;
        setState(() {});
        setCategoryStatus(categoryObj);
        List<dynamic> catearr = auditObj["categorys"].where((obj)=>obj["complete"] == true).toList();
        String categoryname = categoryObj["categoryname"];
        Widget child = Container(
          height: 80,
          child: Column(
            children: [
              Text(categoryname,style: headingTextStyle,),
              SizedBox(height: 30,),
              Text(AppTranslations.of(context)!.text("key_message_13"),style: paragraphTextStyle,),
            ],

          ),
        );
        if(auditObj["categorys"].length == catearr.length){
          childs[2] = 0;
          childs[0] = 2;
          childs[1] = 2;
          APIService(context).showWindowAlert(title: "",desc: "",child:child,callback: (){
            activeStep = 1;
            gotoPage();
            acknowlodgeBtn = true;
            setState(() {});
          });
          setState(() {});
        }else{
          APIService(context).showWindowAlert(title: "",desc: "",child:child,callback: (){
            activeStep = 1;
            gotoPage();
            setState(() {});
          });
        }
      }else{
        onCallback(1);
      }
      setState(() {});
    });
  }
  Widget getChildNew(){
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoxContainer(
              width: 650,
              height: 90,
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
                      DataCell(Container(child: Center(child: SizedBox(width:50,child: StatusComp(status: "",statusvalue: totalPer.toString()+"%",percentage: int.tryParse(totalPer.toString()),)))))
                    ])
                  ]
                  )
              ),
            ),
            SizedBox(height: defaultPadding,),
            Flexible(
              flex: 12,
              fit: FlexFit.loose,
              child: Container(
                height: double.infinity,
                // constraints: BoxConstraints(
                //   minHeight: 0,
                //   maxHeight: 2500, // some max limit to avoid infinite height
                // ),
                child: ExpandablePageView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: childs.length,
                  controller: _controller,
                  onPageChanged: (index) => _updatePageHeight(index),
                  itemBuilder: (BuildContext context, int index) {
                    if(index == 0){
                      return basicChild();
                    }else if(index == 1){
                      return categoryChild();
                    }else if(index == 2){
                      return questionChild();
                    }else if(index == 3){
                      return acknowledgeChild();
                    }else{
                      return Container();
                    }
                  }
                  ,),
              ),
            ),
            SizedBox(height: defaultPadding,),
            Visibility(
                visible: activeStep == 2 ? true : false,
                child: Center(
                  child: SizedBox(
                    width: 350,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        ButtonComp(
                            width: 120,
                            label: AppTranslations.of(context)!.text("key_btn_save")
                            , onPressed:(){
                          if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                            APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_27"),callback: (){});
                            return;
                          }
                          List ansList = questionArray.where((ele)=>ele["submitAns"].toString().trim().isNotEmpty).toList();
                          if(ansList.length == questionArray.length-1){
                            showNextBtn = false;
                            setState(() {});
                          }
                          saveAnswerQuestion(onCallback: (id){});
                          /*
                          if(ansList.length < questionArray.length-1){

                            Map<String,dynamic> data = {
                              "audit_id":questionArray[pageStep]["audit_id"],
                              "category_id":questionArray[pageStep]["category_id"],
                              "questionid":questionArray[pageStep]["questionid"],
                              "reviews":questionArray[pageStep]["reviews"],
                              "clientremarks":questionArray[pageStep]["clientremarks"],
                              "answer":questionArray[pageStep]["answer"],
                              "cateanswer":categoryObj["answer"],
                              "catetotal":categoryObj["total"],
                              "selecteddropdown":questionArray[pageStep]["selecteddropdown"]
                            };
                            usercontroller.saveAuditQuestion(context, data: data, callback: () async {
                              questionArray[pageStep]["submitAns"] = questionArray[pageStep]["answer"].toString().trim();
                              enableAction = true;
                              List<dynamic> qarray = questionArray.where((eleobj)=>eleobj["answer"].toString().trim().isNotEmpty && !eleobj["answer"].toString().trim().contains("N/A")).toList();
                              num total = 0;
                              num ans = 0;
                              qarray.forEach((eleobj){
                                ans = ans+(num.tryParse(eleobj["answer"].toString()) ?? 0);
                                total = total+4;
                              });
                              categoryObj["answer"] = ans.toString();
                              categoryObj["total"] = total.toString();
                              await processAuditCategories();
                              setState(() {});
                            });
                          }else{
                            Map<String,dynamic> data = {
                              "audit_id":questionArray[pageStep]["audit_id"],
                              "category_id":questionArray[pageStep]["category_id"],
                              "questionid":questionArray[pageStep]["questionid"],
                              "reviews":questionArray[pageStep]["reviews"],
                              "clientremarks":questionArray[pageStep]["clientremarks"],
                              "answer":questionArray[pageStep]["answer"],
                              "cateanswer":categoryObj["answer"],
                              "catetotal":categoryObj["total"],
                              "selecteddropdown":questionArray[pageStep]["selecteddropdown"]
                            };
                            usercontroller.saveAuditQuestion(context, data: data, callback: () async {
                              if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                                selectedColor = Colors.transparent;
                              }else{
                                List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString().trim()).toList();
                                if(arr.length != 0){
                                  selectedColor = arr[0]["color"];
                                }
                              }
                              questionArray[pageStep]["submitAns"] = questionArray[pageStep]["answer"].toString().trim();
                              enableAction = true;
                              List<dynamic> qarray = questionArray.where((eleobj)=>eleobj["answer"].toString().trim().isNotEmpty && !eleobj["answer"].toString().trim().contains("N/A")).toList();
                              num total = 0;
                              num ans = 0;
                              qarray.forEach((eleobj){
                                ans = ans+(num.tryParse(eleobj["answer"].toString()) ?? 0);
                                total = total+4;
                              });
                              categoryObj["answer"] = ans.toString();
                              categoryObj["total"] = total.toString();
                              setCategoryStatus(categoryObj);
                              List<dynamic> catearr = auditObj["categorys"].where((obj)=>obj["complete"] == true).toList();
                              await processAuditCategories();
                              String categoryname = categoryObj["categoryname"];
                              Widget child = Container(
                                height: 80,
                                child: Column(
                                  children: [
                                    Text(categoryname,style: headingTextStyle,),
                                    SizedBox(height: 30,),
                                    Text(AppTranslations.of(context)!.text("key_message_13"),style: paragraphTextStyle,),
                                  ],

                                ),
                              );
                              if(auditObj["categorys"].length == catearr.length){
                                childs[2] = 0;
                                childs[0] = 2;
                                childs[1] = 2;
                                APIService(context).showWindowAlert(title: "",desc: "",child:child,callback: (){
                                  activeStep = 1;
                                  gotoPage();
                                  acknowlodgeBtn = true;
                                  setState(() {});
                                });
                                setState(() {});
                              }else{

                                APIService(context).showWindowAlert(title: "",desc: "",child:child,callback: (){
                                  activeStep = 1;
                                  gotoPage();
                                  setState(() {});
                                });

                              }
                            });
                          }

                           */
                          setState(() {});
                        }),
                        SizedBox(width: 60,),
                        Visibility(
                            visible: showNextBtn,
                            child: ButtonComp(
                                width: 120,
                                label: AppTranslations.of(context)!.text("key_btn_next")
                                , onPressed:() async {
                              if(questionArray[pageStep]["submitAns"].toString().trim().isEmpty ){
                                APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){
                                  saveAnswerQuestion(onCallback: (id) async {
                                    if(pageStep < questionArray.length-1){
                                      pageStep++;
                                      if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                                        selectedColor = Colors.transparent;
                                      }else{
                                        List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString().trim()).toList();
                                        if(arr.length != 0){
                                          selectedColor = arr[0]["color"];
                                        }
                                      }
                                      await processAuditCategories();
                                      _questioncontroller.animateToPage(
                                          pageStep,
                                          duration: _kDuration,
                                          curve: _kCurve
                                      );
                                      setState(() {});
                                    }
                                  });
                                },showCancelBtn: true,okbutton:AppTranslations.of(context)!.text("key_btn_save") );
                                return;
                              }
                              if(pageStep < questionArray.length-1){
                                pageStep++;
                                if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
                                  selectedColor = Colors.transparent;
                                }else{
                                  List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString().trim()).toList();
                                  if(arr.length != 0){
                                    selectedColor = arr[0]["color"];
                                  }
                                }
                                await processAuditCategories();
                                _questioncontroller.animateToPage(
                                    pageStep,
                                    duration: _kDuration,
                                    curve: _kCurve
                                );
                                setState(() {});
                              }
                              setState(() {});
                            })
                        ),
                        SizedBox(width: 30,)
                      ],
                    ),
                  ),
                )
            ),
            // Visibility(
            //     visible: activeStep == 2 ? true : false,
            //     child: Center(
            //       child: Container(
            //         width: wdt+40,
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             ButtonComp(
            //                 width: 120,
            //                 label: AppTranslations.of(context)!.text("key_btn_back")
            //                 , onPressed:(){
            //               if(pageStep > 0){
            //                 pageStep--;
            //                 if(questionArray[pageStep]["answer"].toString().trim().isEmpty){
            //                   selectedColor = Colors.transparent;
            //                 }else{
            //                   List<dynamic> arr = usercontroller.scoreArr.where((e)=>e["value"] == questionArray[pageStep]["answer"].toString()).toList();
            //                   if(arr.length != 0){
            //                     selectedColor = arr[0]["color"];
            //                   }
            //                 }
            //                 _questioncontroller.animateToPage(
            //                     pageStep,
            //                     duration: _kDuration,
            //                     curve: _kCurve
            //                 );
            //                 setState(() {});
            //
            //               }
            //
            //               setState(() {});
            //
            //             }),
            //             Row(
            //               children: [
            //                 SizedBox(
            //                   width: 40,
            //                 )
            //               ],
            //             )
            //           ],
            //         ),
            //       ),
            //     )
            // )
          ],
        ),
      ),
    );
  }
  String getBackButtonName(){
    String title = AppTranslations.of(context)!.text("key_auditinfo");
    if(activeStep == 0){
      title = AppTranslations.of(context)!.text("key_auditinfo");
    }else if(activeStep == 1){
      title = AppTranslations.of(context)!.text("key_message_23");
    }else if(activeStep == 2){
      title = AppTranslations.of(context)!.text("key_message_22");
    }else if(activeStep == 3){
      title = AppTranslations.of(context)!.text("key_message_22");
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      onCallback: (id){
        APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){
          saveAnswerQuestion(onCallback: (mid){
            usercontroller.selectedIndex = id;
            if(id == 0){
              Navigator.pushNamed(context, "/dashboard");
            }else if(id == 1){
              Navigator.pushNamed(context, "/auditlist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
            }else if(id == 2){
              Navigator.pushNamed(context, "/client",arguments: ScreenArgument(argument: ArgumentData.CLIENT,mapData: {}));
            }else if(id == 3){
              Navigator.pushNamed(context, "/user",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
            }else if(id == 4){
              Navigator.pushNamed(context, "/templatelist",arguments: ScreenArgument(argument: ArgumentData.USER,mapData: {}));
            }else if(id == 5){
              APIService(context).showWindowAlert(title:"",desc: AppTranslations.of(context)!.text("key_message_09"),showCancelBtn: true,callback: (){
                usercontroller.logout(context, data: {}, callback: (){
                  Navigator.pushNamed(context, "/login");
                  //Get.offNamed("/login");
                });
              });
            }
          });
        },showCancelBtn: true,okbutton:AppTranslations.of(context)!.text("key_btn_save"));
      },
      enableAction: enableAction,
      previousScreenName:getBackButtonName(),
      backEvent: (){
        if(activeStep == 0){
          Navigator.of(context).pop();
        }else if(activeStep == 1){
          activeStep = 0;
          if(auditObj["branch"].length != 0){
            Future.delayed(Duration(milliseconds: 400))
                .then((value){
              String date = auditObj["branch"][0]["joining_date"].toString();
              auditObj["branch"][0]["joining_date"] = Jiffy.parse(date).dateTime;
              formKey.currentState!.patchValue(auditObj["branch"][0]);
            });
          }
        }else if(activeStep == 2){
          if(questionArray[pageStep]["answer"].toString().trim().isNotEmpty ) {
            if(questionArray[pageStep]["submitAns"].toString().trim().isNotEmpty){
              activeStep = 1;
            }else{
              APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){
                saveAnswerQuestion(onCallback: (id){
                  activeStep = 1;
                });
              },showCancelBtn: true,okbutton:AppTranslations.of(context)!.text("key_btn_save") );
            }
          }else{
            activeStep = 1;
          }
          setState(() {});

        }else if(activeStep == 3){
          activeStep = 1;
        }
        _controller.animateToPage(
            activeStep,
            duration: _kDuration,
            curve: _kCurve
        );
        setState(() {});
      },
      showBackbutton: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 80,
            child: EasyStepper(
                activeStep: activeStep,
                lineStyle:  LineStyle(
                  lineLength: 150,
                  lineSpace: 0,
                  lineType: LineType.normal,
                  defaultLineColor: Color(0xFF002651),
                  finishedLineColor: Colors.green,
                  lineThickness: 1.5,
                ),
                enableStepTapping: true,
                activeStepTextColor: Color(0xFF002651),
                finishedStepTextColor: Color(0xFF002651),
                internalPadding: 0,
                showLoadingAnimation: false,
                stepRadius: 15,
                showStepBorder: false,
                steps: [
                  EasyStep(
                      enabled: childs[0] != 0,
                      customStep: CircleAvatar(
                        radius: 25,
                        backgroundColor: childs[0] != 0 ? childs[0]==1?Theme.of(context).colorScheme.primary:Colors.green : Color(0xFF002651),
                        child: childs[0] == 2?Icon(CupertinoIcons.check_mark):SizedBox(),
                      ),

                      topTitle: false,
                      title: AppTranslations.of(context)!.text("key_basicinfo"),
                      customTitle:  SizedBox(
                        width: double.infinity,
                        child: Text(AppTranslations.of(context)!.text("key_basicinfo"), textAlign: TextAlign.center),
                      )
                  ),
                  EasyStep(
                      enabled: childs[1] != 0,
                      customStep: CircleAvatar(
                        radius: 25,
                        child: childs[1] == 2?Icon(CupertinoIcons.check_mark):SizedBox(),
                        backgroundColor: childs[1] != 0 ? childs[1]==1?Theme.of(context).colorScheme.primary:Colors.green : Color(0xFF002651),
                      ),
                      topTitle: false,
                      title: AppTranslations.of(context)!.text("key_question"),
                      customTitle:  SizedBox(
                        width: double.infinity,
                        child: Text(AppTranslations.of(context)!.text("key_question"), textAlign: TextAlign.center),
                      )
                  ),
                  EasyStep(
                      enabled: childs[2] != 0,
                      customStep: CircleAvatar(
                        radius: 25,
                        child: childs[2] == 2?Icon(CupertinoIcons.check_mark):SizedBox(),
                        backgroundColor: childs[2] != 0 ? childs[2]==1?Theme.of(context).colorScheme.primary:Colors.green : Color(0xFF002651),
                      ),
                      topTitle: false,
                      title: AppTranslations.of(context)!.text("key_acknowledgment"),
                      customTitle:  SizedBox(
                        width: double.infinity,
                        child: Text(AppTranslations.of(context)!.text("key_acknowledgment"), textAlign: TextAlign.center),
                      )
                  )
                ],
                onStepReached: (index) {
                  // if(index <= 1){
                  //
                  // }
                  if(questionArray[pageStep]["answer"].toString().trim().isNotEmpty){
                    if(questionArray[pageStep]["submitAns"].toString().trim().isEmpty){
                      setState(() {});
                      APIService(context).showWindowAlert(title: "",desc: AppTranslations.of(context)!.text("key_message_24"),callback: (){
                        saveAnswerQuestion(onCallback: (id){
                          if(index == 2){
                            activeStep = 3;
                          }else{
                            activeStep = index;
                          }
                          gotoPage();
                          if(activeStep == 0){
                            if(auditObj["branch"].length != 0){
                              Future.delayed(Duration(milliseconds: 400))
                                  .then((value){
                                String date = auditObj["branch"][0]["joining_date"].toString();
                                auditObj["branch"][0]["joining_date"] = Jiffy.parse(date).dateTime;
                                formKey.currentState!.patchValue(auditObj["branch"][0]);
                              });
                            }
                          }else if(activeStep == 2){
                            Future.delayed(Duration(milliseconds: 400))
                                .then((value){
                              formKey02.currentState!.patchValue({
                                "name":usercontroller.userData.name,
                                "email":usercontroller.userData.email,
                                "mobileno":usercontroller.userData.mobile,
                              });
                            });
                          }

                          setState(() {});
                        });
                      },showCancelBtn: true,okbutton:AppTranslations.of(context)!.text("key_btn_save") );
                      return;
                    }
                  }
                  if(index == 2){
                    activeStep = 3;
                  }else{
                    activeStep = index;
                  }
                  gotoPage();
                  if(activeStep == 0){
                    if(auditObj["branch"].length != 0){
                      Future.delayed(Duration(milliseconds: 400))
                          .then((value){
                        String date = auditObj["branch"][0]["joining_date"].toString();
                        auditObj["branch"][0]["joining_date"] = Jiffy.parse(date).dateTime;
                        formKey.currentState!.patchValue(auditObj["branch"][0]);
                      });
                    }
                  }else if(activeStep == 2){
                    Future.delayed(Duration(milliseconds: 400))
                        .then((value){
                      formKey02.currentState!.patchValue({
                        "name":usercontroller.userData.name,
                        "email":usercontroller.userData.email,
                        "mobileno":usercontroller.userData.mobile,
                      });
                    });
                  }

                  setState(() {});
                }
            ),
          ),
          Expanded(
              flex: 12,
              child:  getChildNew()
          ),
        ],
      ),
    );
  }
}
