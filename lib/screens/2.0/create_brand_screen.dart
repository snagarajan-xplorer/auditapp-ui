import 'dart:async';
import 'package:audit_app/models/screenarguments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/usercontroller.dart';
import '../../responsive.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/app_form_field.dart';
import '../../widget/reusable_table.dart';

class CreateBrandScreen extends StatefulWidget {
  const CreateBrandScreen({super.key});

  @override
  State<CreateBrandScreen> createState() => _CreateBrandScreenState();
}

class _CreateBrandScreenState extends State<CreateBrandScreen> {
  late final UserController userController;

  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _brandNameFocusNode = FocusNode();
  final GlobalKey _brandFieldKey = GlobalKey();

  PlatformFile? _logoFile;

  bool _isEditMode = false;
  String? _editClientId;
  String? _existingLogoPath;

  bool _isAddContactMode = false;

  String? _emailError;
  bool _isCheckingEmail = false;
  Timer? _emailDebounce;

  List<Map<String, dynamic>> _brandList = [];
  List<Map<String, dynamic>> _brandContactRows = [];
  bool _isLoading = false;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    userController = Get.find<UserController>();
    if (userController.userData.role == null) {
      userController.loadInitData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBrands());
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _clientNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _brandNameFocusNode.dispose();
    _emailDebounce?.cancel();
    super.dispose();
  }

  void _loadBrands() {
    setState(() => _isLoading = true);
    userController.getBrandList(context, callback: (data) {
      if (mounted) {
        final List<Map<String, dynamic>> uniqueBrands = [];
        final List<Map<String, dynamic>> flatList = [];
        for (final e in data) {
          final brand = Map<String, dynamic>.from(e);
          uniqueBrands.add(brand);
          final contacts = (brand['contacts'] as List?) ?? [];
          if (contacts.isEmpty) {
            flatList.add(brand);
          } else {
            for (final c in contacts) {
              final contact = Map<String, dynamic>.from(c);
              flatList.add({
                ...brand,
                'contactname': contact['contactname'] ?? '',
                'clientmobile': contact['contactmobile'] ?? '',
                'clientemail': contact['contactemail'] ?? '',
                'contact_id': contact['id'],
              });
            }
          }
        }
        setState(() {
          _isLoading = false;
          _brandList = uniqueBrands;
          _brandContactRows = flatList;
        });
      }
    });
  }

  void _clearForm() {
    _brandNameFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _brandNameController.clear();
      _clientNameController.clear();
      _mobileController.clear();
      _emailController.clear();
      setState(() {
        _logoFile = null;
        _isEditMode = false;
        _editClientId = null;
        _existingLogoPath = null;
        _isAddContactMode = false;
        _editClientId = null;
        _emailError = null;
        _isCheckingEmail = false;
      });
    });
  }

  void _onBrandSelected(Map<String, dynamic> brand) {
    _brandNameFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isAddContactMode = true;
        _editClientId = brand['clientid']?.toString();
        _brandNameController.text = brand['clientname']?.toString() ?? '';
      });
    });
  }

  void _exitAddContactMode() {
    _brandNameFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _brandNameController.clear();
      _clientNameController.clear();
      _mobileController.clear();
      _emailController.clear();
      setState(() {
        _isAddContactMode = false;
        _editClientId = null;
        _emailError = null;
      });
    });
  }

  void _checkEmail(String email) {
    _emailDebounce?.cancel();
    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isCheckingEmail = false;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        _isCheckingEmail = false;
      });
      return;
    }
    setState(() => _isCheckingEmail = true);
    _emailDebounce = Timer(const Duration(milliseconds: 500), () {
      userController.checkClientEmail(context, email: email, callback: (exists, {String? message}) {
        if (mounted) {
          setState(() {
            _isCheckingEmail = false;
            _emailError = exists
                ? (message ?? 'Email already exists for another contact')
                : null;
          });
        }
      });
    });
  }

  void _submit() {
    if (!_isAddContactMode && _brandNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Client name is required')));
      return;
    }

    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contact name is required')));
      return;
    }

    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 10-digit mobile number')));
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email ID is required')));
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_emailError!)));
      return;
    }

    if (_isAddContactMode && _editClientId != null) {
      userController.addClientContact(
        context,
        data: {
          'clientid': _editClientId,
          'contactname': _clientNameController.text.trim(),
          'contactmobile': mobile,
          'contactemail': email,
          'created_by': userController.userData.name ?? '',
        },
        callback: (res) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _clearForm();
          _loadBrands();
        },
      );
      return;
    }

    final Map<String, dynamic> extraData = {
      'contactname': _clientNameController.text.trim(),
      'clientmobile': mobile,
      'clientemail': email,
      'created_by': userController.userData.name ?? '',
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
          _clearForm();
          _loadBrands();
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

  // ── Column definitions ─────────────────────────────────────────────────

  List<TableColumnDef> get _brandColumns => [
        TableColumnDef(
          label: 'No.',
          flex: 1,
          cellBuilder: (row, index) {
            final pageIndex = (_currentPage - 1) * _pageSize + index + 1;
            return Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFC9C9C9), width: 0.8),
                ),
              ),
              child: Text(
                pageIndex.toString().padLeft(3, '0'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF505050)),
              ),
            );
          },
        ),
        TableColumnDef(
          label: 'Client Logo',
          flex: 2,
          cellBuilder: (row, _) {
            final logoPath = row['clientlogo']?.toString() ?? '';
            return Container(
              height: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFC9C9C9), width: 0.8),
                ),
              ),
              child: logoPath.isNotEmpty
                  ? Image.network(
                      imgUrl(logoPath),
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported,
                              size: 28, color: Color(0xFFBBBBBB)),
                    )
                  : const Icon(Icons.image_not_supported,
                      size: 28, color: Color(0xFFBBBBBB)),
            );
          },
        ),
        TableColumnDef(label: 'Client Name', flex: 2, key: 'clientname'),
        TableColumnDef(
          label: 'Contact Name',
          flex: 2,
          key: 'contactname',
        ),
        TableColumnDef(label: 'Mobile', flex: 2, key: 'clientmobile'),
        TableColumnDef(label: 'Email', flex: 3, key: 'clientemail'),
        TableColumnDef(label: 'Client created by', flex: 2, key: 'created_by'),
        TableColumnDef(
          label: 'Status',
          flex: 2,
          cellBuilder: (row, _) {
            final s = row['status']?.toString() ?? '';
            return statusBadgeCell(
              label: s == 'A' ? 'Active' : 'In Active',
              color: s == 'A' ? 'green' : 'red',
            );
          },
        ),
        TableColumnDef(
          label: 'Action',
          flex: 2,
          isLast: true,
          cellBuilder: (row, _) {
            return Container(
              height: double.infinity,
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: SizedBox(
                height: 33,
                child: ElevatedButton.icon(
                  onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/editbrand',
                            arguments: ScreenArgument(mode: 'Edit', editData: row),
                          );
                          if (result == true) {
                            _loadBrands();
                          }
                        },
                  icon: const Icon(Icons.edit,
                      size: 12, color: Colors.white),
                  label: const Text('Edit',
                      style:
                          TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E77D0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    elevation: 0,
                  ),
                ),
              ),
            );
          },
        ),
      ];

  // ── Create Brand Form ──────────────────────────────────────────────────

  Widget _buildCreateBrandSection() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Client Name',
                    style: TextStyle(fontSize: 14, color: Color(0xFF505050))),
                const SizedBox(height: 8),
                RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _brandNameController,
                  focusNode: _brandNameFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.length < 3) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    if (_isAddContactMode) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return _brandList.where((b) =>
                        (b['clientname']?.toString() ?? '').toLowerCase().contains(query));
                  },
                  displayStringForOption: (option) => option['clientname']?.toString() ?? '',
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      key: _brandFieldKey,
                      controller: controller,
                      focusNode: focusNode,
                      readOnly: _isAddContactMode,
                      decoration: AppFormStyles.inputDecoration(
                        hintText: 'Type to search existing clients or enter new name',
                        suffixIcon: _isAddContactMode
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Color(0xFF999999)),
                                onPressed: _exitAddContactMode,
                              )
                            : null,
                      ),
                      style: const TextStyle(height: 1.0),
                      onSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    double fieldWidth = 400;
                    final keyContext = _brandFieldKey.currentContext;
                    if (keyContext != null) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null) fieldWidth = box.size.width;
                    }
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(4),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 220,
                            maxWidth: fieldWidth,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Text(
                                    option['clientname']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: _onBrandSelected,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!_isAddContactMode) ...[
            const Text('Upload Logo',
                style: TextStyle(fontSize: 14, color: Color(0xFF505050))),
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
                    padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Browse',
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
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
                      child: Image.memory(_logoFile!.bytes!, fit: BoxFit.contain),
                    ),
                  )
                else if (_existingLogoPath != null && _existingLogoPath!.isNotEmpty)
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
                        imgUrl(_existingLogoPath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
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
          ],

          Text(_isAddContactMode ? 'Contact Info' : 'Client Info',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF505050))),
          const SizedBox(height: 16),
          Responsive.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labeledField(label: 'Contact Name', controller: _clientNameController),
                    const SizedBox(height: 16),
                    _labeledField(label: 'Mobile No.', controller: _mobileController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _labeledField(label: 'Contact Name', controller: _clientNameController)),
                    const SizedBox(width: 20),
                    Expanded(child: _labeledField(label: 'Mobile No.', controller: _mobileController, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildEmailField()),
                  ],
                ),
          const SizedBox(height: 28),

          Center(
            child: SizedBox(
              width: 350,
              height: 44,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF535353),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _isAddContactMode
                      ? 'Add Contact'
                      : (_isEditMode ? 'Update Client' : 'Create Client'),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return AppLabeledField(
      label: 'Email ID',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: AppFormStyles.inputDecoration(
              suffixIcon: _isCheckingEmail
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _emailError != null
                      ? const Icon(Icons.error_outline, color: Colors.red, size: 20)
                      : _emailController.text.isNotEmpty
                          ? const Icon(Icons.check_circle_outline, color: Colors.green, size: 20)
                          : null,
            ),
            style: const TextStyle(height: 1.0),
            onChanged: _checkEmail,
          ),
          if (_emailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _emailError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
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

  // ── Brand List Section ─────────────────────────────────────────────────

  Widget _buildBrandListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: const Text(
            'Client list',
            style: TextStyle(
                fontSize: 20,color: Color(0xFF505050), fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ReusableTable(
          columns: _brandColumns,
          rows: _brandContactRows,
          isLoading: _isLoading,
          currentPage: _currentPage,
          pageSize: _pageSize,
          maxVisiblePages: 8,
          cellVerticalPadding: 18,
          cellHorizontalPadding: 10,
          headerFontWeight: FontWeight.w500,
          onPageChanged: (page) => setState(() => _currentPage = page),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Settings',
      showBackbutton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(
                _isAddContactMode ? 'Add Contact' : 'Create Client',
                style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF505050),
                    fontWeight: FontWeight.w600),
              ),
            ),
            _buildCreateBrandSection(),
            const Divider(height: 1, color: Color(0xFFDDDDDD)),
            _buildBrandListSection(),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
