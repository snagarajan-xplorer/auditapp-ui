import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';

class AuditCompletedStep extends StatelessWidget {
  final dynamic auditObj;
  final VoidCallback onStartNewAudit;

  const AuditCompletedStep({
    super.key,
    required this.auditObj,
    required this.onStartNewAudit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: Colors.green.shade300),
          SizedBox(height: defaultPadding),
          const Text("Successfully Completed Audit",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF505050))),
          SizedBox(height: defaultPadding * 2),
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
              side: const BorderSide(color: Color(0xFF02B2EB)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: defaultPadding),
          ButtonComp(
            width: 230,
            color: const Color(0xFF02B2EB),
            label: "Start a new audit",
            onPressed: onStartNewAudit,
          ),
        ],
      ),
    );
  }
}
