import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import '../../../constants.dart';

class SubmitReviewStep extends StatelessWidget {
  final dynamic auditObj;
  final bool isViewMode;
  final double wdt;
  final bool reviewAcknowledged;
  final bool acknowlodgeImage;
  final Uint8List? imageBytes;
  final String userName;
  final ValueChanged<bool> onAcknowledgeChanged;
  final VoidCallback onBrowse;
  final VoidCallback onSubmit;

  const SubmitReviewStep({
    super.key,
    required this.auditObj,
    required this.isViewMode,
    required this.wdt,
    required this.reviewAcknowledged,
    required this.acknowlodgeImage,
    required this.imageBytes,
    required this.userName,
    required this.onAcknowledgeChanged,
    required this.onBrowse,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    String companyName = auditObj["companyname"] ?? "";
    String auditId = auditObj["audit_no"] ?? "";
    String auditDate = "";
    String auditTime = "";
    String assignedBy = "";
    String reviewSubmitted = "";

    try {
      auditDate = Jiffy.parse(auditObj["start_date"])
          .format(pattern: "dd/MM/yyyy");
    } catch (_) {}
    try {
      auditTime = Jiffy.parse(auditObj["start_time"])
          .format(pattern: "hh:mm a");
    } catch (_) {}
    assignedBy =
        auditObj["assigned_by"] ?? auditObj["auditorname"] ?? "";
    reviewSubmitted = Jiffy.now().format(pattern: "dd/MM/yyyy");

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 80),
          child: SizedBox(
            width: wdt,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Submit Review" heading above the card
                Padding(
                  padding: EdgeInsets.only(
                      top: defaultPadding, bottom: defaultPadding),
                  child: const Text("Submit Review",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87)),
                ),
                // White card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company name
                      Text(companyName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                      SizedBox(height: defaultPadding * 1.5),
                      // Info rows
                      _infoRow("Audit ID", auditId, "Audit Date",
                          auditDate),
                      SizedBox(height: defaultPadding * 1.5),
                      _infoRow("Audit assigned by", assignedBy,
                          "Audit time", auditTime),
                      SizedBox(height: defaultPadding * 1.5),
                      _infoRow("Auditor", userName,
                          "Review Submitted", reviewSubmitted),
                      SizedBox(height: defaultPadding * 2),
                      // Acknowledgment checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value:
                                isViewMode ? true : reviewAcknowledged,
                            activeColor: const Color(0xFF505050),
                            onChanged: isViewMode
                                ? null
                                : (val) {
                                    onAcknowledgeChanged(
                                        val ?? false);
                                  },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: const Text(
                                "I acknowledge the audit's conclusion, with all activities performed as per established protocol",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: defaultPadding),
                      // Proof of location text
                      Text("Proof of location is included.",
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700)),
                      SizedBox(height: defaultPadding),
                      // Browse button + image preview
                      if (!isViewMode)
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              height: buttonHeight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF02B2EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: onBrowse,
                                child: const Text("Browse",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (acknowlodgeImage &&
                                imageBytes != null)
                              Container(
                                width: 150,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: Image.memory(imageBytes!,
                                      fit: BoxFit.cover),
                                ),
                              ),
                          ],
                        ),
                      SizedBox(height: defaultPadding * 2),
                      // Submit button (hidden in view mode)
                      if (!isViewMode)
                        Center(
                          child: ButtonComp(
                            width: 300,
                            label: "Submit to Review",
                            onPressed: onSubmit,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
                  style: const TextStyle(
                      color: Color(0xFF898989), fontSize: 16)),
              const SizedBox(height: 4),
              Text(value1,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF505050))),
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
              const SizedBox(height: 4),
              Text(value2,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
