import 'dart:typed_data';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/app_form_field.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
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
    required this.onQuestionIndexTap,
    required this.onPrevious,
    required this.onNext,
    required this.onScoreTap,
    required this.onFilePick,
    required this.onFileRemove,
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
                maxLength: 500,
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
                maxLength: 500,
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
                                  initial = DateFormat('dd/MM/yyyy').parse(question["timeframe"]);
                                } catch (_) {
                                  try {
                                    initial = DateFormat('yyyy-MM-dd').parse(question["timeframe"]);
                                  } catch (_) {}
                                }
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                question["timeframe"] = DateFormat('dd/MM/yyyy').format(picked);
                                onRefresh();
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
            const SizedBox(height: 20),
            // Attach Audit Evidence
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppTranslations.of(context)!
                      .text("key_attach_evidence"),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF505050)),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isViewMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 100,
                      height: buttonHeight,
                      child: ElevatedButton(
                          onPressed: () {
                            onFilePick(question);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                              AppTranslations.of(context)!
                                  .text("key_btn_browse"),
                              style: const TextStyle(
                                  color: Colors.white))),
                    ),
                  ),
                Flexible(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (question["proofdocuments"] as List? ?? [])
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
    final Uint8List? localBytes = imgelement["_localBytes"] as Uint8List?;

    Widget imageWidget;
    if (localBytes != null && image) {
      imageWidget = Image.memory(
        localBytes,
        fit: BoxFit.cover,
        width: 140,
        height: 100,
        errorBuilder: (_, __, ___) => const _AttachmentPlaceholder(icon: Icons.broken_image),
      );
    } else if (image) {
      imageWidget = Image.network(
        imgUrl(imgelement["image"].toString()),
        fit: BoxFit.cover,
        width: 140,
        height: 100,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const _AttachmentPlaceholder(icon: Icons.hourglass_top),
        errorBuilder: (_, __, ___) => const _AttachmentPlaceholder(icon: Icons.broken_image),
      );
    } else {
      imageWidget = Image.asset(img, fit: BoxFit.contain, width: 60, height: 60);
    }

    return Container(
      width: 140,
      height: 100,
      margin: const EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () {
                final String? serverPath = imgelement["id"] != null
                    ? imgelement["image"].toString()
                    : null;
                if (serverPath != null) {
                  launchUrl(Uri.parse(imgUrl(serverPath)));
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageWidget,
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
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentPlaceholder extends StatelessWidget {
  final IconData icon;
  const _AttachmentPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 100,
      color: const Color(0xFFF5F5F5),
      child: Center(child: Icon(icon, size: 36, color: const Color(0xFFBDBDBD))),
    );
  }
}
