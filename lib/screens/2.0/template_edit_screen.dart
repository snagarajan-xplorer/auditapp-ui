import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../../constants.dart';
import '../../controllers/usercontroller.dart';
import '../../models/screenarguments.dart';
import '../../services/api_service.dart';
import '../../widget/app_form_field.dart';
import '../main/layoutscreen.dart';


class TemplateEditScreenV2 extends StatefulWidget {
  const TemplateEditScreenV2({super.key});

  @override
  State<TemplateEditScreenV2> createState() => _TemplateEditScreenV2State();
}

class _TemplateEditScreenV2State extends State<TemplateEditScreenV2> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final UserController _uc;

  TextEditingController templateNameController = TextEditingController();

   String? selectedClientId;
  bool _isActive = true;
  bool _isAssignedToAudit = false;

  // Data
  List<dynamic> _clientList = [];

  // Page argument
  bool _isEditMode = false;
  Map<String, dynamic>? _editData;

  // ── helpers ──────────────────────────────────────────────────────────────

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _uc = Get.find<UserController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    if (_uc.userData.role == null) {
      _uc.loadInitData();
    }

    // Read arguments
    final args = ModalRoute.of(context)?.settings.arguments ?? Get.arguments;
    if (args is ScreenArgument) {
      if (args.mode == "Edit" && args.editData != null) {
        _isEditMode = true;
        _editData = Map<String, dynamic>.from(args.editData!);

        // Check if template is assigned to any active audit
        final templateId = _editData!['id'] ?? _editData!['template_id'];
        if (templateId != null) {
          _uc.getTempalteStatus(
            context,
            data: {
              'template_id': templateId.toString(),
              'status': 'IA',
            },
            callback: (res) {
              if (mounted) {
                setState(() {
                  // Template is assigned to audit if deactivation is blocked (cont == false)
                  _isAssignedToAudit = res['cont'] == false &&
                      ((res['pending_audits'] ?? 0) > 0);
                });
              }
            },
          );
        }
      }
    }

    // Load client list (brands)
    _uc.getClientList(
      context,
      data: {
        'role': _uc.userData.role,
        'client_id': _uc.userData.clientid,
      },
      callback: (clients) {
        _clientList = clients;
        if (mounted) setState(() {});

        // If edit mode, pre-fill form after clients are loaded
        if (_isEditMode && _editData != null) {
          _prefillEditData();
        }
      },
    );

    // Load roles directly via API (GET /role)
    _loadRoles();
  }

  void _loadRoles() {
    APIService(context).getData("role", true, loader: false).then((resvalue) {
      if (resvalue.length != 5) {
        Map<String, dynamic> res = jsonDecode(resvalue);
        if (!res.containsKey("type") && res.containsKey("data")) {
          if (mounted) setState(() {});
        }
      }
    });
  }

  void _prefillEditData() {
    if (_editData == null) return;

    Future.delayed(const Duration(milliseconds: 400), () {
      // Pre-fill template name
      if (_editData!['templatename'] != null) {
        templateNameController.text = _editData!['templatename'].toString();
      }

      // Pre-fill selected brand/client
      final clientId = _editData!['client_id'] ?? _editData!['clientid'];
      if (clientId != null) {
        selectedClientId = clientId.toString();
      }

      // Pre-fill active status
      if (_editData!['status'] != null) {
        _isActive = _editData!['status'].toString() == 'A';
      }

      if (mounted) setState(() {});
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Settings',
      showBackbutton: true,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← Back link
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: Color(0xFF02B2EB)),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF02B2EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
               'Edit Template',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF505050),
                ),
              ),
              const SizedBox(height: 24),

              // Form
              FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: defaultPadding),
                    _buildCreateTemplateSection(),
                    const SizedBox(height: defaultPadding * 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: AppLabeledField(
                  label: 'Template Name',
                  child: TextField(
                    controller: templateNameController,
                    readOnly: true,
                    enabled: false,
                    decoration: AppFormStyles.inputDecoration().copyWith(
                      fillColor: const Color(0xFFEEEEEE),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                child: AppLabeledField(
                  label: 'Client',
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedClientId,
                    isExpanded: true,
                    items: _clientList
                        .map<DropdownMenuItem<String>>((client) =>
                            DropdownMenuItem(
                              value: client['clientid']?.toString(),
                              child: Text(
                                  client['clientname']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: null,
                    decoration: AppFormStyles.inputDecoration().copyWith(
                      fillColor: const Color(0xFFEEEEEE),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active toggle
          Row(
            children: [
              Transform.scale(
                scale: 1.3,
                child: Switch(
                  value: _isActive,
                  onChanged: (value) {
                    if (!value && _isAssignedToAudit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cannot deactivate. Template has pending audit(s) that are not yet completed.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF67AC5B),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isActive ? 'Active' : 'Inactive',
                style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
              ),
              if (!_isActive && _isAssignedToAudit) ...[
                const SizedBox(width: 16),
                Text(
                  '*Template has pending audit(s). Complete all audits to deactivate.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Save Template button
          Center(
            child: SizedBox(
              width: 350,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  final templateId = _editData?['id'] ?? _editData?['template_id'];
                  if (templateId == null) return;
                  _uc.getTempalteStatus(
                    context,
                    data: {
                      'template_id': templateId.toString(),
                      'status': _isActive ? 'A' : 'IA',
                    },
                    callback: (res) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message']?.toString() ?? 'Template updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (mounted){
                        Navigator.pop(context, true);
                      }
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF535353),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Update Template',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
