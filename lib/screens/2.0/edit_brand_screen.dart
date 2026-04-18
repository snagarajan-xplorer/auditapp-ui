import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/usercontroller.dart';
import '../../models/screenarguments.dart';
import '../../responsive.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/app_form_field.dart';

class EditBrandScreen extends StatefulWidget {
  const EditBrandScreen({super.key});

  @override
  State<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends State<EditBrandScreen> {
  late final UserController userController;

  // Form fields
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  PlatformFile? _logoFile;
  bool _isActive = true;
  bool _isCheckingStatus = false;

  bool _isEditMode = false;
  String? _editClientId;
  String? _existingLogoPath;

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoadingContacts = false;

  final TextEditingController _newContactNameController = TextEditingController();
  final TextEditingController _newMobileController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  String? _newEmailError;
  bool _isCheckingNewEmail = false;
  Timer? _newEmailDebounce;
  bool _showAddContactForm = false;

  @override
  void initState() {
    super.initState();
    userController = Get.find<UserController>();
    if (userController.userData.role == null) {
      userController.loadInitData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is ScreenArgument && args.editData != null) {
        _prefillForEdit(args.editData!);
        _loadContacts(args.editData!['clientid']?.toString());
      }
    });
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _clientNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _newContactNameController.dispose();
    _newMobileController.dispose();
    _newEmailController.dispose();
    _newEmailDebounce?.cancel();
    super.dispose();
  }

  void _loadContacts(String? clientid) {
    if (clientid == null) return;
    setState(() => _isLoadingContacts = true);
    userController.getClientContacts(context, clientid: clientid, callback: (data) {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
          _contacts = List.from(data).map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    });
  }

  void _checkNewEmail(String email) {
    _newEmailDebounce?.cancel();
    if (email.isEmpty) {
      setState(() { _newEmailError = null; _isCheckingNewEmail = false; });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() { _newEmailError = 'Please enter a valid email address'; _isCheckingNewEmail = false; });
      return;
    }
    setState(() => _isCheckingNewEmail = true);
    _newEmailDebounce = Timer(const Duration(milliseconds: 500), () {
      userController.checkClientEmail(context, email: email, callback: (exists, {String? message}) {
        if (mounted) {
          setState(() {
            _isCheckingNewEmail = false;
            _newEmailError = exists
                ? (message ?? 'Email already exists for another contact')
                : null;
          });
        }
      });
    });
  }

  void _submitNewContact() {
    if (_newContactNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact name is required')));
      return;
    }
    final email = _newEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email ID is required')));
      return;
    }
    if (_newEmailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_newEmailError!)));
      return;
    }
    final mobile = _newMobileController.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number')));
      return;
    }
    userController.addClientContact(context, data: {
      'clientid': _editClientId,
      'contactname': _newContactNameController.text.trim(),
      'contactmobile': mobile,
      'contactemail': email,
      'created_by': userController.userData.name ?? '',
    }, callback: (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added successfully'), backgroundColor: Colors.green),
      );
      _newContactNameController.clear();
      _newMobileController.clear();
      _newEmailController.clear();
      setState(() { _showAddContactForm = false; _newEmailError = null; });
      _loadContacts(_editClientId);
    });
  }

  void _loadBrands() {
    userController.getBrandList(context, callback: (data) {
      if (mounted) {
        setState(() {
        });
      }
    });
  }

  void _clearForm() {
    _brandNameController.clear();
    _clientNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    setState(() {
      _logoFile = null;
      _isEditMode = false;
      _editClientId = null;
      _existingLogoPath = null;
    });
  }

  void _prefillForEdit(Map<String, dynamic> row) {
    _brandNameController.text = row['clientname']?.toString() ?? '';
    _clientNameController.text = row['contactname']?.toString() ?? '';
    _mobileController.text = row['clientmobile']?.toString() ?? '';
    _emailController.text = row['clientemail']?.toString() ?? '';
    setState(() {
      _isEditMode = true;
      _editClientId = row['clientid']?.toString();
      _existingLogoPath = row['clientlogo']?.toString();
      _isActive = (row['status']?.toString() ?? 'A') == 'A';
      _logoFile = null;
    });
  }

  void _submit() {
    if (_brandNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Client name is required')));
      return;
    }

    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 10-digit mobile number')));
      return;
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    final Map<String, dynamic> extraData = {
      'contactname': _clientNameController.text.trim(),
      'clientmobile': mobile,
      'clientemail': email,
      'created_by': userController.userData.name ?? '',
      'status': _isActive ? 'A' : 'IA',
    };

    if (_isEditMode && _editClientId != null) {
      userController.updateBrand(
        context,
        clientid: _editClientId!,
        brandname: _brandNameController.text.trim(),
        logoBytes: _logoFile?.bytes,
        logoFilename: _logoFile?.name,
        data: extraData,
        callback: (res) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        },
      );
    } else {
      if (_logoFile != null) {
        userController.createBrand(
          context,
          brandname: _brandNameController.text.trim(),
          logoBytes: _logoFile!.bytes,
          logoFilename: _logoFile!.name,
          data: extraData,
          callback: (res) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Client created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _clearForm();
            _loadBrands();
          },
        );
      } else {
        userController.createBrandNoLogo(
          context,
          data: {
            'brandname': _brandNameController.text.trim(),
            ...extraData,
          },
          callback: (res) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Client created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _clearForm();
            _loadBrands();
          },
        );
      }
    }
  }

  Widget _buildCreateBrandSection() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Name
          SizedBox(
            width: double.infinity, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Client Name',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF505050))),
                const SizedBox(height: 8),
                TextField(
                  controller: _brandNameController,
                  decoration: AppFormStyles.inputDecoration(),
                  style: const TextStyle(height: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Upload Logo
          const Text('Upload Logo',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF505050))),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['png', 'jpg', 'jpeg'],
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      _logoFile = result.files.first;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02B2EB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 23, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Browse',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),

              // Show logo preview
              if (_logoFile != null)
                Container(
                  width: 150,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      _logoFile!.bytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else if (_existingLogoPath != null &&
                  _existingLogoPath!.isNotEmpty)
                Container(
                  width: 150,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      imgUrl(_existingLogoPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '* File supported .png, .jpg, .jpeg  and size maximum  w 700px X h 500px',
            style: TextStyle(fontSize: 12, color: Color(0xFF535353)),
          ),
          const SizedBox(height: 24),

          // Client Info
          const Text('Client Info',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF505050))),
          const SizedBox(height: 16),
          Responsive.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labeledField(label: 'Contact Name', controller: _clientNameController),
                    const SizedBox(height: 16),
                    _labeledField(label: 'Mobile No.', controller: _mobileController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _labeledField(label: 'Email ID', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _labeledField(label: 'Contact Name', controller: _clientNameController)),
                    const SizedBox(width: 20),
                    Expanded(child: _labeledField(label: 'Mobile No.', controller: _mobileController, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 20),
                    Expanded(child: _labeledField(label: 'Email ID', controller: _emailController, keyboardType: TextInputType.emailAddress)),
                  ],
                ),
          const SizedBox(height: 28),
          Row(
            children: [
              Transform.scale(
                scale: 1.3,
                child: Switch(
                  value: _isActive,
                  onChanged: _isCheckingStatus
                      ? null
                      : (value) {
                          if (!value && _editClientId != null) {
                            // Trying to deactivate – check all audits are done
                            setState(() => _isCheckingStatus = true);
                            userController.getClientStatus(context,
                                data: {
                                  'client_id': _editClientId,
                                  'status': 'IA',
                                },
                                callback: (res) {
                                  if (!mounted) return;
                                  setState(() => _isCheckingStatus = false);
                                  if (res['cont'] == true) {
                                    setState(() => _isActive = false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Cannot deactivate client'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                });
                          } else {
                            // Activating – allow directly
                            if (value && _editClientId != null) {
                              userController.getClientStatus(context,
                                  data: {
                                    'client_id': _editClientId,
                                    'status': 'A',
                                  },
                                  callback: (res) {
                                    if (!mounted) return;
                                    if (res['cont'] == true) {
                                      setState(() => _isActive = true);
                                    }
                                  });
                            } else {
                              setState(() => _isActive = value);
                            }
                          }
                        },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF67AC5B),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFBDBDBD),
                ),
              ),
              if (_isCheckingStatus)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                _isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 14,
                  color: _isActive ? const Color(0xFF67AC5B) : const Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
          // Submit button
          Center(
            child: SizedBox(
              width: 350,
              height: 44,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF535353),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _isEditMode ? 'Update Client' : 'Create Client',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AppLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: AppFormStyles.inputDecoration(),
        style: const TextStyle(height: 1.0),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  Widget _buildContactsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contacts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF505050))),
              if (!_showAddContactForm)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddContactForm = true),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Add Contact', style: TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02B2EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showAddContactForm) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF505050))),
                  const SizedBox(height: 12),
                  Responsive.isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeledField(label: 'Contact Name', controller: _newContactNameController),
                            const SizedBox(height: 12),
                            _labeledField(label: 'Mobile No.', controller: _newMobileController, keyboardType: TextInputType.phone),
                            const SizedBox(height: 12),
                            _buildNewEmailField(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _labeledField(label: 'Contact Name', controller: _newContactNameController)),
                            const SizedBox(width: 16),
                            Expanded(child: _labeledField(label: 'Mobile No.', controller: _newMobileController, keyboardType: TextInputType.phone)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNewEmailField()),
                          ],
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _submitNewContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF535353),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Save Contact', style: TextStyle(fontSize: 13, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          _newContactNameController.clear();
                          _newMobileController.clear();
                          _newEmailController.clear();
                          setState(() { _showAddContactForm = false; _newEmailError = null; });
                        },
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF2E77D0))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoadingContacts)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No contacts found', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            )
          else
            ..._contacts.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['contactname']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(c['contactemail']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(c['contactmobile']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildNewEmailField() {
    return AppLabeledField(
      label: 'Email ID',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: AppFormStyles.inputDecoration(
              suffixIcon: _isCheckingNewEmail
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _newEmailError != null
                      ? const Icon(Icons.error_outline, color: Colors.red, size: 20)
                      : _newEmailController.text.isNotEmpty
                          ? const Icon(Icons.check_circle_outline, color: Colors.green, size: 20)
                          : null,
            ),
            style: const TextStyle(height: 1.0),
            onChanged: _checkNewEmail,
          ),
          if (_newEmailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_newEmailError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Settings',
      showBackbutton: true,
      child: SingleChildScrollView(
         padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 50, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
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
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: const Text(
                'Edit Brand',
                style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF505050),
                    fontWeight: FontWeight.w600),
              ),
            ),
            _buildCreateBrandSection(),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
