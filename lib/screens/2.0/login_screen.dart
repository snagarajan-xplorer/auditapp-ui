import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/usercontroller.dart';
import '../../services/api_service.dart';

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
            const SizedBox(height: 38),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 36, bottom: 36),
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
              ),
              child: Form(
                key: formKey,
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
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 360,
                      height: 50,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(
                            color: Color(0xFF505050),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFC9C9C9),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
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
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 360,
                      height: 50,
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF505050),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFC9C9C9),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
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
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 360,
                      child: DropdownButtonFormField<String>(
                        value: roleMap.containsKey(selectedRole) ? selectedRole : null,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: const TextStyle(
                            color: Color(0xFF505050),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFC9C9C9),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: roleMap.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value ?? roleMap.keys.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 360,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
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
    );
  }
}