import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/app_form_field.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
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

  // Callbacks
  final void Function(dynamic element) onQuestionIndexTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(dynamic question, String value, Color color)
      onScoreTap;
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
    required this.onQuestionIndexTap,
    required this.onPrevious,
    required this.onNext,
    required this.onScoreTap,
    required this.onRefresh,
  });



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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
          width: wdt + 140,
          child: questionArray.isNotEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 10,
                      child: KeyedSubtree(
                        key: ValueKey(
                            "question_${questionArray[pageStep]["questionid"]}"),
                        child: _questionComp(
                            context, questionArray[pageStep]),
                      ),
                    ),
                    SizedBox(
                      width: 30,
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
                    )
                  ],
                )
              : const SizedBox(),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionComp(BuildContext context, dynamic question) {
    return BoxContainer(
      width: wdt + 120,
      height: null,
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
            const SizedBox(height: 16),
            // Observation (was Review)
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
            // Management Response (was Client Remarks)
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
            const SizedBox(height: 16),
            // Mode of Audit / Responsibility / Time Frame row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AppLabeledField(
                      label: AppTranslations.of(context)!
                          .text("key_mode_of_audit"),
                      child: DropdownButtonFormField<String>(
                        initialValue: (question["mode_of_audit"] ?? "").toString().isEmpty
                            ? null
                            : question["mode_of_audit"],
                        items: const [
                          DropdownMenuItem(value: "Onsite", child: Text("Onsite")),
                          DropdownMenuItem(value: "Offsite", child: Text("Offsite")),
                          DropdownMenuItem(value: "Hybrid", child: Text("Hybrid")),
                        ],
                        onChanged: isViewMode
                            ? null
                            : (value) {
                                question["mode_of_audit"] = value;
                                onRefresh();
                              },
                        decoration: AppFormStyles.inputDecoration(),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AppLabeledField(
                      label: AppTranslations.of(context)!
                          .text("key_responsibility"),
                      child: FormBuilderTextField(
                        name: "responsibility_${question["questionid"]}",
                        readOnly: isViewMode,
                        initialValue: question["responsibility"] ?? "",
                        style: Theme.of(context).textTheme.bodyMedium,
                        onChanged: (value) {
                          question["responsibility"] = value;
                          onRefresh();
                        },
                        decoration: AppFormStyles.inputDecoration(),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: AppLabeledField(
                    label: AppTranslations.of(context)!
                        .text("key_timeframe"),
                    child: GestureDetector(
                      onTap: isViewMode
                          ? null
                          : () async {
                              DateTime initial = DateTime.now();
                              if ((question["timeframe"] ?? "").toString().isNotEmpty) {
                                try {
                                  initial = DateFormat('dd/MM/yyyy hh:mm a').parse(question["timeframe"]);
                                } catch (_) {
                                  try {
                                    initial = DateFormat('dd/MM/yyyy').parse(question["timeframe"]);
                                  } catch (_) {
                                    try {
                                      initial = DateFormat('yyyy-MM-dd').parse(question["timeframe"]);
                                    } catch (_) {}
                                  }
                                }
                              }
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(initial),
                                );
                                if (pickedTime != null) {
                                  final dt = DateTime(
                                    pickedDate.year, pickedDate.month, pickedDate.day,
                                    pickedTime.hour, pickedTime.minute,
                                  );
                                  question["timeframe"] = DateFormat('dd/MM/yyyy hh:mm a').format(dt);
                                  onRefresh();
                                }
                              }
                            },
                      child: InputDecorator(
                        decoration: AppFormStyles.inputDecoration(
                          suffixIcon: const Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          (question["timeframe"] ?? "").toString().isEmpty
                              ? ""
                              : question["timeframe"],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}