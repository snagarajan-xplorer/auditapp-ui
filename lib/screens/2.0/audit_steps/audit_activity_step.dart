import 'dart:typed_data';
import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';

class AuditActivityStep extends StatelessWidget {
  final dynamic auditObj;
  final String answerMark;
  final String totalMark;
  final String totalPer;
  final bool isViewMode;
  final bool showAudit;
  final void Function(dynamic element, String answeredQuestion,
      String totalQuestion) onCategoryTap;
  final VoidCallback onFilePick;
  final void Function(dynamic imageElement) onFileRemove;

  const AuditActivityStep({
    super.key,
    required this.auditObj,
    required this.answerMark,
    required this.totalMark,
    required this.totalPer,
    required this.isViewMode,
    required this.showAudit,
    required this.onCategoryTap,
    required this.onFilePick,
    required this.onFileRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAudit) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rating summary table
          _buildRatingTable(context),
          SizedBox(height: defaultPadding),
          // Section title
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: const Text("Audit Activity",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87)),
            ),
          ),
          const SizedBox(height: 24),
          // Category cards grid
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 40,
            runSpacing: 40,
            children: auditObj["categorys"]
                .map<Widget>(
                    (element) => _buildCategoryCard(context, element))
                .toList(),
          ),
          SizedBox(height: defaultPadding),
          _buildEvidenceSection(context),
          SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  Widget _buildRatingTable(BuildContext context) {
    return BoxContainer(
      width: 580,
      height: 90,
      padding: 5,
      child: DataTableTheme(
        data: DataTableThemeData(
            dataRowMinHeight: 30,
            dataRowMaxHeight: 30,
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
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF505050))))),
            DataColumn(
                label: Center(
                    child: Text(
                        AppTranslations.of(context)!
                            .text("key_message_14"),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF505050))))),
            DataColumn(
                label: Center(
                    child: Text(
                        AppTranslations.of(context)!
                            .text("key_message_16"),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF505050))))),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Center(
                  child: Text(answerMark,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))))),
              DataCell(Center(
                  child: Text(totalMark,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505050))))),
              DataCell(Center(
                  child: SizedBox(
                      width: 50,
                      child: StatusComp(
                        status: "",
                        statusvalue: "$totalPer%",
                        percentage: int.tryParse(totalPer),
                      )))),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic element) {
    String totalQuestion = element["questions"].length.toString();
    List<dynamic> attendQuestion = element["questions"]
        .where((quest) =>
            quest["answer"].toString().trim().toString().isNotEmpty)
        .toList();
    int ansValue = 0;
    int totalValue = 0;
    for (var ele in attendQuestion) {
      if (ele["answer"] != "N/A") {
        String str = (ele["answer"] ?? "0");
        int d = int.tryParse(str) ?? 0;
        ansValue = ansValue + d;
        totalValue = totalValue + 4;
      }
    }
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
        attendQuestion.isEmpty ? "0" : attendQuestion.length.toString();

    // Determine button status
    String btnLabel = AppTranslations.of(context)!.text("key_start");
    Color btnColor = const Color(0xFF535353);
    // Calculate average rating per answered question
    String ratingStr = "";
    if (attendQuestion.isNotEmpty) {
      int ratingVal = (ansValue / attendQuestion.length).round();
      ratingStr = ratingVal.toString();
    }

    if (isViewMode) {
      btnLabel = "View";
      btnColor = const Color(0xFF29B6F6);
    } else if (answeredQuestion == totalQuestion &&
        answeredQuestion != "0") {
      btnLabel = "Completed";
      btnColor = const Color(0xFF67AC5B);
    } else if (int.parse(answeredQuestion) > 0) {
      btnLabel = "Pending";
      btnColor = const Color(0xFFF29500);
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
            Text(element["heading"] ?? "",
                style: const TextStyle(
                    color: Color(0xFF898989),
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 4),
            SizedBox(
              height: 45,
              child: Text(element["categoryname"],
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF505050)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            // Stats row 1: Average Score | %Secured
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        AppTranslations.of(context)!
                            .text("key_average"),
                        style: const TextStyle(
                            color: Color(0xFF898989), fontSize: 12)),
                    Row(
                      children: [
                        const Text(": ",
                            style: TextStyle(fontSize: 12)),
                        const Text("50%",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("%Secured",
                        style: TextStyle(
                            color: Color(0xFF898989), fontSize: 12)),
                    Row(
                      children: [
                        const Text(": ",
                            style: TextStyle(fontSize: 12)),
                        value.toString().trim().isEmpty
                            ? const Text("",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))
                            : SizedBox(
                                width: 50,
                                child: StatusComp(
                                  status: "",
                                  statusvalue: "$value%",
                                  percentage: int.tryParse(value),
                                )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Stats row 2: Questions | Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        AppTranslations.of(context)!
                            .text("key_question"),
                        style: const TextStyle(
                            color: Color(0xFF898989), fontSize: 12)),
                    Text(": $answeredQuestion/$totalQuestion",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rating",
                        style: TextStyle(
                            color: Color(0xFF898989), fontSize: 12)),
                    Text(": $ratingStr",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  onCategoryTap(
                      element, answeredQuestion, totalQuestion);
                },
                child: Text(btnLabel,
                    style: const TextStyle(
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

  Widget _buildEvidenceSection(BuildContext context) {
    List<dynamic> proofDocs = auditObj["proofdocuments"] ?? [];
    return BoxContainer(
      width: 760,
      height: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.of(context)!.text("key_attach_evidence"),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF505050)),
              ),
              if (!isViewMode)
                SizedBox(
                  width: 100,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: onFilePick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                        AppTranslations.of(context)!.text("key_btn_browse"),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (proofDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text("No evidence attached",
                    style: TextStyle(
                        color: Color(0xFF898989), fontSize: 14)),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: proofDocs
                  .map<Widget>(
                      (imgelement) => _buildAttachment(context, imgelement))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, dynamic imgelement) {
    bool isLocal = imgelement["_isLocal"] == true;
    bool isImage = true;
    String name = imgelement["image"].toString();
    var index = name.lastIndexOf(".");
    var ext = name.substring(index, name.length);
    String img = "assets/images/doc.png";
    if (ext.contains("doc")) {
      isImage = false;
      img = "assets/images/doc.png";
    } else if (ext.contains("xls")) {
      isImage = false;
      img = "assets/images/xls.png";
    } else if (ext.contains("pdf")) {
      isImage = false;
      img = "assets/images/pdf.png";
    } else if (ext.contains("ppt")) {
      isImage = false;
      img = "assets/images/ppt.png";
    }

    ImageProvider imageProvider;
    if (isLocal) {
      imageProvider = isImage
          ? MemoryImage(imgelement["_localBytes"] as Uint8List)
          : AssetImage(img);
    } else {
      imageProvider = isImage
          ? NetworkImage(IMG_URL + imgelement["image"])
          : AssetImage(img);
    }

    return Container(
      width: 140,
      height: 100,
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: InkWell(
              onTap: isLocal
                  ? null
                  : () {
                      launchUrl(Uri.parse(
                        IMG_URL + imgelement["image"].toString(),
                      ));
                    },
              child: Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover, image: imageProvider),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 1)),
              ),
            ),
          ),
          if (!isViewMode)
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: () {
                  onFileRemove(imgelement);
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
