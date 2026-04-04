import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/usercontroller.dart';
import '../../widget/app_form_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final UserController usercontroller = Get.find<UserController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String email = "";
  bool isLoading = false;
  bool emailSent = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/can-logo.svg',
                width: 200,
                height: 100,
              ),
              const SizedBox(height: 28),
              const Text(
                'Forgot Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF505050),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(top: 36, bottom: 36),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFEFEF),
                ),
                child: emailSent
                    ? _buildSuccessMessage()
                    : _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Password reset link has been sent to your email.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF505050)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 360,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Get.offNamed("/login"),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF505050)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 14, color: Color(0xFF505050)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter your registered email address',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF505050),
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minHeight: 50),
            child: AppLabeledField(
              label: 'Email',
              child: TextFormField(
                decoration: AppFormStyles.inputDecoration(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF505050),
                ),
                onChanged: (value) {
                  email = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!_emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 360,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _autovalidateMode = AutovalidateMode.disabled;
                          isLoading = true;
                        });
                        usercontroller.forgotPassword(
                          context,
                          data: {"email": email},
                          callback: (res) {
                            setState(() {
                              isLoading = false;
                              emailSent = true;
                            });
                          },
                        );
                      } else {
                        setState(() {
                          _autovalidateMode = AutovalidateMode.onUserInteraction;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF505050),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Get.offNamed("/login"),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF505050),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
