import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shared Form Field Styling — Design System v2.0
/// ─────────────────────────────────────────────────────────────────────────────
/// All 2.0 screens MUST use these utilities so that form fields stay consistent:
///   ▸ Label is always OUTSIDE (above) the input field
///   ▸ Uniform border radius, colours, padding
///   ▸ Optional required-asterisk on labels
///
/// Usage:
///   AppLabeledField(
///     label: 'Unit Head / HOD Name',
///     required: true,
///     child: TextFormField(decoration: AppFormStyles.inputDecoration()),
///   )
/// ─────────────────────────────────────────────────────────────────────────────

// ─── Design Tokens ──────────────────────────────────────────────────────────

class AppFormStyles {
  AppFormStyles._(); // prevent instantiation

  // Colours
  static const Color borderColor = Color(0xFFBDBDBD);
  static const Color focusBorderColor = Color(0xFF1976D2);
  static const Color errorBorderColor = Colors.red;
  static const Color fillColor = Colors.white;
  static const Color labelColor = Color(0xFF505050);
  static const Color hintColor = Color(0xFF9E9E9E);

  // Dimensions
  static const double _radius = 8.0;

  /// Standard [InputDecoration] with **no label** inside the field.
  /// Labels must be placed outside using [fieldLabel] or [AppLabeledField].
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: hintColor),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: '',
      errorMaxLines: 3,
      hoverColor: Colors.transparent,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: focusBorderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: errorBorderColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: errorBorderColor, width: 2),
      ),
    );
  }

  /// Builds the standard label widget placed **above** form fields.
  ///
  /// [required] appends a red asterisk after the label text.
  static Widget fieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom:8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ]
              : [],
        ),
      ),
    );
  }
}

// ─── Convenience Widget ─────────────────────────────────────────────────────

/// Wraps **any** form-field child with a consistent outside-label layout.
///
/// ```dart
/// AppLabeledField(
///   label: 'Email ID',
///   required: true,
///   child: FormBuilderTextField(
///     name: 'email',
///     decoration: AppFormStyles.inputDecoration(),
///   ),
/// )
/// ```
class AppLabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const AppLabeledField({
    super.key,
    required this.label,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormStyles.fieldLabel(label, required: required),
        child,
      ],
    );
  }
}
