import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/usercontroller.dart';
import '../../models/screenarguments.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';

class EditBrandScreen extends StatefulWidget {
  const EditBrandScreen({super.key});

  @override
  State<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends State<EditBrandScreen> {
  final UserController userController = Get.put(UserController());

  // Form fields
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  PlatformFile? _logoFile;
  bool _isActive = true;

  // Edit mode
  bool _isEditMode = false;
  String? _editClientId;
  String? _existingLogoPath;

  // State
  List<Map<String, dynamic>> _brandList = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
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
    setState(() => _isLoading = true);
    userController.getBrandList(context, callback: (data) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _brandList = List.from(data)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
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
          .showSnackBar(const SnackBar(content: Text('Brand name is required')));
      return;
    }

    final Map<String, dynamic> extraData = {
      'contactname': _clientNameController.text.trim(),
      'clientmobile': _mobileController.text.trim(),
      'clientemail': _emailController.text.trim(),
      'created_by': userController.userData.name ?? '',
      'status': _isActive ? 'A' : 'I',
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
                const Text('Brand Name',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF505050))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _brandNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFC9C9C9),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFC9C9C9),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFC9C9C9),
                          width: 1,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    style: const TextStyle(height: 1.0),
                  ),
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
                  width: 95,
                  height: 40,
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
                  width: 95,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      '$IMG_URL$_existingLogoPath',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Client Name',
                  controller: _clientNameController,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _labeledField(
                  label: 'Mobile No.',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _labeledField(
                  label: 'Email ID',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
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
                  _isEditMode ? 'Update Brand' : 'Create Brand',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF505050))),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Color(0xFFC9C9C9),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Color(0xFFC9C9C9),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Color(0xFFC9C9C9),
                  width: 1,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            style: const TextStyle(height: 1.0),
          ),
        )
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Settings',
      showBackbutton: false,
      child: SingleChildScrollView(
         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
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
                    fontWeight: FontWeight.w500),
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
