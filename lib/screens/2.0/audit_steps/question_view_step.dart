import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/app_form_field.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';

class QuestionViewStep extends StatelessWidget {
  final double wdt;
  final dynamic categoryObj;
  final List<dynamic> questionArray;
  final int pageStep;
  final int answerQuest;
  final bool isViewMode;
  final bool showNextBtn;
  final Color selectedColor;
  final List<dynamic> scoreArr;
  final PageController questionController;

  // Callbacks
  final void Function(dynamic element) onQuestionIndexTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(dynamic question, String value, Color color)
      onScoreTap;
  final void Function(dynamic question) onFilePick;
  final void Function(dynamic imageElement, dynamic question)
      onFileRemove;
  final VoidCallback onRefresh;

  const QuestionViewStep({
    super.key,
    required this.wdt,
    required this.categoryObj,
    required this.questionArray,
    required this.pageStep,
    required this.answerQuest,
    required this.isViewMode,
    required this.showNextBtn,
    required this.selectedColor,
    required this.scoreArr,
    required this.questionController,
    required this.onQuestionIndexTap,
    required this.onPrevious,
    required this.onNext,
    required this.onScoreTap,
    required this.onFilePick,
    required this.onFileRemove,
    required this.onRefresh,
  });

  /// Get the current dropdown value from selecteddropdown or
  /// fallback to config.
  static dynamic getDropdownValue(
      dynamic question, dynamic element2) {
    List<dynamic> arr = (question["selecteddropdown"] ?? [])
        .where((item) =>
            item["dropdownid"] == element2["dropdownid"])
        .toList();
    if (arr.isNotEmpty &&
        arr[0]["selectedoption"] != null &&
        arr[0]["selectedoption"].toString().trim().isNotEmpty) {
      return arr[0]["selectedoption"];
    }
    var val = element2["selectedoption"];
    if (val == null || val.toString().trim().isEmpty) return null;
    return val;
  }

