import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';

class PublishedStep extends StatelessWidget {
  final dynamic auditObj;
  final bool isViewMode;
  final double wdt;
  final List<dynamic> clientUsers;
  final String? selectedClientEmail;
  final bool publishReviewed;
  final ValueChanged<String?> onClientEmailChanged;
  final ValueChanged<bool> onReviewedChanged;
  final VoidCallback onPublish;

  const PublishedStep({
    super.key,
    required this.auditObj,
    required this.isViewMode,
    required this.wdt,
    required this.clientUsers,
    required this.selectedClientEmail,
    required this.publishReviewed,
    required this.onClientEmailChanged,
    required this.onReviewedChanged,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    String companyName = auditObj["companyname"] ?? "";
    bool isAlreadyPublished =
        (auditObj["status"] ?? "").toString() == "P";

    return SingleChildScrollView(
      child: Center(
        child: BoxContainer(
          width: wdt,
          height: null,
          isBGTransparent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: defaultPadding),
              Text(companyName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF505050))),
              SizedBox(height: defaultPadding),
              // Download Report button
              OutlinedButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse(
                    "${API_URL}exportControl?type=1&id=${auditObj["reporturl"] ?? ""}",
                  ));
                },
                label: const Text("Download Report",
                    style: TextStyle(color: Color(0xFF02B2EB))),
                icon: const Icon(Icons.download,
                    color: Color(0xFF02B2EB)),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: Color(0xFF02B2EB)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: defaultPadding * 2),
              // Select Client Mail
              const Text("Select Client Mail Id",
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF505050))),
              const SizedBox(height: 8),
              SizedBox(
                width: 340,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedClientEmail,
                  items: clientUsers
                      .map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user["email"],
                      child: Text(user["email"] ?? ""),
                    );
                  }).toList(),
                  onChanged: isAlreadyPublished
                      ? null
                      : (val) {
                          onClientEmailChanged(val);
                        },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hoverColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                            color: Colors.grey.shade400)),
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
                    activeColor: const Color(0xFF67AC5B),
                    onChanged: isAlreadyPublished
                        ? null
                        : (val) {
                            onReviewedChanged(val ?? false);
                          },
                  ),
                  const Text(
                      "I'm reviewed the audit's conclusion, with all activities.",
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF505050))),
                ],
              ),
              SizedBox(height: defaultPadding * 2),
              // Published status badge
              if (isAlreadyPublished)
                Padding(
                  padding:
                      EdgeInsets.only(bottom: defaultPadding),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text("Audit Published Successfully",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ],
                  ),
                ),
              // Publish button
              if (!isAlreadyPublished)
                ButtonComp(
                  width: 300,
                  color: const Color(0xFF6FAF4E),
                  label: "I'm Reviewed & Published report",
                  onPressed: onPublish,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
