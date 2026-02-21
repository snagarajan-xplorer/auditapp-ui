import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:flutter/cupertino.dart';

import '../constants.dart';
import '../controllers/usercontroller.dart';
import '../localization/app_translations.dart';
import '../responsive.dart';
import 'main/layoutscreen.dart';

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
    'Unscheduled',
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    if (_uc.userData.role == null) {
      _uc.loadInitData();
    }

    // Read arguments passed from unscheduled audit screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _prefillData = args;
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

              // Pre-fill form fields from unscheduled audit row data
              if (_prefillData != null) {
                Future.delayed(const Duration(milliseconds: 400), () {
                  final pf = _prefillData!;

                  // If client_id is present, load templates for that client
                  if (pf['client_id'] != null) {
                    final clientId = pf['client_id'].toString();
                    _uc.getTemplateList(
                      context,
                      clientid: clientId,
                      callback: (templates) {
                        _templateList = templates;
                        if (mounted) setState(() {});
                      },
                    );
                  }

                  // Patch available form values
                  final patch = <String, dynamic>{};
                  if (pf['client_id'] != null) {
                    patch['client_id'] = pf['client_id'].toString();
                  }
                  if (pf['zone'] != null && pf['zone'] != '-') {
                    patch['zone'] = pf['zone'];
                  }
                  if (pf['state'] != null && pf['state'] != '-') {
                    patch['state'] = pf['state'];
                  }
                  if (pf['city'] != null && pf['city'] != '-') {
                    // Add the city to city list so dropdown has the value
                    _cityList = [{'Name': pf['city']}];
                    if (mounted) setState(() {});
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _formKey.currentState?.patchValue({'city': pf['city']});
                    });
                  }
                  if (pf['location'] != null && pf['location'] != '-') {
                    patch['location'] = pf['location'];
                  }
                  if (pf['type_of_location'] != null &&
                      pf['type_of_location'] != '-') {
                    patch['type_of_location'] = pf['type_of_location'];
                  }
                  if (pf['branch'] != null && pf['branch'] != '-') {
                    patch['branch'] = pf['branch'];
                  }

                  _formKey.currentState?.patchValue(patch);
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
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            onChanged: (value) {
              if (value == null) return;
              _uc.getTemplateList(
                context,
                clientid: value,
                callback: (templates) {
                  _templateList = templates;
                  if (mounted) setState(() {});
                },
              );
            },
            decoration: _inputDecoration('Company Name'),
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
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Template Name'),
          ),
        ),
      ];

  /// Full-width: Audit Name
  Widget _fieldAuditName() => FormBuilderTextField(
        name: 'auditname',
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
        style: Theme.of(context).textTheme.bodyMedium,
        validator: FormBuilderValidators.required(
          errorText:
              AppTranslations.of(context)!.text('key_error_01') ?? '',
        ),
        decoration: _inputDecoration('Audit Branch Name'),
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
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _inputDecoration('Location', required: false),
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
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Assigned To'),
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
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Date').copyWith(
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
            validator: FormBuilderValidators.required(
              errorText:
                  AppTranslations.of(context)!.text('key_error_01') ?? '',
            ),
            decoration: _inputDecoration('Time').copyWith(
              suffixIcon: const Icon(CupertinoIcons.clock, size: 20),
            ),
          ),
        ),
      ];

  /// Full-width: Information (multiline)
  Widget _fieldInformation() => FormBuilderTextField(
        name: 'remarks',
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
          backgroundColor: const Color(0xFF0376d8),
          padding: const EdgeInsets.all(5),
        ),
        onPressed: _onCreateAudit,
        child: const Center(
          child: Text(
            'Create Audit',
            style: paragraphTextStyle,
          ),
        ),
      ),
    );
  }

  // ── form submit ───────────────────────────────────────────────────────────
  // Fields that exist in tbl_audit (match the model's $fillable + DB columns)
  static const Set<String> _dbFields = {
    'auditname', 'audit_no', 'start_date', 'client_id', 'start_time',
    'pincode', 'zone', 'state', 'city', 'assigned_user', 'template_id',
    'created_user', 'latitude', 'longitude', 'reporturl', 'remarks',
    'publish_user', 'end_date', 'end_time', 'complete_date', 'branch',
    'publish_date', 'location',
  };

  void _onCreateAudit() {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final Map<String, dynamic> data = {};
    _formKey.currentState!.value.forEach((key, value) {
      if (value is DateTime) {
        data[key] = Jiffy.parseFromDateTime(value).dateTime.toIso8601String();
      } else {
        data[key] = value;
      }
    });

    data['end_date'] = data['start_date'];
    data['end_time'] = data['start_time'];
    data['created_user'] = _uc.userData.userId;

    // Ensure optional DB fields have a default (columns are NOT NULLABLE)
    data.putIfAbsent('remarks', () => ' ');
    data.putIfAbsent('location', () => ' ');

    // Remove fields that don't exist in tbl_audit
    data.removeWhere((key, _) => !_dbFields.contains(key));

    // Replace null values with space (DB columns are NOT NULLABLE)
    data.updateAll((key, value) => value ?? ' ');

    _uc.saveAudit(context, data: data, callback: () {
      Navigator.pushNamed(context, '/auditlist');
    });
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
                              decoration: _inputDecoration('Select Audit Type'),
                            ),
                          ),
                          const SizedBox(height: defaultPadding * 1.5),

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
