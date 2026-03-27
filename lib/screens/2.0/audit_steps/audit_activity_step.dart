import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/statuscomp.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../responsive.dart';

class AuditActivityStep extends StatelessWidget {
  final dynamic auditObj;
  final String answerMark;
  final String totalMark;
  final String totalPer;
  final bool isViewMode;
  final bool showAudit;
  final void Function(dynamic element, String answeredQuestion,
      String totalQuestion) onCategoryTap;

  const AuditActivityStep({
    super.key,
    required this.auditObj,
    required this.answerMark,
    required this.totalMark,
    required this.totalPer,
    required this.isViewMode,
    required this.showAudit,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAudit) return const SizedBox();
    final isMobile = Responsive.isMobile(context);
    final horizontalPad = isMobile ? 16.0 : 48.0;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
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
        ],
      ),
    );
  }

  Widget _buildRatingTable(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final horizontalPad = isMobile ? 16.0 : 48.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final tableWidth = screenWidth < 650 ? screenWidth - (horizontalPad * 2) : 580.0;
    return BoxContainer(
      width: tableWidth,
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
          minWidth: tableWidth,
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

    int totalQ = element["questions"].length as int;
    String avgStr = "";
    if (totalQ > 0) {
      avgStr = "$ansValue/${totalQ * 4}";
    }

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
                        Text(avgStr,
                            style: const TextStyle(
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

}
