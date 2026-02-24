import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/usercontroller.dart';
import '../../models/screenarguments.dart';
import 'package:file_picker/file_picker.dart';
import '../main/layoutscreen.dart';
import '../../constants.dart';
import '../../widget/reusable_table.dart';
import 'package:jiffy/jiffy.dart';
import 'dart:js' as js;
import 'dart:html' as html;

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  final UserController userController = Get.put(UserController());

  // Data state
  List<Map<String, dynamic>> templateList = [];
  List<dynamic> clientList = [];
  List<dynamic> userList = [];
  String? selectedClientId;
  TextEditingController templateNameController = TextEditingController();
  String? uploadedFileName;
  PlatformFile? uploadedFile;
  bool isLoading = false;
  int currentPage = 1;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    if (userController.userData.role == null) {
      userController.loadInitData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    _loadClients();
    _loadUsers();
    _loadTemplates();
  }

  void _loadUsers() {
    userController.getUserList(context,
        data: {
          "role": "ALL",
          "status": "ALL",
          "client": userController.userData.clientid,
          "userRole": userController.userData.role,
        },
        callback: (data) {
          setState(() {
            userList = List.from(data);
          });
          // Reload templates so user names resolve correctly
          _loadTemplates();
        });
  }

  String _getUserName(dynamic userId) {
    if (userId == null) return '';
    final id = userId.toString();
    for (var user in userList) {
      final u = Map<String, dynamic>.from(user);
      if (u['id']?.toString() == id) {
        return u['name']?.toString() ?? id;
      }
    }
    return id;
  }

  void _loadClients() {
    userController.getClientList(
      context,
      data: {
        "role": userController.userData.role,
        "client_id": userController.userData.clientid,
      },
      loader: false,
      callback: (res) {
        if (mounted) {
          setState(() {
            clientList = (res).map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      },
    );
  }

  void _loadTemplates() {
    setState(() => isLoading = true);
    userController.getAllTemplateList(context, callback: (data) {
      setState(() {
        isLoading = false;
        templateList = List.from(data).map((e) {
          final item = Map<String, dynamic>.from(e);
          String formattedDate = '';
          try {
            formattedDate =
                Jiffy.parse(item['created_at'].toString()).format(pattern: 'dd/MM/yyyy');
          } catch (_) {
            formattedDate = item['created_at']?.toString() ?? '';
          }
          return {
            ...item,
            'templatename': item['templatename']?.toString() ?? '',
            'clientname': item['clientname']?.toString() ?? '',
            'displayDate': formattedDate,
            'created_by': _getUserName(item['assigned_user']),
            'status': item['status']?.toString() ?? '',
            'statusLabel': item['status'] == 'A' ? 'Active' : 'In Active',
            'statusColor': item['status'] == 'A' ? 'green' : 'red',
          };
        }).toList();
      });
    });
  }

  void _uploadTemplate() async {
    if (uploadedFile == null ||
        selectedClientId == null ||
        templateNameController.text.isEmpty) {
      return;
    }
    setState(() => isLoading = true);
    userController.uploadTemplate(
      context,
      filename: uploadedFile!.name,
      bytes: uploadedFile!.bytes,
      data: {
        'templatename': templateNameController.text,
        'description': templateNameController.text,
        'client_id': selectedClientId,
        'assigned_user': userController.userData.name, 
      },
      callback: (res) {
        setState(() {
          isLoading = false;
          uploadedFileName = null;
          uploadedFile = null;
          templateNameController.clear();
          selectedClientId = null;
        });
        _loadTemplates();
      },
    );
  }

  // ── Column definitions ────────────────────────────────────────────────────

  List<TableColumnDef> get _templateColumns => [
        TableColumnDef(label: 'Template', flex: 1, cellBuilder: (row, index) {
          final pageIndex = (currentPage - 1) * pageSize + index + 1;
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
        }),
        TableColumnDef(label: 'Template Name', flex: 2, key: 'templatename'),
        TableColumnDef(label: 'Brand', flex: 2, key: 'clientname'),
        TableColumnDef(label: 'Created Date', flex: 2, key: 'displayDate'),
        TableColumnDef(label: 'Template created by', flex: 2, key: 'created_by'),
        TableColumnDef(
          label: 'Status',
          flex: 2,
          cellBuilder: (row, _) {
            return statusBadgeCell(
              label: row['statusLabel'] ?? '-',
              color: row['statusColor'] ?? 'grey',
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      height: 33,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/edittemplate',
                            arguments: ScreenArgument(mode: 'Edit', editData: row),
                          );
                          if (result == true) {
                            _loadTemplates();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 12, color: Colors.white),
                        label: const Text('Edit',
                            style: TextStyle(fontSize: 12, color: Colors.white)),
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
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFBBBBBB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final templateToken = row['token'];
                        if (templateToken == null) return;
                        _downloadTemplate(templateToken.toString());
                      },
                      icon: const Icon(Icons.download,
                          size: 20, color: Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ];

void _downloadTemplate(String templateId) {
  final UserController uc = Get.find<UserController>();
  uc.downloadTemplate(
    context,
    data: {'template_id': templateId},
    callback: (res) {
      if (res != null && res['url'] != null) {
        // For Flutter Web
        html.AnchorElement(href: res['url'].toString())
          ..setAttribute('download', 'template_$templateId.xlsx')
          ..click();
      } else if (res != null && res['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'].toString())),
        );
      }
    },
  );
}
  // ── Create Template Section ───────────────────────────────────────────────

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
                      decoration: InputDecoration(
                        hintText: '',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4)),
                        filled: true,
                        fillColor: Colors.white,
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
                      items: clientList
                          .map<DropdownMenuItem<String>>((client) =>
                              DropdownMenuItem(
                                value: client['clientid']?.toString(),
                                child: Text(
                                    client['clientname']?.toString() ?? ''),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClientId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6)),
                        filled: true,
                        fillColor: Colors.white,
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

          // Upload Template
          const Text(
            'Upload Template',
            style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['xls', 'xlsx'],
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      uploadedFile = result.files.first;
                      uploadedFileName = uploadedFile!.name;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02B2EB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Browse',
                    style: TextStyle(fontSize: 14, color: Colors.white,fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              if (uploadedFileName != null)
                Flexible(
                  child: Text(
                    uploadedFileName!,
                    style: const TextStyle(
                      color: Color(0xFF505050),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '* File supported .xl & .xls  template format',
            style: TextStyle(fontSize: 12, color: Color(0xFF535353)),
          ),
          const SizedBox(height: 24),

          // Create Template button
          Center(
            child: SizedBox(
              width: 350,
              height: 40,
              child: ElevatedButton(
                onPressed: _uploadTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF535353),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Create Template',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Template List Section ─────────────────────────────────────────────────

  Widget _buildTemplateListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: const Text(
            'Template list',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ReusableTable(
          columns: _templateColumns,
          rows: templateList,
          isLoading: isLoading,
          currentPage: currentPage,
          pageSize: pageSize,
          maxVisiblePages: 8,
          cellVerticalPadding: 18,
          cellHorizontalPadding: 10,
          headerFontWeight: FontWeight.w500,
          onPageChanged: (page) => setState(() => currentPage = page),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Settings',
      showBackbutton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 50, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Template',
                    style: TextStyle(fontSize: 20,color: Color(0xFF505050), fontWeight: FontWeight.w500),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      js.context.callMethod('open', [
                        '${API_URL}templateexport?id=s2hgpasn0chndggqv0saht48b6lv25d8dkxulj9u8bgcosomappaiezrnc6kh6kgb8vbh2aqjplh78nk7r8caf3pq2f0bzckhf9ukv3y2g493w288e83preg',
                        '_blank'
                      ]);
                    },
                    label: const Text(
                      'Download Template Format',
                      style: TextStyle(
                          color: Color(0xFF02B2EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    icon: const Icon(Icons.download,
                        color: Color(0xFF02B2EB)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF02B2EB)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            _buildCreateTemplateSection(),
            _buildTemplateListSection(),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