  Color _getQuestionColor(dynamic element, int index) {
    Color c = const Color(0xFF535353);
    if (element["answer"].toString().trim().isEmpty) {
      if (pageStep == index - 1) c = const Color(0xFF2E77D0);
    } else {
      c = const Color(0xFF67AC5B);
      if (pageStep == index - 1) c = const Color(0xFF2E77D0);
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    int id = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
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
                      style: const TextStyle(
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
                      style: const TextStyle(
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
            child: questionArray.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 10,
                        child: PageView.builder(
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: questionArray.length,
                          controller: questionController,
                          itemBuilder: (context, index) {
                            return KeyedSubtree(
                              key: ValueKey(
                                  "question_${questionArray[index]["questionid"]}"),
                              child: _questionComp(
                                  context, questionArray[index]),
                            );
                          },
                        ),
                      ),
                      // Side index buttons
                      SizedBox(
                        width: 30,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                questionArray.map((element) {
                              id++;
                              return InkWell(
                                onTap: () {
                                  onQuestionIndexTap(element);
                                },
                                child: Container(
                                  width:
                                      pageStep == element["index"]
                                          ? 30
                                          : 20,
                                  height: 30,
                                  margin: const EdgeInsets.only(
                                      top: 4, bottom: 4),
                                  decoration: BoxDecoration(
                                    color: _getQuestionColor(
                                        element, id),
                                    borderRadius:
                                        const BorderRadius.only(
                                            topRight:
                                                Radius.circular(8),
                                            bottomRight:
                                                Radius.circular(
                                                    8)),
                                  ),
                                  child: Center(
                                    child: Text(id.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    ],
                  )
                : const SizedBox(),
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
                if (pageStep > 0)
                  ButtonComp(
                    width: 120,
                    label: "Previous",
                    color: const Color(0xFF555555),
                    onPressed: onPrevious,
                  ),
                if (pageStep > 0) const SizedBox(width: 20),
                Visibility(
                  visible: isViewMode
                      ? (pageStep < questionArray.length - 1)
                      : showNextBtn,
                  child: ButtonComp(
                    width: 120,
                    label: AppTranslations.of(context)!
                        .text("key_btn_next"),
                    onPressed: onNext,
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

  Widget _questionComp(BuildContext context, dynamic question) {
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(question["question"],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF505050))),
                  const SizedBox(height: 20),
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
                        borderRadius: const BorderRadius.all(
                            Radius.circular(25)),
                        border: Border.all(
                            color: const Color(0xFF707070),
                            width: 1.0)),
                    child: Center(
                      child: Text(question["answer"],
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    AppTranslations.of(context)!.text("key_score"),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF505050)),
                  ),
                  const SizedBox(height: 10),
                  // Score buttons row (hidden in view mode)
                  if (!isViewMode)
                    Wrap(
                      children: scoreArr
                          .map((element) => Container(
                                width: 80,
                                height: 50,
                                margin: const EdgeInsets.only(
                                    top: 7, bottom: 7),
                                color: element["color"],
                                child: InkWell(
                                  onTap: () {
                                    onScoreTap(
                                        question,
                                        element["value"],
                                        element["color"]);
                                  },
                                  child: Center(
                                    child: Text(
                                        element["value"].toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Dropdowns row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: question["dropdown"]
                  .map<Widget>((element2) {
                return Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AppLabeledField(
                      label: element2["dropdownname"],
                      child: DropdownButtonFormField<dynamic>(
                        initialValue: getDropdownValue(
                            question, element2),
                        items: element2["options"]
                            .map<DropdownMenuItem<dynamic>>(
                                (toElement) =>
                                    DropdownMenuItem(
                                      value: toElement[
                                          "optionvalue"],
                                      child: Text(toElement[
                                          "optionvalue"]),
                                    ))
                            .toList(),
                        onChanged: isViewMode
                            ? null
                            : (value) {
                                List<dynamic> arr = question[
                                        "selecteddropdown"]
                                    .where((item) =>
                                        item["dropdownid"] ==
                                        element2["dropdownid"])
                                    .toList();
                                if (arr.isEmpty) {
                                  question["selecteddropdown"]
                                      .add({
                                    "dropdownid":
                                        element2["dropdownid"],
                                    "dropdownname":
                                        element2["dropdownname"],
                                    "selectedoption": value
                                  });
                                } else {
                                  arr[0]["selectedoption"] =
                                      value;
                                }
                                onRefresh();
                              },
                        decoration:
                            AppFormStyles.inputDecoration(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Review text
            AppLabeledField(
              label: AppTranslations.of(context)!
                  .text("key_review"),
              child: FormBuilderTextField(
                name: "reviews_${question["questionid"]}",
                readOnly: isViewMode,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                initialValue: question["reviews"],
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  question["reviews"] = value;
                  onRefresh();
                },
                decoration: AppFormStyles.inputDecoration(),
              ),
            ),
            const SizedBox(height: 16),
            // Client remarks
            AppLabeledField(
              label: AppTranslations.of(context)!
                  .text("key_customer_review"),
              child: FormBuilderTextField(
                name:
                    "clientremarks_${question["questionid"]}",
                readOnly: isViewMode,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                initialValue: question["clientremarks"],
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  question["clientremarks"] = value;
                  onRefresh();
                },
                decoration: AppFormStyles.inputDecoration(),
              ),
            ),
            const SizedBox(height: 20),
            // File attachments
            Row(
              children: [
                if (!isViewMode)
                  Flexible(
                    flex: 1,
                    child: SizedBox(
                      width: 150,
                      height: buttonHeight,
                      child: ElevatedButton.icon(
                          onPressed: () {
                            onFilePick(question);
                          },
                          icon: const Icon(Icons.cloud_upload,
                              size: 20, color: Colors.white),
                          label: Text(
                              AppTranslations.of(context)!
                                  .text("key_btn_upload"),
                              style: const TextStyle(
                                  color: Colors.white))),
                    ),
                  ),
                Flexible(
                  flex: 2,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: question["proofdocuments"]
                        .map<Widget>((imgelement) {
                      return _buildAttachment(
                          context, imgelement, question);
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

  Widget _buildAttachment(BuildContext context,
      dynamic imgelement, dynamic question) {
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
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: InkWell(
              onTap: () {
                launchUrl(Uri.parse(
                  IMG_URL + imgelement["image"].toString(),
                ));
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: image
                            ? NetworkImage(
                                IMG_URL + imgelement["image"])
                            : AssetImage(img)),
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (!isViewMode)
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: () {
                  onFileRemove(imgelement, question);
                },
                child: SvgPicture.asset(
                  "assets/icons/close.svg",
                  colorFilter: ColorFilter.mode(
                      Colors.blue.shade900, BlendMode.srcIn),
                  height: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
