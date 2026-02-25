import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
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
import 'package:jiffy/jiffy.dart';
import '../../constants.dart';
import '../../controllers/usercontroller.dart';
import '../../theme/themes.dart';
import '../main/layoutscreen.dart';
import 'dart:js' as js;

/// V2.0 Audit Execution Screen
/// 4-step stepper: Branch Details → Audit Activity → Submit Review → Published
class AuditCategoryScreenV2 extends StatefulWidget {
  const AuditCategoryScreenV2({super.key});

  @override
  State<AuditCategoryScreenV2> createState() => _AuditCategoryScreenV2State();
}

class _AuditCategoryScreenV2State extends State<AuditCategoryScreenV2> {
  GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  double wdt = 950;
  ScreenArgument? pageargument;
  UserController usercontroller = Get.put(UserController());

  final _controller = PageController(keepPage: false);
  final _questioncontroller = PageController(keepPage: false);

  int answerQuest = 0;
  bool enableAction = true;
  bool showNextBtn = true;
  bool showQuestion = false;
  bool showAudit = false;
  bool showImage = false;
  bool acknowlodgeImage = false;
  bool reviewAcknowledged = false;
  bool publishReviewed = false;

  /// Step states: 0=disabled, 1=active, 2=completed
  List<int> childs = [1, 0, 0, 0];
  static const _kCurve = Curves.ease;
  static const _kDuration = Duration(milliseconds: 300);

  dynamic auditObj = {};
  dynamic categoryObj = {};
  List<dynamic> questionArray = [];
  Color selectedColor = Colors.transparent;

  int activeStep = 0;
  int pageStep = 0;
  int totalpage = 0;

  Uint8List? _imageBytes;
  String? _imageName;
  List<Uint8List>? _imageBytesList;
  List<String>? _imageNameList;
  int countFile = 0;
  int totalFile = 0;
  String totalMark = "0";
  String answerMark = "0";
  String totalPer = "0";
  List<String> extension = [
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
    ".pdf", ".png", ".jpeg", ".jpg"
  ];

  // Published step
  List<dynamic> clientUsers = [];
  String? selectedClientEmail;

