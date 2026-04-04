import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/usercontroller.dart';
import '../../services/api_service.dart';
import '../../widget/app_form_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final UserController usercontroller = Get.find<UserController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String password = "";
  String confirmPassword = "";
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;
  bool btnEnabled = false;
  String msg = "";
  String? token;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      token = Get.parameters['token'];
      usercontroller.checkCorrectToken(context, data: {"token": token}, callback: (data) {
        if (data.containsKey("type")) {
          btnEnabled = false;
          msg = data["message"];
        } else {
          btnEnabled = true;
        }
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, data) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Alert'),
            content: const Text('You must change your password before proceeding.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
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
                  'Change Password',
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
                  child: btnEnabled ? _buildForm() : _buildMessage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
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
            'Set your new password',
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
              label: 'New Password',
              child: TextFormField(
                obscureText: !showPassword,
                decoration: AppFormStyles.inputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
                onChanged: (value) {
                  password = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minHeight: 50),
            child: AppLabeledField(
              label: 'Confirm Password',
              child: TextFormField(
                obscureText: !showConfirmPassword,
                decoration: AppFormStyles.inputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
                onChanged: (value) {
                  confirmPassword = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
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
                        if (password != confirmPassword) {
                          APIService(context).showWindowAlert(
                            title: "",
                            desc: "Password and Confirm Password do not match",
                            callback: () {},
                          );
                          return;
                        }
                        setState(() {
                          _autovalidateMode = AutovalidateMode.disabled;
                          isLoading = true;
                        });
                        var obj = {
                          "token": token,
                          "password": password,
                          "confirmpassword": confirmPassword,
                        };
                        usercontroller.changePassword(context, data: obj, callback: () {
                          setState(() {
                            isLoading = false;
                          });
                          Get.offNamed("/dashboard");
                        });
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
                      'Change Password',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
