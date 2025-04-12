import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D5CA),
      appBar: AppBar(title: const Text('Home Page')),
      body: const Center(
        child: Text(
          'You are logged in!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
