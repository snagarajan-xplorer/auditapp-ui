import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'dart:convert';

import '../../constants.dart';
import '../../controllers/usercontroller.dart';
import '../../models/screenarguments.dart';
import '../../responsive.dart';
import '../../services/api_service.dart';
import '../main/layoutscreen.dart';


class TemplateEditScreenV2 extends StatefulWidget {
  const TemplateEditScreenV2({super.key});

  @override
  State<TemplateEditScreenV2> createState() => _TemplateEditScreenV2State();
}

class _TemplateEditScreenV2State extends State<TemplateEditScreenV2> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final UserController _uc = Get.put(UserController());

  TextEditingController templateNameController = TextEditingController();

   String? selectedClientId;
  bool _isActive = true;

  // Data
  List<dynamic> _roles = [];
  List<dynamic> _clientList = [];

  // Selected brand IDs (multi-select)
  List<String> _selectedBrandIds = [];
  bool _allBrandsSelected = false;
  bool _brandSectionOpen = true;

  // State dropdown data
  // ignore: unused_field
  String? _selectedState;

  // Page argument
  ScreenArgument? _pageArgument;
  bool _isEditMode = false;
  Map<String, dynamic>? _editData;

  // ── helpers ──────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF505050),
      ),
      contentPadding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
      counterText: '',
      errorMaxLines: 3,
      hoverColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4DB6AC)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    if (_uc.userData.role == null) {
      _uc.loadInitData();
    }

    // Read arguments
    final args = ModalRoute.of(context)?.settings.arguments ?? Get.arguments;
    if (args is ScreenArgument) {
      _pageArgument = args;
      if (args.mode == "Edit" && args.editData != null) {
        _isEditMode = true;
        _editData = Map<String, dynamic>.from(args.editData!);
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
          _roles = res["data"];
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

  // ── section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF505050),
        ),
      ),
    );
  }

  // ── spacing helpers ───────────────────────────────────────────────────────
  Widget get _hSpace => SizedBox(
        width: Responsive.isDesktop(context) ? defaultPadding : 0,
        height: Responsive.isDesktop(context) ? 0 : defaultPadding,
      );

  // ── field builders ────────────────────────────────────────────────────────

  /// Row 1: Username | Email ID | Mobile No.
 
  Widget _fieldUsername() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Username'),
        FormBuilderTextField(
          name: 'name',
          style: Theme.of(context).textTheme.bodyMedium,
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: 'Please enter username',
          ),
          decoration: _inputDecoration(''),
        ),
      ],
    );
  }

  Widget _fieldCity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('City'),
        FormBuilderTextField(
          name: 'city',
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: _inputDecoration(''),
        ),
      ],
    );
  }

  /// Role dropdown
  Widget _fieldRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Role'),
        SizedBox(
          width: Responsive.isDesktop(context) ? 350 : double.infinity,
          child: FormBuilderDropdown<String>(
            name: 'role',
            items: _roles
                .map<DropdownMenuItem<String>>(
                  (r) => DropdownMenuItem(
                    value: r['roleid'].toString(),
                    child: Text(r['rolename'].toString()),
                  ),
                )
                .toList(),
            validator: FormBuilderValidators.required(
              errorText: 'Please select role',
            ),
            onChanged: (value) {
              // Handle visibility of brand based on role
              if (mounted) setState(() {});
            },
            decoration: _inputDecoration(''),
          ),
        ),
      ],
    );
  }

  /// Brand multi-select checkbox widget (custom)
  Widget _fieldBrand() {
    // Determine the current role: prefer the form field value, fall back to edit data
    String? selectedRole = _formKey.currentState?.fields['role']?.value;
    if (selectedRole == null && _isEditMode && _editData != null) {
      selectedRole = _editData!['role']?.toString();
    }
    // Hide brands for AD and JrA roles
    if (selectedRole == 'AD' || selectedRole == 'JrA') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Brand'),
        Container(
          width: Responsive.isDesktop(context)
              ? MediaQuery.of(context).size.width * 0.45
              : double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with "Select" label
              InkWell(
                onTap: () {
                  setState(() {
                    _brandSectionOpen = !_brandSectionOpen;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBrandIds.isEmpty
                            ? 'Select'
                            : _allBrandsSelected
                                ? 'All Brands'
                                : '${_selectedBrandIds.length} selected',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF535353),
                        ),
                      ),
                      Icon(
                        _brandSectionOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF535353),
                      ),
                    ],
                  ),
                ),
              ),
              if (_brandSectionOpen) ...[
                const Divider(height: 1, color: Color(0xFFC9C9C9)),
                // "All Brands" option
                _brandCheckboxTile(
                  label: 'All Brands',
                  isChecked: _allBrandsSelected,
                  onChanged: (checked) {
                    setState(() {
                      _allBrandsSelected = checked ?? false;
                      if (_allBrandsSelected) {
                        _selectedBrandIds = _clientList
                            .map((c) => c['clientid'].toString())
                            .toList();
                      } else {
                        _selectedBrandIds = [];
                      }
                    });
                  },
                ),
                // Individual brands
                ..._clientList.map((client) {
                  final id = client['clientid'].toString();
                  final name = client['clientname'].toString();
                  return _brandCheckboxTile(
                    label: name,
                    isChecked: _selectedBrandIds.contains(id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedBrandIds.add(id);
                        } else {
                          _selectedBrandIds.remove(id);
                        }
                        _allBrandsSelected = _clientList.isNotEmpty &&
                            _selectedBrandIds.length == _clientList.length;
                      });
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _brandCheckboxTile({
    required String label,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFC9C9C9))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: onChanged,
                activeColor: const Color(0xFF02B2EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF505050),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: Responsive.isDesktop(context) ? 400 : double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF535353),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
        onPressed: () {},
        child: Text(
          _isEditMode ? 'Update User' : 'Create New User',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Create Template',
      showBackbutton: true,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Template Name',
                        style: TextStyle(fontSize: 14, color: Color(0xFF505050))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: templateNameController,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: '',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4)),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Brand',
                        style: TextStyle(fontSize: 14, color: Color(0xFF505050))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedClientId,
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
                        disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
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
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF67AC5B),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Active',
                style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
              ),
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
                      if (res['message'] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'].toString())),
                        );
                      }
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
                  'Save Template',
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
