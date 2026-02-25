import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:flutter/cupertino.dart';

import '../../constants.dart';
import '../../controllers/usercontroller.dart';
import '../../localization/app_translations.dart';
import '../../models/screenarguments.dart';
import '../../responsive.dart';
import '../main/layoutscreen.dart';

/// ---------------------------------------------------------------------------
/// Create Audit Screen
/// Matches the "Scheduled Audit Details" form in the screenshot.
/// - Company Name = client name (clientid dropdown)
/// - Pincode auto-fills State & City
/// - "Create Audit" button calls saveAudit API
/// ---------------------------------------------------------------------------
class CreateAuditScreen extends StatefulWidget {
  const CreateAuditScreen({super.key});

  @override
  State<CreateAuditScreen> createState() => _CreateAuditScreenState();
}

class _CreateAuditScreenState extends State<CreateAuditScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final UserController _uc = Get.put(UserController());

  List<dynamic> _clientList = [];
  List<dynamic> _templateList = [];
  List<dynamic> _auditorList = [];
  List<dynamic> _cityList = [];
  List<String> _zones = [];

  DateTime _initialDate = Jiffy.now().dateTime;
  DateTime _firstDate = Jiffy.now().dateTime;
  DateTime _lastDate = Jiffy.now().add(months: 8).dateTime;

  /// Data passed from the unscheduled audit screen row
  Map<String, dynamic>? _prefillData;

  /// Whether this is an edit of an existing audit
  bool _isEditMode = false;

  /// The audit ID when editing
  dynamic _editAuditId;

  /// Track the selected audit type (Scheduled or Un Scheduled)
  String _selectedAuditType = 'Scheduled';

  /// Flag to prevent onChanged from interfering during prefill
  bool _isPrefilling = false;



  static const List<String> _locationTypes = [
    'Retail Store',
    'Warehouse',
    'Office',
    'Factory',
    'Showroom',
    'Distribution Center',
    'Other',
  ];

  static const List<String> _auditTypes = [
    'Scheduled',
    'Un-scheduled',
  ];

  // ── helpers ──────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label, {bool required = true}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      label: RichText(
        text: TextSpan(
          text: label,
          children: required
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  )
                ]
              : [],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      contentPadding: const EdgeInsets.only(left: 20, top: 10),
      counterText: '',
      errorMaxLines: 3,
      hoverColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: ThemeData().primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: ThemeData().primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: ThemeData().primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    if (_uc.userData.role == null) {
      _uc.loadInitData();
    }

    // Read arguments passed from audit list (Edit) or unscheduled audit screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ScreenArgument && args.mode == 'Edit' && args.editData != null) {
      // Coming from audit list "Edit" button
      _isEditMode = true;
      _prefillData = Map<String, dynamic>.from(args.editData!);
      _editAuditId = _prefillData!['id'] ?? _prefillData!['audit_id'];
      _selectedAuditType = 'Scheduled';
    } else if (args is Map<String, dynamic>) {
      _prefillData = args;
      // Coming from "Schedule Audit" on unscheduled screen — always Scheduled
      _selectedAuditType = 'Scheduled';
    }

    _uc.getClientList(
      context,
      data: {
        'role': _uc.userData.role,
        'client_id': _uc.userData.clientid,
      },
      callback: (clients) {
        _clientList = clients;
        _uc.getUserList(
          context,
          data: {'role': 'JrA', 'status': 'A'},
          callback: (users) {
            _auditorList =
                users.where((u) => u['role'] == 'JrA').toList();
            _uc.getZone(context, callback: (zones) {
              _zones = zones.map((z) => z.toString()).toList();
              if (mounted) setState(() {});

              // Pre-fill form fields from unscheduled audit row data or edit mode
              if (_prefillData != null) {
                _isPrefilling = true;
                Future.delayed(const Duration(milliseconds: 400), () {
                  final pf = _prefillData!;

                  // Build base patch FIRST (fields that don't need async)
                  final patch = <String, dynamic>{};
                  patch['audit_type'] = 'Scheduled';
                  if (pf['client_id'] != null) patch['client_id'] = pf['client_id'].toString();
                  if (pf['zone'] != null && pf['zone'] != '-') patch['zone'] = pf['zone'];
                  if (pf['location'] != null && pf['location'] != '-') patch['location'] = pf['location'];
                  if (pf['type_of_location'] != null && pf['type_of_location'] != '-') patch['type_of_location'] = pf['type_of_location'];
                  if (pf['branch'] != null && pf['branch'] != '-') patch['branch'] = pf['branch'];

                  // Edit mode: also prefill auditname, assigned_user, remarks, start_date, start_time
                  if (_isEditMode) {
                    final auditName = (pf['auditname'] ?? pf['audit_name'] ?? '').toString();
                    if (auditName.isNotEmpty) patch['auditname'] = auditName;
                    if (pf['assigned_user'] != null) patch['assigned_user'] = pf['assigned_user'].toString();
                    if (pf['remarks'] != null && pf['remarks'].toString().trim().isNotEmpty) {
                      patch['remarks'] = pf['remarks'].toString();
                    }
                    // Parse start_date
                    if (pf['start_date'] != null) {
                      try {
                        final dt = DateTime.parse(pf['start_date'].toString());
                        patch['start_date'] = dt;
                        // Allow editing past dates in edit mode
                        if (dt.isBefore(_firstDate)) {
                          _firstDate = dt;
                          _initialDate = dt;
                        }
                      } catch (_) {}
                    }
                    // Parse start_time
                    if (pf['start_time'] != null) {
                      try {
                        final rawTime = pf['start_time'].toString();
                        // Handle formats like "09:00:00" or ISO datetime
                        DateTime timeValue;
                        if (rawTime.contains('T') || rawTime.contains('-')) {
                          timeValue = DateTime.parse(rawTime);
                        } else {
                          final parts = rawTime.split(':');
                          timeValue = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
                        }
                        patch['start_time'] = timeValue;
                      } catch (_) {}
                    }
                  }

                  final pincode = pf['pincode']?.toString() ?? '';
                  if (pincode.isNotEmpty && pincode != '-') {
                    patch['pincode'] = pincode;
                  }

                  // Helper to re-apply all fields after any setState rebuild
                  void reapplyPatch() {
                    _formKey.currentState?.patchValue(patch);
                    if (pf['template_id'] != null && _templateList.isNotEmpty) {
                      _formKey.currentState?.patchValue({
                        'template_id': pf['template_id'].toString(),
                      });
                    }
                  }

                  // Apply base fields immediately
                  _formKey.currentState?.patchValue(patch);

                  // Load templates for the selected client
                  if (pf['client_id'] != null) {
                    _uc.getTemplateList(
                      context,
                      clientid: pf['client_id'].toString(),
                      callback: (templates) {
                        _templateList = templates;
                        if (mounted) setState(() {});
                        // Re-apply all fields + template after rebuild
                        Future.delayed(const Duration(milliseconds: 300), () {
                          reapplyPatch();
                          _isPrefilling = false;
                        });
                      },
                    );
                  }

                  // Handle pincode-dependent fields (state, city) asynchronously
                  if (pincode.length == 6) {
                    _uc.getPinCode(
                      context,
                      pincode: pincode,
                      callback: (res) {
                        _cityList = res.isNotEmpty
                            ? res
                            : (pf['city'] != null && pf['city'] != '-'
                                ? [{'Name': pf['city']}]
                                : []);
                        final stateValue = res.isNotEmpty
                            ? res[0]['State']
                            : (pf['state'] != null && pf['state'] != '-'
                                ? pf['state']
                                : null);
                        if (mounted) setState(() {});
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (stateValue != null) {
                            _formKey.currentState?.patchValue({'state': stateValue});
                          }
                          // Re-apply all fields after rebuild
                          reapplyPatch();
                          final cityToSelect =
                              pf['city'] ?? (res.isNotEmpty ? res[0]['Name'] : null);
                          if (cityToSelect != null) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _formKey.currentState?.patchValue({'city': cityToSelect});
                            });
                          }
                        });
                      },
                    );
                  } else {
                    // No valid pincode — set state/city from prefill data directly
                    if (pf['state'] != null && pf['state'] != '-') {
                      _formKey.currentState?.patchValue({'state': pf['state']});
                    }
                    if (pf['city'] != null && pf['city'] != '-') {
                      _cityList = [{'Name': pf['city']}];
                      if (mounted) setState(() {});
                      Future.delayed(const Duration(milliseconds: 200), () {
                        reapplyPatch();
                        _formKey.currentState?.patchValue({'city': pf['city']});
                      });
                    }
                    // If no template load is pending, clear prefilling flag
                    if (pf['client_id'] == null) _isPrefilling = false;
                  }
                });
              }
            });
          },
        );
      },
    );
  }

  // ── section header widget ─────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: headingFontSize,
          fontWeight: FontWeight.w600,
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

  /// Row: Company Name | Template Name
  List<Widget> _rowCompanyTemplate() => [
        Flexible(
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'client_id',
            items: _clientList
                .map<DropdownMenuItem<String>>(
                  (c) => DropdownMenuItem(
                    value: c['clientid'].toString(),
                    child: Text(c['clientname']),
                  ),
                )
                .toList(),
            validator: _selectedAuditType == 'Scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '',
                  )
                : null,
            onChanged: (value) {
              if (value == null || _isPrefilling) return;
              _uc.getTemplateList(
                context,
                clientid: value,
                callback: (templates) {
                  _templateList = templates;
                  if (mounted) setState(() {});
                },
              );
            },
            decoration: _inputDecoration('Company Name', required: _selectedAuditType == 'Scheduled'),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'template_id',
            items: _templateList
                .map<DropdownMenuItem<String>>(
                  (t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['templatename']),
                  ),
                )
                .toList(),
            validator: _selectedAuditType == 'Scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '',
                  )
                : null,
            decoration: _inputDecoration('Template Name', required: _selectedAuditType == 'Scheduled'),
          ),
        ),
      ];

  // ── Financial year helper ────────────────────────────────────────────────
  String _computeFinancialYear() {
    final now = DateTime.now();
    final fyStart = now.month >= 4 ? now.year : now.year - 1;
    return 'FY$fyStart-${(fyStart + 1).toString().substring(2)}';
  }

  /// Full-width: Company Name (for un-scheduled form – no template loading)
  Widget _fieldCompanyNameOnly() => FormBuilderDropdown<String>(
        name: 'client_id',
        items: _clientList
            .map<DropdownMenuItem<String>>(
              (c) => DropdownMenuItem(
                value: c['clientid'].toString(),
                child: Text(c['clientname']),
              ),
            )
            .toList(),
        validator: FormBuilderValidators.required(
          errorText:
              AppTranslations.of(context)!.text('key_error_01') ?? '',
        ),
        decoration: _inputDecoration('Company Name'),
      );

  // ── initialValue helpers (safe getter from prefill data) ────────────────
  String? _prefillString(String key, [String? altKey]) {
    if (_prefillData == null) return null;
    final v = _prefillData![key] ?? (altKey != null ? _prefillData![altKey] : null);
    if (v == null) return null;
    final s = v.toString();
    return (s.isEmpty || s == '-') ? null : s;
  }

  /// Full-width: Audit Name
  Widget _fieldAuditName() => FormBuilderTextField(
        name: 'auditname',
        initialValue: _isEditMode ? _prefillString('auditname', 'audit_name') : null,
        style: Theme.of(context).textTheme.bodyMedium,
        validator: FormBuilderValidators.required(
          errorText:
              AppTranslations.of(context)!.text('key_error_01') ?? '',
        ),
        decoration: _inputDecoration('Audit Name'),
      );

  /// Full-width: Audit Branch Name
  Widget _fieldBranchName() => FormBuilderTextField(
        name: 'branch',
        initialValue: _prefillString('branch'),
        style: Theme.of(context).textTheme.bodyMedium,
        validator: _selectedAuditType == 'Scheduled'
            ? FormBuilderValidators.required(
                errorText:
                    AppTranslations.of(context)!.text('key_error_01') ?? '',
              )
            : null,
        decoration: _inputDecoration('Audit Branch Name', required: _selectedAuditType == 'Scheduled'),
      );

  /// Row: Zone | Pincode | State
  List<Widget> _rowZonePincodeState() => [
        Flexible(
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'zone',
            items: _zones
                .map<DropdownMenuItem<String>>(
                  (z) => DropdownMenuItem(value: z, child: Text(z)),
                )
                .toList(),
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Zone'),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderTextField(
            name: 'pincode',
            initialValue: _prefillString('pincode'),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLength: 6,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            onChanged: (value) {
              if (value != null && value.length == 6) {
                _uc.getPinCode(
                  context,
                  pincode: value,
                  callback: (res) {
                    _cityList = res;
                    if (mounted) setState(() {});
                    _formKey.currentState?.patchValue({
                      'state': res.isNotEmpty ? res[0]['State'] : '',
                    });
                    // auto-select first city if available
                    if (res.isNotEmpty) {
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        () => _formKey.currentState
                            ?.patchValue({'city': res[0]['Name']}),
                      );
                    }
                  },
                );
              }
            },
            decoration: _inputDecoration('Pincode'),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderTextField(
            name: 'state',
            initialValue: _prefillString('state'),
            style: Theme.of(context).textTheme.bodyMedium,
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('State'),
          ),
        ),
      ];

  /// Row: City | Location | Type of Location
  List<Widget> _rowCityLocationTypeOf() => [
        Flexible(
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'city',
            items: _cityList
                .map<DropdownMenuItem<String>>(
                  (c) => DropdownMenuItem(
                    value: c['Name'].toString(),
                    child: Text(c['Name'].toString()),
                  ),
                )
                .toList(),
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('City'),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderTextField(
            name: 'location',
            initialValue: _prefillString('location'),
            style: Theme.of(context).textTheme.bodyMedium,
            validator: _selectedAuditType == 'Un-scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '', 
                  )
                : null,
            decoration: _inputDecoration(
              'Location',
              required: _selectedAuditType == 'Un-scheduled',
            ),
          ),
        ),
        _hSpace,
        Flexible( 
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'type_of_location', 
            items: _locationTypes
                .map<DropdownMenuItem<String>>(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                )
                .toList(),
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Type of Location'),
          ),
        ),
      ];

  /// Row: Assigned To | Date | Time
  List<Widget> _rowAssignedDatetime() => [
        Flexible(
          flex: 1,
          child: FormBuilderDropdown<String>(
            name: 'assigned_user',
            items: _auditorList
                .map<DropdownMenuItem<String>>(
                  (u) => DropdownMenuItem(
                    value: u['id'].toString(),
                    child: Text(u['name']),
                  ),
                )
                .toList(),
            validator: _selectedAuditType == 'Scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '',
                  )
                : null,
            decoration: _inputDecoration('Assigned To', required: _selectedAuditType == 'Scheduled'),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderDateTimePicker(
            name: 'start_date',
            initialDate: _initialDate,
            firstDate: _firstDate,
            lastDate: _lastDate,
            inputType: InputType.date,
            style: Theme.of(context).textTheme.bodyMedium,
            validator: _selectedAuditType == 'Scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '',
                  )
                : null,
            decoration: _inputDecoration('Date', required: _selectedAuditType == 'Scheduled').copyWith(
              suffixIcon: const Icon(CupertinoIcons.calendar, size: 20),
            ),
          ),
        ),
        _hSpace,
        Flexible(
          flex: 1,
          child: FormBuilderDateTimePicker(
            name: 'start_time',
            inputType: InputType.time,
            format: DateFormat.jm(),
            timePickerInitialEntryMode: TimePickerEntryMode.dialOnly,
            style: Theme.of(context).textTheme.bodyMedium,
            validator: _selectedAuditType == 'Scheduled'
                ? FormBuilderValidators.required(
                    errorText:
                        AppTranslations.of(context)!.text('key_error_01') ?? '',
                  )
                : null,
            decoration: _inputDecoration('Time', required: _selectedAuditType == 'Scheduled').copyWith(
              suffixIcon: const Icon(CupertinoIcons.clock, size: 20),
            ),
          ),
        ),
      ];

  /// Full-width: Information (multiline)
  Widget _fieldInformation() => FormBuilderTextField(
        name: 'remarks',
        initialValue: _isEditMode ? _prefillString('remarks') : null,
        maxLines: 4,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: _inputDecoration('Information', required: false).copyWith(
          contentPadding: const EdgeInsets.only(left: 20, top: 25),
        ),
      );

  // ── submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: 160,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF535353),
          padding: const EdgeInsets.all(5),
        ),
        onPressed: _onCreateAudit,
        child: Center(
          child: Text(
            _isEditMode ? 'Update Audit' : 'Create Audit',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── form submit ───────────────────────────────────────────────────────────
  // Fields that exist in tbl_audit (match the model's $fillable + DB columns)
  static const Set<String> _dbFieldsScheduled = {
    'auditname', 'audit_no', 'start_date', 'client_id', 'start_time',
    'pincode', 'zone', 'state', 'city', 'assigned_user', 'template_id',
    'created_user', 'latitude', 'longitude', 'reporturl', 'remarks',
    'publish_user', 'end_date', 'end_time', 'complete_date', 'branch',
    'publish_date', 'location', 'type_of_location',
  };

  // Fields that exist in tbl_unscheduled_audit
  static const Set<String> _dbFieldsUnscheduled = {
    'client_id', 'zone', 'state', 'city', 'pincode',
    'location', 'type_of_location', 'created_user', 'financial_year',
  };

  void _onCreateAudit() {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final Map<String, dynamic> raw = {};
    _formKey.currentState!.value.forEach((key, value) {
      if (value is DateTime) {
        raw[key] = Jiffy.parseFromDateTime(value).dateTime.toIso8601String();
      } else {
        raw[key] = value;
      }
    });
    raw['created_user'] = _uc.userData.userId;

    if (_selectedAuditType == 'Un-scheduled') {
      // ── Un-scheduled audit ───────────────────────────────────────────────
      raw['financial_year'] = _computeFinancialYear();

      // Keep only columns that exist in tbl_unscheduled_audit
      raw.removeWhere((key, _) => !_dbFieldsUnscheduled.contains(key));

      // Null-guard
      raw.updateAll((key, value) => value ?? '');

      _uc.saveUnScheduledAudit(context, data: raw, callback: (success) {
        if (success) Navigator.pushNamed(context, '/unscheduledaudit');
      });
    } else {
      // ── Scheduled audit ──────────────────────────────────────────────────
      raw['end_date']   = raw['start_date'];
      raw['end_time']   = raw['start_time'];

      // Ensure optional DB fields have a default (columns are NOT NULLABLE)
      raw.putIfAbsent('remarks',       () => ' ');
      raw.putIfAbsent('location',      () => ' ');
      raw.putIfAbsent('branch',        () => ' ');
      raw.putIfAbsent('client_id',     () => ' ');
      raw.putIfAbsent('template_id',   () => ' ');
      raw.putIfAbsent('assigned_user', () => ' ');
      raw.putIfAbsent('start_date',    () => ' ');
      raw.putIfAbsent('start_time',    () => ' ');

      // Remove fields that don't exist in tbl_audit
      raw.removeWhere((key, _) => !_dbFieldsScheduled.contains(key));

      // Replace null values with space (DB columns are NOT NULLABLE)
      raw.updateAll((key, value) => value ?? ' ');

      // In edit mode, include the audit ID so backend performs update
      // (added after filtering so it's in the request but not in _dbFieldsScheduled)
      if (_isEditMode && _editAuditId != null) {
        raw['id'] = _editAuditId;
      }

      _uc.saveAudit(context, data: raw, callback: () {
        Navigator.pushNamed(context, '/auditlist');
      });
    }
  }

  // ── build helper: responsive row/column ──────────────────────────────────
  Widget _responsiveRow(List<Widget> children) {
    return Responsive.isDesktop(context)
        ? Row(children: children)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutScreen(
      previousScreenName: 'Audit',
      showBackbutton: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Audit Type ──────────────────────────────────
                          const SizedBox(height: defaultPadding),
                          SizedBox(
                            width: Responsive.isDesktop(context) ? 400 : double.infinity,
                            child: FormBuilderDropdown<String>(
                              name: 'audit_type',
                              initialValue: 'Scheduled',
                              items: _auditTypes
                                  .map<DropdownMenuItem<String>>(
                                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                                  )
                                  .toList(),
                              validator: FormBuilderValidators.required(
                                errorText:
                                    AppTranslations.of(context)!.text('key_error_01') ?? '',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAuditType = value ?? 'Scheduled';
                                });
                              },
                              decoration: _inputDecoration('Select Audit Type'),
                            ),
                          ),
                          const SizedBox(height: defaultPadding * 1.5),

                          // ── SCHEDULED AUDIT FORM ──────────────────────────
                          if (_selectedAuditType == 'Scheduled')
                            ...[
                              // ── Scheduled Audit Details ──────────────────────
                              _sectionHeader('Scheduled Audit Details'),
                              _responsiveRow(_rowCompanyTemplate()),
                              const SizedBox(height: defaultPadding),
                              _fieldAuditName(),
                              const SizedBox(height: defaultPadding * 1.5),

                              // ── Audit Branch Details ─────────────────────────
                              _sectionHeader('Audit Branch Details'),
                              _fieldBranchName(),
                              const SizedBox(height: defaultPadding),
                              _responsiveRow(_rowZonePincodeState()),
                              const SizedBox(height: defaultPadding),
                              _responsiveRow(_rowCityLocationTypeOf()),
                              const SizedBox(height: defaultPadding * 1.5),

                              // ── Audit Schedule ───────────────────────────────
                              _sectionHeader('Audit Schedule'),
                              _responsiveRow(_rowAssignedDatetime()),
                              const SizedBox(height: defaultPadding),
                              _fieldInformation(),
                              const SizedBox(height: defaultPadding * 1.5),
                            ]
                          else
                            // ── UNSCHEDULED AUDIT FORM ────────────────────────
                            ...[
                              // ── Audit Basic Details ──────────────────────────
                              _sectionHeader('Audit Basic Details'),
                              _fieldCompanyNameOnly(),
                              const SizedBox(height: defaultPadding),
                              _responsiveRow(_rowZonePincodeState()),
                              const SizedBox(height: defaultPadding),
                              _responsiveRow(_rowCityLocationTypeOf()),
                              const SizedBox(height: defaultPadding * 1.5),
                            ],

                          // ── Submit row ───────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [_buildSubmitButton()],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
