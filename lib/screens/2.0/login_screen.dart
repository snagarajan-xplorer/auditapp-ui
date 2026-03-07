import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/usercontroller.dart';
import '../../services/api_service.dart';
import '../../widget/app_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserController usercontroller = Get.put(UserController());
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  String selectedRole = "AD";
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Map role display names to role IDs
  final Map<String, String> roleMap = {
    "AD": "Administrator",
    "SrA": "Audit Manager",
    "JrA": "Auditor",
    "CL": "Client / Member",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Image.asset(
              'assets/images/can_logo.png',  
              width: 330,
              height: 158,
            ),
            const SizedBox(height: 28),
            const Text(
              'Welcome to the Profaids Consulting Audit Application',
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
              child: Form(
                key: formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Login your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                            setState(() {
                              email = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
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
                        label: 'Password',
                        child: TextFormField(
                          obscureText: true,
                          decoration: AppFormStyles.inputDecoration(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF505050),
                          ),
                          onChanged: (value) {
                            setState(() {
                              password = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 360,
                      child: AppLabeledField(
                        label: 'Role',
                        child: DropdownButtonFormField<String>(
                          value: roleMap.containsKey(selectedRole) ? selectedRole : null,
                          decoration: AppFormStyles.inputDecoration(),
                          items: roleMap.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a role';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value ?? roleMap.keys.first;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 360,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _autovalidateMode = AutovalidateMode.disabled;
                            });
                            var obj = {
                              "email": email,
                              "password": password,
                              "role": selectedRole, // sends role ID e.g. "AD", "SrA"
                            };
                            usercontroller.login(context, data: obj, callback: () {
                              if (usercontroller.userData.changepass == "N") {
                                Get.offNamed("/changepassword/${usercontroller.userData.mvalue}");
                              } else {
                                Get.offNamed("/dashboard");
                              }
                            }, onFail: (String str) {
                              APIService(context).showWindowAlert(title: "", desc: str, callback: () {});
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
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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