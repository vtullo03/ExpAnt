import 'package:flutter/material.dart';

class OrganizationRegistrationPage extends StatelessWidget {
  const OrganizationRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6E3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Organization Setup',
          style: TextStyle(
            color: Color(0xFF7BA273),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'This is where you’ll fill out your organization info.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
