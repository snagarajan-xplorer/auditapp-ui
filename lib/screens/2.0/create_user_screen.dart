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
import '../../widget/app_form_field.dart';
import '../main/layoutscreen.dart';


class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final UserController _uc;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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

  // Active/Inactive status
  bool _isActive = true;
  bool _isAssignedToAudit = false;
  bool _hasActiveAudits = false;
  int _activeAuditCount = 0;
  int _completedAuditCount = 0;

  // Indian states list for the State dropdown
  static const List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

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
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ScreenArgument) {
      _pageArgument = args;
      if (args.mode == "Edit" && args.editData != null) {
        _isEditMode = true;
        _editData = Map<String, dynamic>.from(args.editData!);
        // Set initial active status from edit data
        _isActive = (_editData!['status'] ?? 'A') != 'IA';

        // Check if user is assigned to any audit
        if (_editData!['id'] != null) {
          _uc.checkUserAuditAssignment(
            context,
            userId: int.tryParse(_editData!['id'].toString()) ?? 0,
            callback: (assigned, auditCount, hasActiveAudits, activeAuditCount, completedAuditCount) {
              if (mounted) {
                setState(() {
                  _isAssignedToAudit = assigned;
                  _hasActiveAudits = hasActiveAudits;
                  _activeAuditCount = activeAuditCount;
                  _completedAuditCount = completedAuditCount;
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

          // If edit mode, pre-fill form
          if (_isEditMode && _editData != null) {
            _prefillEditData();
          }
        }
      }
    });
  }

  void _prefillEditData() {
    if (_editData == null) return;

    Future.delayed(const Duration(milliseconds: 400), () {
      final patch = <String, dynamic>{};

      if (_editData!['name'] != null) patch['name'] = _editData!['name'];
      if (_editData!['email'] != null) patch['email'] = _editData!['email'];
      if (_editData!['mobile'] != null) {
        patch['mobile'] = _editData!['mobile'].toString();
      }
      if (_editData!['joiningdate'] != null &&
          _editData!['joiningdate'].toString().isNotEmpty) {
        try {
          patch['joiningdate'] =
              Jiffy.parse(_editData!['joiningdate'].toString()).dateTime;
        } catch (_) {}
      }
      if (_editData!['state'] != null &&
          _editData!['state'].toString().trim().isNotEmpty) {
        _selectedState = _editData!['state'];
        patch['state'] = _editData!['state'];
      }
      if (_editData!['city'] != null &&
          _editData!['city'].toString().trim().isNotEmpty) {
        patch['city'] = _editData!['city'];
      }
      if (_editData!['role'] != null) patch['role'] = _editData!['role'];

      // Handle client/brand selection
      if (_editData!['client'] != null) {
        List<String> ids = [];
        if (_editData!['client'] is List) {
          ids = (_editData!['client'] as List)
              .map((e) => e.toString())
              .toList();
        } else if (_editData!['client'] is String) {
          final str = _editData!['client'].toString().trim();
          if (str.isNotEmpty && str != '0') {
            ids = str.split(',').map((e) => e.trim()).toList();
          }
        }
        _selectedBrandIds = ids;
        _allBrandsSelected =
            _clientList.isNotEmpty && ids.length == _clientList.length;
      }

      _formKey.currentState?.patchValue(patch);
      if (mounted) setState(() {});
    });
  }

  // ── section label ─────────────────────────────────────────────────────────


  // ── spacing helpers ───────────────────────────────────────────────────────
  Widget get _hSpace => SizedBox(
        width: Responsive.isDesktop(context) ? defaultPadding : 0,
        height: Responsive.isDesktop(context) ? 0 : defaultPadding,
      );

  // ── field builders ────────────────────────────────────────────────────────

  /// Row 1: Username | Email ID | Mobile No.
  Widget _rowUsernameEmailMobile() {
    return Responsive.isDesktop(context)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _fieldUsername()),
              _hSpace,
              Expanded(child: _fieldEmail()),
              _hSpace,
              Expanded(child: _fieldMobile()),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fieldUsername(),
              const SizedBox(height: defaultPadding),
              _fieldEmail(),
              const SizedBox(height: defaultPadding),
              _fieldMobile(),
            ],
          );
  }

  /// Row 2: Joining Date | State | City
  Widget _rowDateStateCity() {
    return Responsive.isDesktop(context)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _fieldJoiningDate()),
              _hSpace,
              Expanded(child: _fieldState()),
              _hSpace,
              Expanded(child: _fieldCity()),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fieldJoiningDate(),
              const SizedBox(height: defaultPadding),
              _fieldState(),
              const SizedBox(height: defaultPadding),
              _fieldCity(),
            ],
          );
  }

  Widget _fieldUsername() {
    return AppLabeledField(
      label: 'Username',
      child: FormBuilderTextField(
        name: 'name',
        style: Theme.of(context).textTheme.bodyMedium,
        textCapitalization: TextCapitalization.words,
        validator: FormBuilderValidators.required(
          errorText: 'Please enter username',
        ),
        decoration: AppFormStyles.inputDecoration(),
      ),
    );
  }

  Widget _fieldEmail() {
    return AppLabeledField(
      label: 'Email ID',
      child: FormBuilderTextField(
        name: 'email',
        style: Theme.of(context).textTheme.bodyMedium,
        keyboardType: TextInputType.emailAddress,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'Please enter email'),
          FormBuilderValidators.email(errorText: 'Please enter valid email'),
        ]),
        decoration: AppFormStyles.inputDecoration(),
      ),
    );
  }

  Widget _fieldMobile() {
    return AppLabeledField(
      label: 'Mobile No.',
      child: FormBuilderTextField(
        name: 'mobile',
        style: Theme.of(context).textTheme.bodyMedium,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: FormBuilderValidators.required(
          errorText: 'Please enter mobile number',
        ),
        decoration: AppFormStyles.inputDecoration(),
      ),
    );
  }

  Widget _fieldJoiningDate() {
    return AppLabeledField(
      label: 'Joining Date',
      child: FormBuilderDateTimePicker(
        name: 'joiningdate',
        inputType: InputType.date,
        style: Theme.of(context).textTheme.bodyMedium,
        firstDate: Jiffy.now().subtract(years: 10).dateTime,
        lastDate: Jiffy.now().add(years: 1).dateTime,
        decoration: AppFormStyles.inputDecoration(
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
      ),
    );
  }

  Widget _fieldState() {
    return AppLabeledField(
      label: 'State',
      child: FormBuilderDropdown<String>(
        name: 'state',
        items: _indianStates
            .map<DropdownMenuItem<String>>(
              (s) => DropdownMenuItem(value: s, child: Text(s)),
            )
            .toList(),
        onChanged: (value) {
          _selectedState = value;
          // Reset city when state changes
          _formKey.currentState?.fields['city']?.didChange(null);
          if (mounted) setState(() {});
        },
        decoration: AppFormStyles.inputDecoration(),
      ),
    );
  }

  Widget _fieldCity() {
    return AppLabeledField(
      label: 'City',
      child: FormBuilderTextField(
        name: 'city',
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: AppFormStyles.inputDecoration(),
      ),
    );
  }

  /// Role dropdown
  Widget _fieldRole() {
    return SizedBox(
      width: Responsive.isDesktop(context) ? 350 : double.infinity,
      child: AppLabeledField(
        label: 'Role',
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
          decoration: AppFormStyles.inputDecoration(),
        ),
      ),
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
        AppFormStyles.fieldLabel('Brand'),
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

  /// Active/Inactive switch (only shown in edit mode)
  Widget _fieldActiveSwitch() {
    if (!_isEditMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _isActive,
              onChanged: (value) {
                // Only prevent deactivation if user has active (non-completed) audits
                if (!value && _hasActiveAudits) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot deactivate this user. The user is assigned to $_activeAuditCount active audit(s) (In-Progress or Upcoming).',
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
              activeThumbColor: Colors.green,
              activeTrackColor: Colors.green.shade200,
            ),
            const SizedBox(width: 8),
            Text(
              _isActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF505050),
              ),
            ),
            if (_isAssignedToAudit && _hasActiveAudits) ...[
              const SizedBox(width: 16),
              Text(
                '*User has $_activeAuditCount active audit(s). Cannot deactivate.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else if (_isAssignedToAudit && !_hasActiveAudits) ...[
              const SizedBox(width: 16),
              Text(
                'User has $_completedAuditCount completed audit(s) only. Can be deactivated.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

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
        onPressed: _onCreateUser,
        child: Text(
          _isEditMode ? 'Save  Profaids User' : 'Create New User',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── form submit ───────────────────────────────────────────────────────────
  void _onCreateUser() {
    if (!_formKey.currentState!.saveAndValidate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
    });

    final formData = Map<String, dynamic>.from(_formKey.currentState!.value);

    // Handle joining date
    if (formData['joiningdate'] != null && formData['joiningdate'] is DateTime) {
      formData['joiningdate'] =
          (formData['joiningdate'] as DateTime).toIso8601String();
    } else {
      formData['joiningdate'] =
          Jiffy.now().dateTime.toIso8601String();
    }

    // Handle brand/client
    final selectedRole = formData['role'];
    if (selectedRole == 'AD' || selectedRole == 'JrA') {
      formData['client'] = '0';
      formData['parentid'] = 0;
    } else if (selectedRole == 'SrA') {
      formData['parentid'] = 0;
      formData['client'] = _selectedBrandIds.join(', ');
    } else {
      formData['client'] = _selectedBrandIds.join(', ');
      formData['parentid'] = 0;
    }

    // Set status based on switch (edit mode) or default active (create mode)
    formData['status'] = _isEditMode ? (_isActive ? 'A' : 'IA') : 'A';

    // Set defaults for optional fields
    formData.putIfAbsent('pincode', () => ' ');
    formData.putIfAbsent('address', () => ' ');
    formData.putIfAbsent('district', () => ' ');
    formData['state'] = formData['state'] ?? ' ';
    formData['city'] = formData['city'] ?? ' ';

    // If edit mode, include id
    if (_isEditMode && _editData != null && _editData!['id'] != null) {
      formData['id'] = _editData!['id'];
    }

    _uc.register(context, data: formData, callback: (res) {
      // Navigate back to user list
      final arg = _pageArgument ??
          ScreenArgument(argument: ArgumentData.USER, mapData: {});
      Navigator.pushNamed(context, '/user', arguments: arg);
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
                        fontSize: 16,
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
                _isEditMode ? 'Edit Profaids Users' : 'Create Profaids Users',
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
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Username | Email ID | Mobile No.
                    _rowUsernameEmailMobile(),
                    const SizedBox(height: defaultPadding),

                    // Row 2: Joining Date | State | City
                    _rowDateStateCity(),
                    const SizedBox(height: defaultPadding * 1.5),

                    // Role
                    _fieldRole(),
                    const SizedBox(height: defaultPadding * 1.5),

                    // Brand
                    _fieldBrand(),
                    const SizedBox(height: defaultPadding * 1.5),

                    // Active/Inactive switch (edit mode only)
                    _fieldActiveSwitch(),
                    const SizedBox(height: defaultPadding * 2),

                    // Submit button
                    Center(child: _buildSubmitButton()),
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
}
