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

  // Edit mode
  bool _isEditMode = false;
  String? _editClientId;
  String? _existingLogoPath;

  // State

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
      }
    });
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _clientNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
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

    final Map<String, dynamic> extraData = {
      'contactname': _clientNameController.text.trim(),
      'clientmobile': _mobileController.text.trim(),
      'clientemail': _emailController.text.trim(),
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
