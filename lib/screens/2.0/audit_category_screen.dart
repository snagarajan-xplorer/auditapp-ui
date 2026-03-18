import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/models/screenarguments.dart';
import 'package:audit_app/services/api_service.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../../controllers/usercontroller.dart';
import '../main/layoutscreen.dart';
import 'audit_steps/branch_details_step.dart';
import 'audit_steps/audit_activity_step.dart';
import 'audit_steps/question_view_step.dart';
import 'audit_steps/submit_review_step.dart';
import 'audit_steps/published_step.dart';

/// V2.0 Audit Execution Screen
/// 4-step stepper: Branch Details → Audit Activity → Submit Review → Published
class AuditCategoryScreenV2 extends StatefulWidget {
  const AuditCategoryScreenV2({super.key});

  @override
  State<AuditCategoryScreenV2> createState() =>
      _AuditCategoryScreenV2State();
}

class _AuditCategoryScreenV2State
    extends State<AuditCategoryScreenV2> {
  GlobalKey<FormBuilderState> formKey =
      GlobalKey<FormBuilderState>();
  double wdt = 950;
  ScreenArgument? pageargument;
  late final UserController usercontroller;

  final _controller = PageController(keepPage: false);
  final _questioncontroller = PageController(keepPage: false);

  /// True when opened from "View Audit" on a published audit — all fields read-only.
  bool isViewMode = false;

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

  // Validation: starts disabled, switches to onUserInteraction after first submit
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // =====================================================
  //  Lifecycle
  // =====================================================

  @override
  void initState() {
    super.initState();
    usercontroller = Get.find<UserController>();
    Future.delayed(const Duration(milliseconds: 200)).then((onValue) {
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
      String auditId =
          (mapData["id"] ?? mapData["audit_id"] ?? "").toString();

      // Detect view-only mode (from "View Audit" on published audits)
      if (pageargument?.mode == "View") {
        isViewMode = true;
      }

      // If audit status is "S" (Scheduled/Upcoming), start it first
      dynamic statusRaw = mapData["status"];
      String status;
      if (statusRaw is Map) {
        String label = (statusRaw["label"] ?? "").toString();
        status = const {
              'Upcoming': 'S',
              'Inprogress': 'PG',
              'Published': 'P',
              'Review': 'C',
              'Cancelled': 'CL',
            }[label] ??
            "";
      } else {
        status = (statusRaw ?? "").toString();
      }
      if (!isViewMode && status == "S") {
        usercontroller.startAudit(context,
            data: {"audit_id": auditId}, callback: (success) {
          _loadAuditData(auditId);
        });
      } else {
        _loadAuditData(auditId);
      }
    });
  }

  // =====================================================
  //  Data Loading
  // =====================================================

  void _loadAuditData(String auditId) {
    Map<String, dynamic> data = {"id": auditId};
    usercontroller.getAuditQuestion(context, data: data, callback: (res) {
      auditObj = res;
      showAudit = true;
      int ansValue = 0;
      int totalValue = 0;

      auditObj["categorys"].forEach((element) {
        element["submitAns"] =
            element["answer"].toString().trim().isNotEmpty
                ? element["answer"].toString().trim()
                : "";
        element["questions"].forEach((eleObj) {
          eleObj["submitAns"] =
              eleObj["answer"].toString().trim().isNotEmpty
                  ? eleObj["answer"].toString().trim()
                  : "";
        });

        List<dynamic> attendQuestion = element["questions"]
            .where((quest) =>
                quest["answer"].toString().trim().isNotEmpty)
            .toList();
        for (var ele in attendQuestion) {
          if (ele["answer"] != "N/A") {
            String str = (ele["answer"] ?? "0");
            int d = int.tryParse(str) ?? 0;
            ansValue = ansValue + d;
            totalValue = totalValue + 4;
          }
        }
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

      // Initialize step states based on existing audit progress
      String auditStatus = (auditObj["status"] ?? "").toString();
      bool hasBranch =
          auditObj["branch"] != null && auditObj["branch"].length != 0;
      bool allCatsDone = _allCategoriesComplete();
      if (auditStatus == "P") {
        childs = [2, 2, 2, 2];
        activeStep = 3;
        publishReviewed = true;
        _loadClientUsers();
      } else if (auditStatus == "C") {
        childs = [2, 2, 2, 1];
        activeStep = 3;
        _loadClientUsers();
      } else if (hasBranch && allCatsDone) {
        childs = [2, 2, 1, 0];
        activeStep = 2;
      } else if (hasBranch) {
        childs = [2, 1, 0, 0];
        activeStep = 1;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (activeStep == 0) {
          if (auditObj["branch"].length != 0) {
            String date =
                auditObj["branch"][0]["joining_date"].toString();
            auditObj["branch"][0]["joining_date"] =
                Jiffy.parse(date).dateTime;
            formKey.currentState!.patchValue(auditObj["branch"][0]);
          }
        }
        if (activeStep > 0) {
          _controller.jumpToPage(activeStep);
        }
      });
      setState(() {});
    });
  }

  void _loadClientUsers() {
    if (auditObj["client_id"] != null) {
      Map<String, dynamic> dataobj = {
        "client_id": auditObj["client_id"]
      };
      usercontroller.getClientUserList(context,
          data: dataobj,
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

  // =====================================================
  //  Score & Category Helpers
  // =====================================================

  void processAuditCategories() {
    int ansValue = 0;
    int totalValue = 0;
    for (var ele in auditObj["categorys"]) {
      List<dynamic> attendQuestion = ele["questions"]
          .where((quest) =>
              quest["answer"].toString().trim().isNotEmpty)
          .toList();
      for (var q in attendQuestion) {
        if (q["answer"] != "N/A") {
          int d = int.tryParse(q["answer"] ?? "0") ?? 0;
          ansValue += d;
          totalValue += 4;
        }
      }
    }
    totalMark = totalValue.toString();
    answerMark = ansValue.toString();
    int? v1 = int.tryParse(answerMark);
    int? v2 = int.tryParse(totalMark);
    if (v2 != null && v2 != 0) {
      totalPer = ((v1! / v2) * 100).round().toString();
    }
  }

  void setCategoryStatus(dynamic element) {
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

  bool _allCategoriesComplete() {
    if (auditObj["categorys"] == null ||
        auditObj["categorys"].isEmpty) {
      return false;
    }
    List<dynamic> completed = auditObj["categorys"]
        .where((obj) => obj["complete"] == true)
        .toList();
    return completed.length == auditObj["categorys"].length;
  }

  void _syncAuditActivityStepState() {
    if (_allCategoriesComplete()) {
      childs[1] = 2;
    } else {
      childs[1] = 1;
    }
  }

  // =====================================================
  //  Navigation
  // =====================================================

  void gotoPage() {
    _controller.animateToPage(activeStep,
        duration: _kDuration, curve: _kCurve);
    setState(() {});
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
      if (arr.isNotEmpty) {
        selectedColor = arr[0]["color"];
      }
    }
    _questioncontroller.animateToPage(pageStep,
        duration: _kDuration, curve: _kCurve);
    setState(() {});
  }

  void _handleQuestionIndexTap(dynamic element) {
    if (isViewMode) {
      _navigateToQuestion(element["index"]);
      return;
    }
    String answer =
        questionArray[pageStep]["answer"].toString().trim();
    String submitAns =
        questionArray[pageStep]["submitAns"].toString().trim();
    if (answer.isNotEmpty && answer != submitAns) {
      saveAnswerQuestion(onCallback: (id) {
        _navigateToQuestion(element["index"]);
      });
    } else {
      _navigateToQuestion(element["index"]);
    }
  }

  // =====================================================
  //  File Upload
  // =====================================================

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

  // =====================================================
  //  Save Answer
  // =====================================================

  void saveAnswerQuestion({required Function(int) onCallback}) {
    Map<String, dynamic> data = {
      "audit_id": questionArray[pageStep]["audit_id"],
      "category_id": questionArray[pageStep]["category_id"],
      "questionid": questionArray[pageStep]["questionid"],
      "reviews": questionArray[pageStep]["reviews"],
      "clientremarks": questionArray[pageStep]["clientremarks"],
      "answer": questionArray[pageStep]["answer"],
      "mode_of_audit": questionArray[pageStep]["mode_of_audit"],
      "responsibility": questionArray[pageStep]["responsibility"],
      "timeframe": questionArray[pageStep]["timeframe"],
      "cateanswer": categoryObj["answer"],
      "catetotal": categoryObj["total"],
      "selecteddropdown": questionArray[pageStep]["selecteddropdown"]
    };
    usercontroller.saveAuditQuestion(context, data: data,
        callback: () async {
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
      for (var eleobj in qarray) {
        ans = ans + (num.tryParse(eleobj["answer"].toString()) ?? 0);
        total = total + 4;
      }
      categoryObj["answer"] = ans.toString();
      categoryObj["total"] = total.toString();
      processAuditCategories();
      List ansList = questionArray
          .where(
              (ele) => ele["submitAns"].toString().trim().isNotEmpty)
          .toList();
      answerQuest = ansList.length;
      if (ansList.length == questionArray.length) {
        showNextBtn = false;
        setState(() {});
        setCategoryStatus(categoryObj);
        List<dynamic> catearr = auditObj["categorys"]
            .where((obj) => obj["complete"] == true)
            .toList();
        if (auditObj["categorys"].length == catearr.length) {
          // ALL categories complete → advance to Submit Review
          childs[0] = 2;
          childs[1] = 2;
          childs[2] = 1;
          APIService(context).showWindowAlert(
              title: "",
              hideTitle: true,
              okButtonColor: const Color(0xFF67AC5B),
              desc:
                  AppTranslations.of(context)!.text("key_message_13"),
              callback: () {
                showQuestion = false;
                activeStep = 2;
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.jumpToPage(activeStep);
                });
              });
        } else {
          // Current category complete, others remain
          APIService(context).showWindowAlert(
              title: "",
              hideTitle: true,
              okButtonColor: const Color(0xFF67AC5B),
              desc:
                  AppTranslations.of(context)!.text("key_message_13"),
              callback: () {
                showQuestion = false;
                activeStep = 1;
                _syncAuditActivityStepState();
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.jumpToPage(activeStep);
                });
              });
        }
      } else {
        onCallback(1);
      }
      setState(() {});
    });
  }

  // =====================================================
  //  Open Category (Audit Activity → Question View)
  // =====================================================

  void _openCategory(dynamic element, String answeredQuestion,
      String totalQuestion) {
    categoryObj = element;
    questionArray = [];
    questionArray = element["questions"];
    for (var mid = 0; mid < questionArray.length; mid++) {
      questionArray[mid]["index"] = mid;
      questionArray[mid]["isSaved"] =
          questionArray[mid]["submitAns"].toString().trim().isNotEmpty;
    }
    pageStep = 0;
    int d = questionArray.indexWhere(
        (element) => element["answer"].toString().trim().isNotEmpty);
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
    showQuestion = true;
    if (questionArray[pageStep]["answer"].toString().trim().isEmpty) {
      selectedColor = Colors.transparent;
    } else {
      List<dynamic> arr = usercontroller.scoreArr
          .where((e) =>
              e["value"] ==
              questionArray[pageStep]["submitAns"].toString().trim())
          .toList();
      if (arr.isNotEmpty) {
        selectedColor = arr[0]["color"];
      }
    }
    showNextBtn = true;
    List<dynamic> attendQuestion2 = categoryObj["questions"]
        .where((quest) =>
            quest["answer"].toString().trim().isNotEmpty)
        .toList();
    answerQuest = attendQuestion2.length;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 20)).then((v) {
      _questioncontroller.animateToPage(pageStep,
          duration: _kDuration, curve: _kCurve);
    });
  }

  // =====================================================
  //  Step Callback Handlers
  // =====================================================

  void _handleBranchContinue() {
    if (isViewMode) {
      activeStep = 1;
      setState(() {});
      gotoPage();
      return;
    }
    if (formKey.currentState!.saveAndValidate()) {
      _autovalidateMode = AutovalidateMode.disabled;
      Map<String, dynamic> obj =
          Map.of(formKey.currentState!.value);
      obj["joining_date"] =
          Jiffy.parseFromDateTime(obj["joining_date"])
              .dateTime
              .toIso8601String();
      obj["audit_id"] = auditObj["id"];
      usercontroller.saveAuditBranch(context, data: obj,
          callback: () {
        _autovalidateMode = AutovalidateMode.disabled;
        if (auditObj["branch"].isEmpty) {
          auditObj["branch"].add(Map<String, dynamic>.from(
              formKey.currentState!.value));
        } else {
          auditObj["branch"][0] = Map<String, dynamic>.from(
              formKey.currentState!.value);
        }
        childs[0] = 2;
        childs[1] = 1;
        activeStep = 1;
        setState(() {});
        gotoPage();
      });
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  void _handleScoreTap(
      dynamic question, String value, Color color) {
    question["answer"] = value;
    selectedColor = color;
    enableAction = false;
    setState(() {});
  }

  void _handleFilePick(dynamic question) async {
    if (question["proofdocuments"].length == 10) {
      APIService(context).showToastMgs(
          AppTranslations.of(context)!.text("key_error_04"));
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    _imageBytesList = [];
    _imageNameList = [];
    countFile = 0;
    setState(() {});
    if (result != null && result.files.isNotEmpty) {
      totalFile = result.files.length;
      for (var kid = 0; kid < result.files.length; kid++) {
        var file = result.files[kid];
        var index = file.name.lastIndexOf(".");
        var ext = file.name.substring(index, file.name.length);
        if (!extension.contains(ext)) {
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
  }

  void _handleFileRemove(
      dynamic imageElement, dynamic question) {
    APIService(context).showWindowAlert(
        title: "",
        desc: AppTranslations.of(context)!.text("key_are_you"),
        showCancelBtn: true,
        callback: () {
          Map<String, dynamic> obj = {
            "id": imageElement["id"],
            "audit_id": imageElement["audit_id"],
            "question_id": imageElement["question_id"]
          };
          usercontroller.removeUploadFile(context, data: obj,
              callback: (arr) {
            question["proofdocuments"] = arr;
            setState(() {});
          });
        });
  }

  void _handleQuestionPrevious() {
    if (isViewMode) {
      _navigateToQuestion(pageStep - 1);
      return;
    }
    String answer =
        questionArray[pageStep]["answer"].toString().trim();
    String submitAns =
        questionArray[pageStep]["submitAns"].toString().trim();
    if (answer.isNotEmpty && answer != submitAns) {
      saveAnswerQuestion(onCallback: (id) {
        _navigateToQuestion(pageStep - 1);
      });
    } else {
      _navigateToQuestion(pageStep - 1);
    }
  }

  void _handleQuestionNext() {
    if (isViewMode) {
      if (pageStep < questionArray.length - 1) {
        _navigateToQuestion(pageStep + 1);
      }
      return;
    }
    String answer =
        questionArray[pageStep]["answer"].toString().trim();
    String submitAns =
        questionArray[pageStep]["submitAns"].toString().trim();
    if (answer.isNotEmpty && answer != submitAns) {
      saveAnswerQuestion(onCallback: (id) {
        if (pageStep < questionArray.length - 1) {
          _navigateToQuestion(pageStep + 1);
        }
      });
    } else if (pageStep < questionArray.length - 1) {
      _navigateToQuestion(pageStep + 1);
    } else {
      // Last question with answer already saved
      List ansList = questionArray
          .where(
              (ele) => ele["submitAns"].toString().trim().isNotEmpty)
          .toList();
      if (ansList.length == questionArray.length) {
        setCategoryStatus(categoryObj);
        List<dynamic> catearr = auditObj["categorys"]
            .where((obj) => obj["complete"] == true)
            .toList();
        if (auditObj["categorys"].length == catearr.length) {
          childs[0] = 2;
          childs[1] = 2;
          childs[2] = 1;
          APIService(context).showWindowAlert(
              title: "",
              hideTitle: true,
              okButtonColor: const Color(0xFF67AC5B),
              desc:
                  AppTranslations.of(context)!.text("key_message_13"),
              callback: () {
                showQuestion = false;
                activeStep = 2;
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.jumpToPage(activeStep);
                });
              });
        } else {
          APIService(context).showWindowAlert(
              title: "",
              hideTitle: true,
              okButtonColor: const Color(0xFF67AC5B),
              desc:
                  AppTranslations.of(context)!.text("key_message_13"),
              callback: () {
                showQuestion = false;
                activeStep = 1;
                _syncAuditActivityStepState();
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.jumpToPage(activeStep);
                });
              });
        }
      }
    }
  }

  void _handleAcknowledgeChanged(bool value) {
    reviewAcknowledged = value;
    setState(() {});
  }

  void _handleBrowseAcknowledgeImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        showImage = false;
        acknowlodgeImage = true;
        _imageBytes = result.files.first.bytes;
        _imageName = result.files.first.name;
      });
    }
  }

  void _handleSubmitReview() {
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
          desc: AppTranslations.of(context)!.text("key_error_06"),
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
        _loadClientUsers();
        setState(() {});
        gotoPage();
      });
    });
  }

  void _handleClientEmailChanged(String? val) {
    selectedClientEmail = val;
    setState(() {});
  }

  void _handlePublishReviewedChanged(bool val) {
    publishReviewed = val;
    setState(() {});
  }

  void _handlePublish() {
    if (!publishReviewed) {
      APIService(context).showWindowAlert(
          title: "",
          desc: "Please review and confirm before publishing.",
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
      "client_email": selectedClientEmail,
    };
    usercontroller.publishAuditStatus(context, data: data,
        callback: () {
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
      childs[3] = 2;
      setState(() {});
      APIService(context).showWindowAlert(
          title: "",
          desc: "Audit published successfully!",
          callback: () {
        Navigator.pushNamed(context, "/auditlist",
            arguments: ScreenArgument(
                argument: ArgumentData.USER, mapData: {}));
      });
    });
  }

  // =====================================================
  //  Back Navigation
  // =====================================================

  void _handleBack() {
    if (showQuestion) {
      if (isViewMode) {
        showQuestion = false;
        setState(() {});
        return;
      }
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
                  _syncAuditActivityStepState();
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
      _syncAuditActivityStepState();
      setState(() {});
      return;
    }
    if (activeStep == 0) {
      Navigator.of(context).pop();
    } else if (activeStep == 1) {
      activeStep = 0;
      if (!isViewMode) childs[0] = 1;
      if (auditObj["branch"].length != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          var dateVal = auditObj["branch"][0]["joining_date"];
          if (dateVal is! DateTime) {
            auditObj["branch"][0]["joining_date"] =
                Jiffy.parse(dateVal.toString()).dateTime;
          }
          formKey.currentState!.patchValue(auditObj["branch"][0]);
        });
      }
      gotoPage();
    } else if (activeStep == 2) {
      activeStep = 1;
      if (!isViewMode) childs[1] = 1;
      gotoPage();
    } else if (activeStep == 3) {
      activeStep = 2;
      if (!isViewMode) childs[2] = 1;
      gotoPage();
    }
    setState(() {});
  }

  // =====================================================
  //  Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      onCallback: (id) {
        if (isViewMode) {
          _navigateMenu(id);
          return;
        }
        if (showQuestion &&
            questionArray.isNotEmpty &&
            questionArray[pageStep]["answer"]
                .toString()
                .trim()
                .isNotEmpty) {
          APIService(context).showWindowAlert(
              title: "",
              desc:
                  AppTranslations.of(context)!.text("key_message_24"),
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
      showBackbutton: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inline "← Back" button
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 80, top: 12),
              child: InkWell(
                onTap: _handleBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back,
                        size: 18, color: Color(0xFF02B2EB)),
                    SizedBox(width: 4),
                    Text("Back",
                        style: TextStyle(
                            color: Color(0xFF02B2EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
          // Stepper
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: _buildStepper(),
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

  Widget _buildStepper() {
    return EasyStepper(
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
      activeStepTextColor: const Color(0xFF002651),
      finishedStepTextColor: const Color(0xFF002651),
      internalPadding: 0,
      showLoadingAnimation: false,
      stepRadius: 15,
      showStepBorder: false,
      steps: [
        _buildEasyStep(0, "Branch Details"),
        _buildEasyStep(1, "Audit Activity"),
        _buildEasyStep(2, "Submit Review"),
        _buildEasyStep(3, "Published"),
      ],
      onStepReached: _onStepReached,
    );
  }

  EasyStep _buildEasyStep(int index, String title) {
    return EasyStep(
      enabled: childs[index] != 0,
      customStep: CircleAvatar(
        radius: 25,
        backgroundColor: childs[index] != 0
            ? childs[index] == 1
                ? const Color(0xFFF29500)
                : Colors.green
            : const Color(0xFF898989),
        child: childs[index] == 2
            ? const Icon(CupertinoIcons.check_mark,
                color: Colors.white, size: 15)
            : const SizedBox(),
      ),
      placeTitleAtStart: false,
      title: title,
      customTitle: SizedBox(
          width: double.infinity,
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14))),
    );
  }

  void _onStepReached(int index) {
    if (childs[index] == 0) return;
    if (isViewMode) {
      showQuestion = false;
      activeStep = index;
      gotoPage();
      if (activeStep == 0 && auditObj["branch"].length != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          var dateVal = auditObj["branch"][0]["joining_date"];
          if (dateVal is! DateTime) {
            auditObj["branch"][0]["joining_date"] =
                Jiffy.parse(dateVal.toString()).dateTime;
          }
          formKey.currentState!.patchValue(auditObj["branch"][0]);
        });
      }
      setState(() {});
      return;
    }
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
            desc:
                AppTranslations.of(context)!.text("key_message_24"),
            callback: () {
              saveAnswerQuestion(onCallback: (id) {
                showQuestion = false;
                activeStep = index;
                gotoPage();
                setState(() {});
              });
            },
            showCancelBtn: true,
            okbutton:
                AppTranslations.of(context)!.text("key_btn_save"));
        return;
      }
    }
    showQuestion = false;
    activeStep = index;
    gotoPage();
    if (activeStep == 0) {
      if (auditObj["branch"].length != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          String date =
              auditObj["branch"][0]["joining_date"].toString();
          auditObj["branch"][0]["joining_date"] =
              Jiffy.parse(date).dateTime;
          formKey.currentState!.patchValue(auditObj["branch"][0]);
        });
      }
    }
    setState(() {});
  }

  Widget _buildPageContent() {
    // If in question mode, show question view
    if (showQuestion && activeStep == 1) {
      return QuestionViewStep(
        wdt: wdt,
        categoryObj: categoryObj,
        questionArray: questionArray,
        pageStep: pageStep,
        answerQuest: answerQuest,
        isViewMode: isViewMode,
        showNextBtn: showNextBtn,
        selectedColor: selectedColor,
        scoreArr: usercontroller.scoreArr,
        questionController: _questioncontroller,
        onQuestionIndexTap: _handleQuestionIndexTap,
        onPrevious: _handleQuestionPrevious,
        onNext: _handleQuestionNext,
        onScoreTap: _handleScoreTap,
        onFilePick: _handleFilePick,
        onFileRemove: _handleFileRemove,
        onRefresh: () => setState(() {}),
      );
    }
    // Otherwise show steps via page controller
    return PageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      controller: _controller,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return BranchDetailsStep(
              formKey: formKey,
              isViewMode: isViewMode,
              autovalidateMode: _autovalidateMode,
              onContinue: _handleBranchContinue,
            );
          case 1:
            return AuditActivityStep(
              auditObj: auditObj,
              answerMark: answerMark,
              totalMark: totalMark,
              totalPer: totalPer,
              isViewMode: isViewMode,
              showAudit: showAudit,
              onCategoryTap: _openCategory,
            );
          case 2:
            return SubmitReviewStep(
              auditObj: auditObj,
              isViewMode: isViewMode,
              wdt: wdt,
              reviewAcknowledged: reviewAcknowledged,
              acknowlodgeImage: acknowlodgeImage,
              imageBytes: _imageBytes,
              userName: usercontroller.userData.name ?? "",
              onAcknowledgeChanged: _handleAcknowledgeChanged,
              onBrowse: _handleBrowseAcknowledgeImage,
              onSubmit: _handleSubmitReview,
            );
          case 3:
            return PublishedStep(
              auditObj: auditObj,
              isViewMode: isViewMode,
              wdt: wdt,
              clientUsers: clientUsers,
              selectedClientEmail: selectedClientEmail,
              publishReviewed: publishReviewed,
              onClientEmailChanged: _handleClientEmailChanged,
              onReviewedChanged: _handlePublishReviewedChanged,
              onPublish: _handlePublish,
            );
          default:
            return const SizedBox();
        }
      },
    );
  }

  // =====================================================
  //  Menu Navigation
  // =====================================================

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
          arguments: ScreenArgument(
              argument: ArgumentData.CLIENT, mapData: {}));
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
