import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../services/LocalStorage.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat();

    _checkSessionAndRoute();
  }

  Future<void> _checkSessionAndRoute() async {
    await LocalStorage.clearData("userdata");
    Timer(const Duration(seconds: 3), () {
      if (mounted) Get.offNamed('/login');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: SizedBox(
          height: 400,
          width: 300,
          child: Column(
            children: [
              SvgPicture.asset("assets/images/can-logo.svg"),
              LinearProgressIndicator(
                value: controller.value,
                semanticsLabel: '',
              )
            ],
          ),
        ),
      ),
    );
  }
}