  Future<void> processAuditCategories() async {
    int ansValue = 0;
    int totalValue = 0;
    await Future.forEach(auditObj["categorys"], (ele) async {
      dynamic element = ele;
      List<dynamic> attendQuestion = element["questions"]
          .where((quest) =>
              quest["answer"].toString().trim().toString().isNotEmpty)
          .toList();
      attendQuestion.forEach((ele) {
        if (ele["answer"] != "N/A") {
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
    int? percentage = ((v1! / v2!) * 100).round();
    totalPer = percentage.toString();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200)).then((onValue) {
      if (usercontroller.userData.role == null) {
        usercontroller.loadInitData();
        usercontroller.selectedIndex = 1;
        Navigator.pushNamed(context, "/auditlist",
            arguments:
                ScreenArgument(argument: ArgumentData.USER, mapData: {}));
      }
      pageargument =
          ModalRoute.of(context)?.settings.arguments as ScreenArgument;
      dynamic mapData = pageargument?.mapData ?? {};
      String auditId = (mapData["id"] ?? mapData["audit_id"] ?? "").toString();
      
      // If audit status is "S" (Scheduled/Upcoming), start it first
      String status = (mapData["status"] ?? "").toString();
      if (status == "S") {
        usercontroller.startAudit(context, data: {"audit_id": auditId}, callback: (success) {
          _loadAuditData(auditId);
        });
      } else {
        _loadAuditData(auditId);
      }
    });
  }

  void _loadAuditData(String auditId) {
      Map<String, dynamic> data = {"id": auditId};
      usercontroller.getAuditQuestion(context, data: data, callback: (res) {
        auditObj = res;
        showAudit = true;
        int ansValue = 0;
        int totalValue = 0;

        auditObj["categorys"].forEach((element) {
          element["submitAns"] = element["answer"].toString().trim().isNotEmpty
              ? element["answer"].toString().trim()
              : "";
          element["questions"].forEach((eleObj) {
            eleObj["submitAns"] = eleObj["answer"].toString().trim().isNotEmpty
                ? eleObj["answer"].toString().trim()
                : "";
          });

          List<dynamic> attendQuestion = element["questions"]
              .where((quest) =>
                  quest["answer"].toString().trim().toString().isNotEmpty)
              .toList();
          attendQuestion.forEach((ele) {
            if (ele["answer"] != "N/A") {
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
        if (v2 != 0) {
          int? percentage = ((v1! / v2!) * 100).round();
          totalPer = percentage.toString();
        }

        Future.delayed(Duration(milliseconds: 400)).then((eleobj) {
          if (activeStep == 0) {
            if (auditObj["branch"].length != 0) {
              String date =
                  auditObj["branch"][0]["joining_date"].toString();
              auditObj["branch"][0]["joining_date"] =
                  Jiffy.parse(date).dateTime;
              formKey.currentState!.patchValue(auditObj["branch"][0]);
            }
          }
        });
        setState(() {});
      });
  }

  setCategoryStatus(dynamic element) {
    element["complete"] = false;
    if (element["total"].toString().trim().isNotEmpty) {
      List<dynamic> arr = element["questions"]
          .where(
              (eleobj) => eleobj["answer"].toString().trim().isNotEmpty)
          .toList();
      if (arr.length == element["questions"].length) {
        element["complete"] = true;
      }
      setState(() {});
    }
  }

  gotoPage() {
    _controller.animateToPage(activeStep,
        duration: _kDuration, curve: _kCurve);
    setState(() {});
  }

  void fileUploadProcess(question) {
    Map<String, dynamic> dataObj = {
      "type": "audit",
      "audit_id": question["audit_id"],
      "questionid": question["questionid"]
    };
    usercontroller.uploadImage(context,
        bytes: _imageBytesList![countFile],
        filename: _imageNameList![countFile],
        data: dataObj, callback: (res01) {
      if (res01.containsKey("data")) {
        question["proofdocuments"].add(res01["data"]);
      }
      setState(() {});
      if (countFile < totalFile - 1) {
        countFile++;
        fileUploadProcess(question);
      }
    });
  }

  void saveAnswerQuestion({required Function(int) onCallback}) {
    Map<String, dynamic> data = {
      "audit_id": questionArray[pageStep]["audit_id"],
      "category_id": questionArray[pageStep]["category_id"],
      "questionid": questionArray[pageStep]["questionid"],
      "reviews": questionArray[pageStep]["reviews"],
      "clientremarks": questionArray[pageStep]["clientremarks"],
      "answer": questionArray[pageStep]["answer"],
      "cateanswer": categoryObj["answer"],
      "catetotal": categoryObj["total"],
      "selecteddropdown": questionArray[pageStep]["selecteddropdown"]
    };
    usercontroller.saveAuditQuestion(context, data: data, callback: () async {
      questionArray[pageStep]["submitAns"] =
          questionArray[pageStep]["answer"].toString().trim();
      enableAction = true;
      List<dynamic> qarray = questionArray
          .where((eleobj) =>
              eleobj["answer"].toString().trim().isNotEmpty &&
              !eleobj["answer"].toString().trim().contains("N/A"))
          .toList();
      num total = 0;
      num ans = 0;
      qarray.forEach((eleobj) {
        ans = ans + (num.tryParse(eleobj["answer"].toString()) ?? 0);
        total = total + 4;
      });
      categoryObj["answer"] = ans.toString();
      categoryObj["total"] = total.toString();
      await processAuditCategories();
      List ansList = questionArray
          .where((ele) => ele["submitAns"].toString().trim().isNotEmpty)
          .toList();
      answerQuest = ansList.length;
      if (ansList.length == questionArray.length) {
        showNextBtn = false;
        setState(() {});
        setCategoryStatus(categoryObj);
        List<dynamic> catearr = auditObj["categorys"]
            .where((obj) => obj["complete"] == true)
            .toList();
        String categoryname = categoryObj["categoryname"];
        Widget child = Container(
          height: 80,
          child: Column(
            children: [
              Text(categoryname, style: headingTextStyle),
              SizedBox(height: 30),
              Text(
                  AppTranslations.of(context)!.text("key_message_13"),
                  style: paragraphTextStyle),
            ],
          ),
        );
        if (auditObj["categorys"].length == catearr.length) {
          childs[0] = 2;
          childs[1] = 2;
          APIService(context).showWindowAlert(
              title: "",
              desc: "",
              child: child,
              callback: () {
                activeStep = 1;
                gotoPage();
                setState(() {});
              });
          setState(() {});
        } else {
          APIService(context).showWindowAlert(
              title: "",
              desc: "",
              child: child,
              callback: () {
                activeStep = 1;
                gotoPage();
                setState(() {});
              });
        }
      } else {
        onCallback(1);
      }
      setState(() {});
    });
  }

  // =====================================================
  //  STEP 0: Branch Details
  // =====================================================

  /// Builds a labeled field: label text above, then the child widget.
  Widget _labeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Plain field decoration (no floating label) matching the screenshot.
  InputDecoration _plainFieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: "",
      errorMaxLines: 3,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0)),
      suffixIcon: suffixIcon,
    );
  }

  Widget branchDetailsChild() {
    return Container(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: BoxContainer(
          width: double.infinity,
          height: null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: FormBuilder(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text("Branch Details",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87)),
                  SizedBox(height: 24),
                  // Row 1: Manager Name, ID Card Number, Joining Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _labeledField(
                          AppTranslations.of(context)!.text("key_branch"),
                          FormBuilderTextField(
                            name: "managername",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_01"))
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _plainFieldDecoration(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _labeledField(
                          AppTranslations.of(context)!.text("key_idcard"),
                          FormBuilderTextField(
                            name: "idcardno",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_01"))
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _plainFieldDecoration(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _labeledField(
                          AppTranslations.of(context)!.text("key_joiningdate"),
                          FormBuilderDateTimePicker(
                            name: "joining_date",
                            initialDate: Jiffy.now().dateTime,
                            firstDate:
                                Jiffy.now().subtract(years: 40).dateTime,
                            lastDate: Jiffy.now().dateTime,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_01"))
                            ]),
                            timePickerInitialEntryMode:
                                TimePickerEntryMode.dialOnly,
                            style: Theme.of(context).textTheme.bodyMedium,
                            inputType: InputType.date,
                            decoration: _plainFieldDecoration(
                                suffixIcon: Icon(
                                    CupertinoIcons.calendar_badge_plus,
                                    size: 20.0,
                                    color: Colors.grey.shade600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Row 2: Phone Number, Email ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _labeledField(
                          AppTranslations.of(context)!.text("key_phoneno"),
                          FormBuilderTextField(
                            name: "phoneno",
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: false),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_01")),
                              FormBuilderValidators.minLength(10,
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_03")),
                              FormBuilderValidators.maxLength(10,
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_03"))
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _plainFieldDecoration(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _labeledField(
                          AppTranslations.of(context)!.text("key_username"),
                          FormBuilderTextField(
                            name: "emailid",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_01")),
                              FormBuilderValidators.email(
                                  errorText: AppTranslations.of(context)!
                                      .text("key_error_02"))
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _plainFieldDecoration(),
                          ),
                        ),
                      ),
                      // Spacer to keep 2 fields aligned with first 2 columns
                      Expanded(child: SizedBox()),
                    ],
                  ),
                  SizedBox(height: 32),
                  // Continue to Audit button — centered
                  Center(
                    child: ButtonComp(
                      width: 250,
                      label: "Continue to Audit",
                      onPressed: () {
                        if (formKey.currentState!.saveAndValidate()) {
                          Map<String, dynamic> obj =
                              Map.of(formKey.currentState!.value);
                          obj["joining_date"] =
                              Jiffy.parseFromDateTime(obj["joining_date"])
                                  .dateTime
                                  .toIso8601String();
                          obj["audit_id"] = auditObj["id"];
                          usercontroller.saveAuditBranch(context, data: obj,
                              callback: () {
                            childs[0] = 2;
                            childs[1] = 1;
                            activeStep = 1;
                            setState(() {});
                            gotoPage();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  //  STEP 1: Audit Activity (category cards + rating table)
  // =====================================================
  Widget auditActivityChild() {
    if (!showAudit) return SizedBox();
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rating summary table
          BoxContainer(
            width: 580,
            height: 90,
            padding: 5,
            child: DataTableTheme(
              data: DataTableThemeData(
                  dataRowHeight: 30,
                  horizontalMargin: 8,
                  headingRowAlignment: MainAxisAlignment.spaceBetween,
                  headingRowHeight: 30),
              child: DataTable2(
                headingRowHeight: 35,
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                columns: [
                  DataColumn(
                      label: Center(
                          child: Text(
                              AppTranslations.of(context)!
                                  .text("key_message_15"),
                              style: TextStyle(fontSize:14,fontWeight: FontWeight.w600,color: Color(0xFF505050))))),
                  DataColumn(
                      label: Center(
                          child: Text(
                              AppTranslations.of(context)!
                                  .text("key_message_14"),
                              style: TextStyle(fontSize:14,fontWeight: FontWeight.w600,color: Color(0xFF505050))))),
                  DataColumn(
                      label: Center(
                          child: Text(
                              AppTranslations.of(context)!
                                  .text("key_message_16"),
                              style: TextStyle(fontSize:14,fontWeight: FontWeight.w600,color: Color(0xFF505050))))),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Container(
                        child: Center(
                            child: Text(answerMark,
                  style: TextStyle(fontSize:14,fontWeight: FontWeight.w600,color: Color(0xFF505050)))))),
                    DataCell(Container(
                        child: Center(
                            child: Text(totalMark,
                                style: TextStyle(fontSize:14,fontWeight: FontWeight.w600,color: Color(0xFF505050)))))),
                    DataCell(
                        Container(
                        child: Center(
                            child: SizedBox(
                                width: 50,
                                child: StatusComp(
                                  status: "",
                                  statusvalue: totalPer + "%",
                                  percentage:
                                      int.tryParse(totalPer),
                                ))))),
                  ])
                ],
              ),
            ),
          ),
          SizedBox(height: defaultPadding),
          // Section title
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("Audit Activity",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87)),
            ),
          ),
          SizedBox(height: 24),
          // Category cards grid
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 40,
            runSpacing: 40,
            children: auditObj["categorys"]
                .map<Widget>((element) => _buildCategoryCard(element))
                .toList(),
          ),
          SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(dynamic element) {
    String totalQuestion = element["questions"].length.toString();
    List<dynamic> attendQuestion = element["questions"]
        .where((quest) =>
            quest["answer"].toString().trim().toString().isNotEmpty)
        .toList();
    int ansValue = 0;
    int totalValue = 0;
    attendQuestion.forEach((ele) {
      if (ele["answer"] != "N/A") {
        String str = (ele["answer"] ?? "0");
        int d = int.tryParse(str) ?? 0;
        ansValue = ansValue + d;
        totalValue = totalValue + 4;
      }
    });
    element["answer"] = ansValue.toString();
    element["total"] = totalValue.toString();

    num score = element["answer"].toString().isEmpty
        ? 0
        : (num.tryParse(element["answer"].toString()) ?? 0);
    num total = (num.tryParse(element["total"].toString()) ?? 0);
    String value = "";
    if (score != 0 && total != 0) {
      int avarge = ((score / total) * 100).round();
      value = avarge.toString();
    }
    String answeredQuestion =
        attendQuestion.length == 0 ? "0" : attendQuestion.length.toString();

    // Determine button status
    String btnLabel =
        AppTranslations.of(context)!.text("key_start");
    Color btnColor = Color(0xFF535353);
    // Calculate average rating per answered question
    String ratingStr = "";
    if (attendQuestion.length > 0) {
      int ratingVal = (ansValue / attendQuestion.length).round();
      ratingStr = ratingVal.toString();
    }

    if (answeredQuestion == totalQuestion &&
        answeredQuestion != "0") {
      btnLabel = "Completed";
      btnColor = Color(0xFF67AC5B);
    } else if (int.parse(answeredQuestion) > 0) {
      btnLabel = "Pending";
      btnColor = Color(0xFFF29500);
    }

    return BoxContainer(
      padding: 20,
      width: 340,
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category heading label
            Text(element["heading"] ?? "",
                style: TextStyle(
                    color: Color(0xFF898989),
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),
            SizedBox(height: 4),
            // Category name
            Container(
              height: 45,
              child: Text(element["categoryname"],
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF505050)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 8),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.of(context)!.text("key_average"),
                        style: TextStyle(color: Color(0xFF898989), fontSize: 12)),
                    Row(
                      children: [
                        Text(": ",
                            style: TextStyle(fontSize: 12)),
                        Text("50%",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("%Secured",
                        style: TextStyle(color: Color(0xFF898989), fontSize: 12)),
                    Row(
                      children: [
                        Text(": ",
                            style: TextStyle(fontSize: 12)),
                        value.toString().trim().isEmpty
                            ? Text("",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12))
                            : SizedBox(
                                width: 50,
                                child: StatusComp(
                                  status: "",
                                  statusvalue: value + "%",
                                  percentage: int.tryParse(value),
                                )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.of(context)!.text("key_question"),
                        style: TextStyle(color: Color(0xFF898989), fontSize: 12)),
                    Text(": $answeredQuestion/$totalQuestion",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rating",
                        style: TextStyle(color: Color(0xFF898989), fontSize: 12)),
                    Text(
                        ": $ratingStr",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Action button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _openCategory(element, answeredQuestion, totalQuestion);
                },
                child: Text(btnLabel,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(
      dynamic element, String answeredQuestion, String totalQuestion) {
    categoryObj = element;
    questionArray = [];
    questionArray = element["questions"];
    for (var mid = 0; mid < questionArray.length; mid++) {
      questionArray[mid]["index"] = mid;
      questionArray[mid]["isSaved"] =
          questionArray[mid]["submitAns"].toString().trim().isNotEmpty
              ? true
              : false;
    }
    pageStep = 0;
    int d = questionArray
        .indexWhere((element) => element["answer"].toString().trim().isNotEmpty);
    if (d != -1) {
      pageStep = d + 1;
    }
    if (pageStep >= questionArray.length - 1) {
      pageStep = 0;
    }
    if (answeredQuestion == totalQuestion) {
      pageStep = 0;
    }
    totalpage = questionArray.length;
    childs[1] = 2;
    // We reuse step 1 page but enter question mode
    showQuestion = true;
    if (questionArray[pageStep]["answer"].toString().trim().isEmpty) {
      selectedColor = Colors.transparent;
    } else {
      List<dynamic> arr = usercontroller.scoreArr
          .where((e) =>
              e["value"] ==
              questionArray[pageStep]["submitAns"].toString().trim())
          .toList();
      if (arr.length != 0) {
        selectedColor = arr[0]["color"];
      }
    }
    showNextBtn = true;
    List<dynamic> attendQuestion2 = categoryObj["questions"]
        .where(
            (quest) => quest["answer"].toString().trim().toString().isNotEmpty)
        .toList();
    answerQuest = attendQuestion2.length;
    setState(() {});
    Future.delayed(Duration(milliseconds: 20)).then((v) {
      _questioncontroller.animateToPage(pageStep,
          duration: _kDuration, curve: _kCurve);
    });
  }

  // =====================================================
  //  Question View (shown within Audit Activity step)
  // =====================================================
  Widget questionChild() {
    int id = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row — fixed, not scrollable
        SizedBox(
          width: wdt + 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(categoryObj["categoryname"] ?? "",
                      style: TextStyle(
                          color: Color(0xFF505050),
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                      "$answerQuest/${questionArray.length}",
                      style: TextStyle(
                          color: Color(0xFF505050),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        // Question pageview with side index
        Expanded(
          child: SizedBox(
            width: wdt + 40,
            child: questionArray.length != 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 10,
                        child: PageView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: questionArray.length,
                          controller: _questioncontroller,
                          itemBuilder: (context, index) {
                            return _questionComp(questionArray[index]);
                          },
                        ),
                      ),
                      // Side index buttons
                      SizedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: questionArray.map((element) {
                            id++;
                            return InkWell(
                              onTap: () {
                                _handleQuestionIndexTap(element);
                              },
                              child: Container(
                                width: pageStep == element["index"] ? 30 : 20,
                                height: 30,
                                margin: EdgeInsets.only(top: 4, bottom: 4),
                                decoration: BoxDecoration(
                                  color: _getQuestionColor(element, id),
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8)),
                                ),
                                child: Center(
                                  child: Text(id.toString(),
                                      style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w600)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  )
                : Container(),
          ),
        ),
        SizedBox(height: defaultPadding),
        // Previous/Next buttons
        Center(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonComp(
                    width: 120,
                    label: "Previous",
                    color: Color(0xFF555555),
                    onPressed: () {
                      if (pageStep > 0) {
                        if (questionArray[pageStep]["answer"]
                            .toString()
                            .trim()
                            .isNotEmpty) {
                          if (questionArray[pageStep]["submitAns"]
                              .toString()
                              .trim()
                              .isEmpty) {
                            APIService(context).showWindowAlert(
                                title: "",
                                desc: AppTranslations.of(context)!
                                    .text("key_message_24"),
                                callback: () {
                                  saveAnswerQuestion(
                                      onCallback: (id) {
                                    _navigateToQuestion(pageStep - 1);
                                  });
                                },
                                showCancelBtn: true,
                                okbutton: AppTranslations.of(context)!
                                    .text("key_btn_save"));
                            return;
                          }
                        }
                        _navigateToQuestion(pageStep - 1);
                      }
                    },
                  ),
                  SizedBox(width: 20),
                  Visibility(
                    visible: showNextBtn,
                    child: ButtonComp(
                      width: 120,
                      label: AppTranslations.of(context)!
                          .text("key_btn_next"),
                      onPressed: () async {
                        if (questionArray[pageStep]["submitAns"]
                            .toString()
                            .trim()
                            .isEmpty) {
                          APIService(context).showWindowAlert(
                              title: "",
                              desc: AppTranslations.of(context)!
                                  .text("key_message_24"),
                              callback: () {
                                saveAnswerQuestion(
                                    onCallback: (id) async {
                                  if (pageStep <
                                      questionArray.length - 1) {
                                    _navigateToQuestion(pageStep + 1);
                                  }
                                });
                              },
                              showCancelBtn: true,
                              okbutton: AppTranslations.of(context)!
                                  .text("key_btn_save"));
                          return;
                        }
                        if (pageStep < questionArray.length - 1) {
                          _navigateToQuestion(pageStep + 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: defaultPadding),
        ],
      );
  }

  void _navigateToQuestion(int index) {
    pageStep = index;
    if (questionArray[pageStep]["answer"].toString().trim().isEmpty) {
      selectedColor = Colors.transparent;
    } else {
      List<dynamic> arr = usercontroller.scoreArr
          .where((e) =>
              e["value"] ==
              questionArray[pageStep]["answer"].toString().trim())
          .toList();
      if (arr.length != 0) {
        selectedColor = arr[0]["color"];
      }
    }
    _questioncontroller.animateToPage(pageStep,
        duration: _kDuration, curve: _kCurve);
    setState(() {});
  }

  void _handleQuestionIndexTap(dynamic element) {
    if (questionArray[pageStep]["answer"].toString().trim().isNotEmpty) {
      if (questionArray[pageStep]["submitAns"]
          .toString()
          .trim()
          .isEmpty) {
        APIService(context).showWindowAlert(
            title: "",
            desc: AppTranslations.of(context)!
                .text("key_message_24"),
            callback: () {
              saveAnswerQuestion(onCallback: (id) {
                _navigateToQuestion(element["index"]);
              });
            },
            showCancelBtn: true,
            okbutton: AppTranslations.of(context)!
                .text("key_btn_save"));
        return;
      }
    }
    _navigateToQuestion(element["index"]);
  }

  Color _getQuestionColor(element, index) {
    Color c = Color(0xFF535353);
    if (element["answer"].toString().trim().isEmpty) {
      if (pageStep == index - 1) c = Color(0xFF2E77D0);
    } else {
      c = Color(0xFFA4DD5A);
      if (pageStep == index - 1) c = Color(0xFF2E77D0);
    }
    return c;
  }

  Widget _questionComp(dynamic question) {
    return BoxContainer(
      width: wdt - 50,
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Question container
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(question["question"],
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16,color: Color(0xFF505050))),
                  SizedBox(height: 20),
                  // Score circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: question["answer"]
                                .toString()
                                .trim()
                                .isEmpty
                            ? Colors.white
                            : selectedColor,
                        borderRadius:
                            BorderRadius.all(Radius.circular(25)),
                        border: Border.all(
                            color: Colors.grey.shade400, width: 1.0)),
                    child: Center(
                      child: Text(question["answer"],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(AppTranslations.of(context)!
                      .text("key_score"),style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Color(0xFF505050)),),
                  SizedBox(height: 10),
                  // Score buttons row
                  Wrap(
                    children: usercontroller.scoreArr
                        .map((element) => Container(
                              width: 80,
                              height: 50,
                              margin: EdgeInsets.only(top: 7, bottom: 7),
                              color: element["color"],
                              child: InkWell(
                                onTap: () {
                                  question["answer"] = element["value"];
                                  selectedColor = element["color"];
                                  enableAction = false;
                                  setState(() {});
                                },
                                child: Center(
                                  child: Text(element["value"].toString(),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Dropdowns row
            Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  question["dropdown"].map<Widget>((element2) {
                return Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _labeledField(
                      element2["dropdownname"],
                      FormBuilderDropdown<dynamic>(
                        name: "zone_${element2["dropdownid"]}",
                        initialValue: element2["selectedoption"],
                        items: element2["options"]
                            .map<DropdownMenuItem<dynamic>>(
                                (toElement) => DropdownMenuItem(
                                      value: toElement["optionvalue"],
                                      child: Text(
                                          toElement["optionvalue"]),
                                    ))
                            .toList(),
                        onChanged: (value) {
                          List<dynamic> arr = question["selecteddropdown"]
                              .where((item) =>
                                  item["dropdownid"] ==
                                  element2["dropdownid"])
                              .toList();
                          if (arr.length == 0) {
                            question["selecteddropdown"].add({
                              "dropdownid": element2["dropdownid"],
                              "dropdownname": element2["dropdownname"],
                              "selectedoption": value
                            });
                          } else {
                            arr[0]["selectedoption"] = value;
                          }
                        },
                        decoration: _plainFieldDecoration(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            // Review text
            _labeledField(
              AppTranslations.of(context)!.text("key_review"),
              FormBuilderTextField(
                name: "reviews",
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                initialValue: question["reviews"],
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  question["reviews"] = value;
                  setState(() {});
                },
                decoration: _plainFieldDecoration(),
              ),
            ),
            SizedBox(height: 16),
            // Client remarks
            _labeledField(
              AppTranslations.of(context)!.text("key_customer_review"),
              FormBuilderTextField(
                name: "clientremarks",
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                initialValue: question["clientremarks"],
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  question["clientremarks"] = value;
                  setState(() {});
                },
                decoration: _plainFieldDecoration(),
              ),
            ),
            SizedBox(height: 20),
            // File attachments
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: SizedBox(
                    width: 150,
                    height: buttonHeight,
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          if (question["proofdocuments"].length == 10) {
                            APIService(context).showToastMgs(
                                AppTranslations.of(context)!
                                    .text("key_error_04"));
                            return;
                          }
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: true,
                          );
                          _imageBytesList = [];
                          _imageNameList = [];
                          countFile = 0;
                          setState(() {});
                          if (result != null && result.files.isNotEmpty) {
                            totalFile = result.files.length;
                            for (var kid = 0;
                                kid < result.files.length;
                                kid++) {
                              var file = result.files[kid];
                              var index = file.name.lastIndexOf(".");
                              var ext = file.name
                                  .substring(index, file.name.length);
                              if (extension.indexOf(ext) == -1) {
                                APIService(context).showWindowAlert(
                                    title: "",
                                    desc: AppTranslations.of(context)!
                                        .text("key_message_28"),
                                    callback: () {});
                                return;
                              }
                              _imageBytesList!.add(file.bytes!);
                              _imageNameList!.add(file.name);
                            }
                            setState(() {});
                            fileUploadProcess(question);
                          }
                        },
                        icon: Icon(Icons.cloud_upload,
                            size: 20, color: Colors.white),
                        label: Text(
                            AppTranslations.of(context)!
                                .text("key_btn_upload"),
                            style: TextStyle(color: Colors.white))),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: question["proofdocuments"]
                        .map<Widget>((imgelement) {
                      bool image = true;
                      String name = imgelement["image"].toString();
                      var index = name.lastIndexOf(".");
                      var ext = name.substring(index, name.length);
                      String img = "assets/images/doc.png";
                      if (ext.contains("doc")) {
                        image = false;
                        img = "assets/images/doc.png";
                      } else if (ext.contains("xls")) {
                        image = false;
                        img = "assets/images/xls.png";
                      } else if (ext.contains("pdf")) {
                        image = false;
                        img = "assets/images/pdf.png";
                      } else if (ext.contains("ppt")) {
                        image = false;
                        img = "assets/images/ppt.png";
                      }
                      return Container(
                        width: 90,
                        height: 90,
                        margin: EdgeInsets.only(left: 5, right: 5),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () {
                                  js.context.callMethod('open', [
                                    IMG_URL +
                                        imgelement["image"].toString(),
                                    "_blank"
                                  ]);
                                },
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: image
                                              ? NetworkImage(IMG_URL +
                                                  imgelement["image"])
                                              : AssetImage(img)),
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () {
                                  APIService(context).showWindowAlert(
                                      title: "",
                                      desc: AppTranslations.of(context)!
                                          .text("key_are_you"),
                                      showCancelBtn: true,
                                      callback: () {
                                        Map<String, dynamic> obj = {
                                          "id": imgelement["id"],
                                          "audit_id":
                                              imgelement["audit_id"],
                                          "question_id":
                                              imgelement["question_id"]
                                        };
                                        usercontroller.removeUploadFile(
                                            context,
                                            data: obj,
                                            callback: (arr) {
                                          question["proofdocuments"] = arr;
                                          setState(() {});
                                        });
                                      });
                                },
                                child: SvgPicture.asset(
                                  "assets/icons/close.svg",
                                  colorFilter: ColorFilter.mode(
                                      Colors.blue.shade900,
                                      BlendMode.srcIn),
                                  height: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  //  STEP 2: Submit Review
  // =====================================================
  Widget submitReviewChild() {
    String companyName = auditObj["companyname"] ?? "";
    String auditId = auditObj["audit_no"] ?? "";
    String auditDate = "";
    String auditTime = "";
    String assignedBy = "";
    String auditorName = "";
    String reviewSubmitted = "";

    try {
      auditDate = Jiffy.parse(auditObj["start_date"])
          .format(pattern: "dd/MM/yyyy");
    } catch (_) {}
    try {
      auditTime = Jiffy.parse(auditObj["start_time"])
          .format(pattern: "hh:mm a");
    } catch (_) {}
    assignedBy = auditObj["assigned_by"] ?? auditObj["auditorname"] ?? "";
    auditorName = usercontroller.userData.name ?? "";
    reviewSubmitted = Jiffy.now().format(pattern: "dd/MM/yyyy");

    return SingleChildScrollView(
      child: Center(
        child: BoxContainer(
          width: wdt,
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Submit Review",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87)),
              SizedBox(height: defaultPadding),
              // Company name
              Center(
                child: Text(companyName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
              ),
              SizedBox(height: defaultPadding),
              // Info rows
              _infoRow("Audit ID", auditId, "Audit Date", auditDate),
              SizedBox(height: defaultPadding),
              _infoRow(
                  "Audit assigned by", assignedBy, "Audit time", auditTime),
              SizedBox(height: defaultPadding),
              _infoRow(
                  "Auditor", auditorName, "Review Submitted", reviewSubmitted),
              SizedBox(height: defaultPadding * 2),
              // Acknowledgment checkbox
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: reviewAcknowledged,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            reviewAcknowledged = val ?? false;
                            setState(() {});
                          },
                        ),
                        Expanded(
                          child: Text(
                            "I acknowledge the audit's conclusion, with all activities performed as per established protocol.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text("Proof of location is included.",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                    SizedBox(height: 10),
                    // Proof image upload
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                  withData: true,
                                );
                                if (result != null &&
                                    result.files.isNotEmpty) {
                                  setState(() {
                                    showImage = false;
                                    acknowlodgeImage = true;
                                    _imageBytes = result.files.first.bytes;
                                    _imageName = result.files.first.name;
                                  });
                                }
                              },
                              icon: Icon(Icons.cloud_upload,
                                  size: 20, color: Colors.white),
                              label: Text("Browse",
                                  style: TextStyle(color: Colors.white))),
                        ),
                        SizedBox(width: 10),
                        if (acknowlodgeImage && _imageBytes != null)
                          Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_imageBytes!,
                                  fit: BoxFit.cover),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: defaultPadding * 2),
              // Submit button
              Center(
                child: ButtonComp(
                  width: 250,
                  label: "Submit to Review",
                  onPressed: () {
                    if (!reviewAcknowledged) {
                      APIService(context).showWindowAlert(
                          title: "",
                          desc:
                              "Please acknowledge the audit conclusion before submitting.",
                          callback: () {});
                      return;
                    }
                    if (!acknowlodgeImage) {
                      APIService(context).showWindowAlert(
                          title: "",
                          desc: AppTranslations.of(context)!
                              .text("key_error_06"),
                          callback: () {});
                      return;
                    }
                    Map<String, dynamic> obj = {};
                    obj["user_id"] = usercontroller.userData.userId;
                    obj["role"] = usercontroller.userData.role;
                    obj["audit_id"] = auditObj["id"];
                    obj["name"] = usercontroller.userData.name;
                    obj["email"] = usercontroller.userData.email;
                    obj["mobileno"] = usercontroller.userData.mobile;
                    usercontroller.saveAuditAcknowledge(context, data: obj,
                        callback: () {
                      Map<String, dynamic> dataObj = {
                        "type": "acknowledge",
                        "audit_id": auditObj["id"],
                        "user_id": usercontroller.userData.userId
                      };
                      usercontroller.uploadImage(context,
                          bytes: _imageBytes,
                          filename: _imageName ?? "",
                          data: dataObj, callback: (res01) {
                        childs[2] = 2;
                        childs[3] = 1;
                        activeStep = 3;
                        // Load client users for publish step
                        _loadClientUsers();
                        setState(() {});
                        gotoPage();
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
      String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
              SizedBox(height: 4),
              Text(value1,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
              SizedBox(height: 4),
              Text(value2,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  //  STEP 3: Published
  // =====================================================
  void _loadClientUsers() {
    if (auditObj["client_id"] != null) {
      Map<String, dynamic> dataobj = {"client_id": auditObj["client_id"]};
      usercontroller.getClientUserList(context, data: dataobj,
          errorcallback: (res) {},
          callback: (arr) {
        clientUsers = arr;
        if (clientUsers.isNotEmpty) {
          selectedClientEmail = clientUsers[0]["email"];
        }
        setState(() {});
      });
    }
  }

  Widget publishedChild() {
    String companyName = auditObj["companyname"] ?? "";

    return SingleChildScrollView(
      child: Center(
        child: BoxContainer(
          width: wdt,
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: defaultPadding),
              Text(companyName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87)),
              SizedBox(height: defaultPadding),
              // Download Report button
              OutlinedButton.icon(
                onPressed: () {
                  js.context.callMethod('open', [
                    API_URL +
                        "exportControl?type=1&id=" +
                        (auditObj["id"] ?? "").toString(),
                    "_blank"
                  ]);
                },
                icon: Icon(Icons.download, color: kPrimaryColor),
                label: Text("Download Report",
                    style: TextStyle(color: kPrimaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kPrimaryColor),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: defaultPadding * 2),
              // Select Client Mail
              Text("Select Client Mail Id",
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade700)),
              SizedBox(height: 8),
              SizedBox(
                width: 350,
                child: DropdownButtonFormField<String>(
                  value: selectedClientEmail,
                  items: clientUsers
                      .map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user["email"],
                      child: Text(user["email"] ?? ""),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedClientEmail = val;
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: Colors.grey.shade400)),
                  ),
                ),
              ),
              SizedBox(height: defaultPadding * 2),
              // Review checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: publishReviewed,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      publishReviewed = val ?? false;
                      setState(() {});
                    },
                  ),
                  Text(
                      "I'm reviewed the audit's conclusion, with all activities.",
                      style: TextStyle(fontSize: 14)),
                ],
              ),
              SizedBox(height: defaultPadding * 2),
              // Publish button
              ButtonComp(
                width: 300,
                color: Color(0xFF6FAF4E),
                label: "I'm Reviewed & Published report",
                onPressed: () {
                  if (!publishReviewed) {
                    APIService(context).showWindowAlert(
                        title: "",
                        desc:
                            "Please review and confirm before publishing.",
                        callback: () {});
                    return;
                  }
                  if (selectedClientEmail == null) {
                    APIService(context).showWindowAlert(
                        title: "",
                        desc: "Please select a client email.",
                        callback: () {});
                    return;
                  }
                  Map<String, dynamic> data = {
                    "audit_id": auditObj["id"],
                    "userid": usercontroller.userData.userId,
                  };
                  usercontroller.publishAuditStatus(context, data: data,
                      callback: () {
                    // Send email to selected client
                    Map<String, dynamic> emailData = {
                      "email": selectedClientEmail,
                      "name": auditObj["companyname"] ?? "",
                      "type": "publish",
                      "audit_name": auditObj["auditname"] ?? "",
                      "audit_no": auditObj["audit_no"] ?? "",
                      "message":
                          "Your audit report has been published and is ready for review."
                    };
                    APIService(context)
                        .postData("sendEmail", emailData, true)
                        .then((_) {});
                    APIService(context).showWindowAlert(
                        title: "",
                        desc: "Audit published successfully!",
                        callback: () {
                      Navigator.pushNamed(context, "/auditlist",
                          arguments: ScreenArgument(
                              argument: ArgumentData.USER,
                              mapData: {}));
                    });
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  //  Helpers
  // =====================================================

  String _getBackButtonName() {
    if (activeStep == 0)
      return AppTranslations.of(context)!.text("key_auditinfo");
    if (activeStep == 1 && !showQuestion)
      return "Branch Details";
    if (activeStep == 1 && showQuestion) return "Audit Activity";
    if (activeStep == 2) return "Audit Activity";
    if (activeStep == 3) return "Submit Review";
    return AppTranslations.of(context)!.text("key_auditinfo");
  }

  // =====================================================
  //  Build
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      onCallback: (id) {
        if (showQuestion &&
            questionArray.isNotEmpty &&
            questionArray[pageStep]["answer"].toString().trim().isNotEmpty) {
          APIService(context).showWindowAlert(
              title: "",
              desc: AppTranslations.of(context)!.text("key_message_24"),
              callback: () {
                saveAnswerQuestion(onCallback: (mid) {
                  _navigateMenu(id);
                });
              },
              showCancelBtn: true,
              okbutton:
                  AppTranslations.of(context)!.text("key_btn_save"));
        } else {
          _navigateMenu(id);
        }
      },
      enableAction: enableAction,
      previousScreenName: _getBackButtonName(),
      backEvent: () {
        if (showQuestion) {
          // Return from question view to category list
          if (questionArray[pageStep]["answer"]
              .toString()
              .trim()
              .isNotEmpty) {
            if (questionArray[pageStep]["submitAns"]
                .toString()
                .trim()
                .isEmpty) {
              APIService(context).showWindowAlert(
                  title: "",
                  desc: AppTranslations.of(context)!
                      .text("key_message_24"),
                  callback: () {
                    saveAnswerQuestion(onCallback: (id) {
                      showQuestion = false;
                      setState(() {});
                    });
                  },
                  showCancelBtn: true,
                  okbutton: AppTranslations.of(context)!
                      .text("key_btn_save"));
              return;
            }
          }
          showQuestion = false;
          setState(() {});
          return;
        }
        if (activeStep == 0) {
          Navigator.of(context).pop();
        } else if (activeStep == 1) {
          activeStep = 0;
          childs[0] = 1;
          if (auditObj["branch"].length != 0) {
            Future.delayed(Duration(milliseconds: 400)).then((value) {
              String date =
                  auditObj["branch"][0]["joining_date"].toString();
              auditObj["branch"][0]["joining_date"] =
                  Jiffy.parse(date).dateTime;
              formKey.currentState!.patchValue(auditObj["branch"][0]);
            });
          }
          gotoPage();
        } else if (activeStep == 2) {
          activeStep = 1;
          childs[1] = 1;
          gotoPage();
        } else if (activeStep == 3) {
          activeStep = 2;
          childs[2] = 1;
          gotoPage();
        }
        setState(() {});
      },
      showBackbutton: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stepper
          SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: EasyStepper(
              activeStep: activeStep,
              lineStyle: LineStyle(
                lineLength: 120,
                lineSpace: 0,
                lineType: LineType.normal,
                defaultLineColor: Colors.grey.shade400,
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
                    backgroundColor: childs[0] != 0
                        ? childs[0] == 1
                            ? Color(0xFFF29500)
                            : Colors.green
                        : Color(0xFF898989),
                    child: childs[0] == 2
                        ? Icon(CupertinoIcons.check_mark,
                            color: Colors.white,size: 15,)
                        : SizedBox(),
                  ),
                  topTitle: false,
                  title: "Branch Details",
                  customTitle: SizedBox(
                      width: double.infinity,
                      child: Text("Branch Details",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14))),
                ),
                EasyStep(
                  enabled: childs[1] != 0,
                  customStep: CircleAvatar(
                    radius: 25,
                    backgroundColor: childs[1] != 0
                        ? childs[1] == 1
                            ? Color(0xFFF29500)
                            : Colors.green
                        : Color(0xFF898989),
                    child: childs[1] == 2
                        ? Icon(CupertinoIcons.check_mark,
                            color: Colors.white,size: 15)
                        : SizedBox(),
                  ),
                  topTitle: false,
                  title: "Audit Activity",
                  customTitle: SizedBox(
                      width: double.infinity,
                      child: Text("Audit Activity",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14))),
                ),
                EasyStep(
                  enabled: childs[2] != 0,
                  customStep: CircleAvatar(
                    radius: 25,
                    backgroundColor: childs[2] != 0
                        ? childs[2] == 1
                            ? Color(0xFFF29500)
                            : Colors.green
                        : Color(0xFF898989),
                    child: childs[2] == 2
                        ? Icon(CupertinoIcons.check_mark,
                            color: Colors.white,size: 15)
                        : SizedBox(),
                  ),
                  topTitle: false,
                  title: "Submit Review",
                  customTitle: SizedBox(
                      width: double.infinity,
                      child: Text("Submit Review",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14))),
                ),
                EasyStep(
                  enabled: childs[3] != 0,
                  customStep: CircleAvatar(
                    radius: 25,
                    backgroundColor: childs[3] != 0
                        ? childs[3] == 1
                            ? Color(0xFFF29500)
                            : Colors.green
                        : Color(0xFF898989),
                    child: childs[3] == 2
                        ? Icon(CupertinoIcons.check_mark,
                            color: Colors.white,size: 15)
                        : SizedBox(),
                  ),
                  topTitle: false,
                  title: "Published",
                  customTitle: SizedBox(
                      width: double.infinity,
                      child: Text("Published",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14))),
                ),
              ],
              onStepReached: (index) {
                if (childs[index] == 0) return;
                if (showQuestion &&
                    questionArray[pageStep]["answer"]
                        .toString()
                        .trim()
                        .isNotEmpty) {
                  if (questionArray[pageStep]["submitAns"]
                      .toString()
                      .trim()
                      .isEmpty) {
                    APIService(context).showWindowAlert(
                        title: "",
                        desc: AppTranslations.of(context)!
                            .text("key_message_24"),
                        callback: () {
                          saveAnswerQuestion(onCallback: (id) {
                            showQuestion = false;
                            activeStep = index;
                            gotoPage();
                            setState(() {});
                          });
                        },
                        showCancelBtn: true,
                        okbutton: AppTranslations.of(context)!
                            .text("key_btn_save"));
                    return;
                  }
                }
                showQuestion = false;
                activeStep = index;
                gotoPage();
                if (activeStep == 0) {
                  if (auditObj["branch"].length != 0) {
                    Future.delayed(Duration(milliseconds: 400))
                        .then((value) {
                      String date =
                          auditObj["branch"][0]["joining_date"].toString();
                      auditObj["branch"][0]["joining_date"] =
                          Jiffy.parse(date).dateTime;
                      formKey.currentState!
                          .patchValue(auditObj["branch"][0]);
                    });
                  }
                }
                setState(() {});
              },
            ),
          ),
          // Page content
          Expanded(
            flex: 12,
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    // If in question mode, show question view
    if (showQuestion && activeStep == 1) {
      return questionChild();
    }
    // Otherwise show steps via page controller
    return PageView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemCount: 4,
      controller: _controller,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return branchDetailsChild();
          case 1:
            return auditActivityChild();
          case 2:
            return submitReviewChild();
          case 3:
            return publishedChild();
          default:
            return Container();
        }
      },
    );
  }

  void _navigateMenu(int id) {
    usercontroller.selectedIndex = id;
    if (id == 0) {
      Navigator.pushNamed(context, "/dashboard");
    } else if (id == 1) {
      Navigator.pushNamed(context, "/auditlist",
          arguments:
              ScreenArgument(argument: ArgumentData.USER, mapData: {}));
    } else if (id == 2) {
      Navigator.pushNamed(context, "/client",
          arguments:
              ScreenArgument(argument: ArgumentData.CLIENT, mapData: {}));
    } else if (id == 3) {
      Navigator.pushNamed(context, "/user",
          arguments:
              ScreenArgument(argument: ArgumentData.USER, mapData: {}));
    } else if (id == 4) {
      Navigator.pushNamed(context, "/templatelist",
          arguments:
              ScreenArgument(argument: ArgumentData.USER, mapData: {}));
    } else if (id == 5) {
      APIService(context).showWindowAlert(
          title: "",
          desc: AppTranslations.of(context)!.text("key_message_09"),
          showCancelBtn: true,
          callback: () {
            usercontroller.logout(context, data: {}, callback: () {
              Navigator.pushNamed(context, "/login");
            });
          });
    }
  }
}
