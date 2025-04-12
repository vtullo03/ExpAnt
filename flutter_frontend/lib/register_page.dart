import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isOrganization = false;
  String _errorMessage = '';

  Future<void> register() async {
    setState(() => _errorMessage = ''); // Clear any previous error

    final url = Uri.parse('https://expant-backend.onrender.com/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text,
        'is_organization': isOrganization, // HELP WTF I CANT GET IT TO WORK 
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
     /* if (isOrganization) {
        Navigator.pushReplacementNamed(context, '/organization_registration');
      } else {*/

        final loginResponse = await http.post(
          Uri.parse('https://expant-backend.onrender.com/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
          }),
        );
        if (loginResponse.statusCode == 200 || loginResponse.statusCode == 201) {
          // IF REGISTERED AS STANDARD USER!! add org later, and also need to check with backend?
          Navigator.pushReplacementNamed(context, '/account_setup');

        }
      }
    else { //if username is taken
      setState(() => _errorMessage = 'Invalid registration combination');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7BA273),
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Username',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isOrganization,
                      onChanged: (bool? value) {
                        setState(() {
                          isOrganization = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Organization account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(requires verification before activation)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4C88B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7BA273),
                    ),
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
