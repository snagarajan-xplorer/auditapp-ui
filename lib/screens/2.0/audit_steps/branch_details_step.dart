import 'package:audit_app/localization/app_translations.dart';
import 'package:audit_app/widget/boxcontainer.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:audit_app/widget/app_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:jiffy/jiffy.dart';

class BranchDetailsStep extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final bool isViewMode;
  final AutovalidateMode autovalidateMode;
  final VoidCallback onContinue;

  const BranchDetailsStep({
    super.key,
    required this.formKey,
    required this.isViewMode,
    required this.autovalidateMode,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BoxContainer(
        width: double.infinity,
        height: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: FormBuilder(
            key: formKey,
            autovalidateMode: autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Branch Details",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
                const SizedBox(height: 24),
                // Row 1: Manager Name, ID Card Number, Joining Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppLabeledField(
                        label: AppTranslations.of(context)!
                            .text("key_branch"),
                        child: FormBuilderTextField(
                          name: "managername",
                          readOnly: isViewMode,
                          validator: isViewMode
                              ? null
                              : FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_01"))
                                ]),
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: AppFormStyles.inputDecoration(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppLabeledField(
                        label: AppTranslations.of(context)!
                            .text("key_idcard"),
                        child: FormBuilderTextField(
                          name: "idcardno",
                          readOnly: isViewMode,
                          validator: isViewMode
                              ? null
                              : FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_01"))
                                ]),
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: AppFormStyles.inputDecoration(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppLabeledField(
                        label: AppTranslations.of(context)!
                            .text("key_joiningdate"),
                        child: FormBuilderDateTimePicker(
                          name: "joining_date",
                          enabled: !isViewMode,
                          initialDate: Jiffy.now().dateTime,
                          firstDate:
                              Jiffy.now().subtract(years: 40).dateTime,
                          lastDate: Jiffy.now().dateTime,
                          validator: isViewMode
                              ? null
                              : FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_01"))
                                ]),
                          timePickerInitialEntryMode:
                              TimePickerEntryMode.dialOnly,
                          style: Theme.of(context).textTheme.bodyMedium,
                          inputType: InputType.date,
                          decoration: AppFormStyles.inputDecoration(
                              suffixIcon: Icon(
                                  CupertinoIcons.calendar_badge_plus,
                                  size: 20.0,
                                  color: Colors.grey.shade600)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Row 2: Phone Number, Email ID
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppLabeledField(
                        label: AppTranslations.of(context)!
                            .text("key_phoneno"),
                        child: FormBuilderTextField(
                          name: "phoneno",
                          readOnly: isViewMode,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          keyboardType: TextInputType.numberWithOptions(
                              signed: true, decimal: false),
                          validator: isViewMode
                              ? null
                              : FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_01")),
                                  FormBuilderValidators.minLength(10,
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_03")),
                                  FormBuilderValidators.maxLength(10,
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_03"))
                                ]),
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: AppFormStyles.inputDecoration(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppLabeledField(
                        label: AppTranslations.of(context)!
                            .text("key_username"),
                        child: FormBuilderTextField(
                          name: "emailid",
                          readOnly: isViewMode,
                          validator: isViewMode
                              ? null
                              : FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_01")),
                                  FormBuilderValidators.email(
                                      errorText:
                                          AppTranslations.of(context)!
                                              .text("key_error_02"))
                                ]),
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: AppFormStyles.inputDecoration(),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 32),
                // Continue to Audit / Next button
                Center(
                  child: ButtonComp(
                    width: 250,
                    label: isViewMode ? "Next" : "Continue to Audit",
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
