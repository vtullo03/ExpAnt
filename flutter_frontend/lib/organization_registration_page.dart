import 'package:flutter/material.dart';

class OrganizationRegistrationPage extends StatefulWidget {
  const OrganizationRegistrationPage({super.key});

  @override
  State<OrganizationRegistrationPage> createState() => _OrganizationRegistrationPageState();
}

class _OrganizationRegistrationPageState extends State<OrganizationRegistrationPage> {
  final TextEditingController _emailController = TextEditingController();

  void _submit() {
    // You can add your API call here to submit the email
    final email = _emailController.text;
    if (email.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted successfully!')),
      );
      Navigator.pop(context); // return to login page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Organization\naccount form',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7BA273),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our team will need to verify your organization’s status.\n\nYour profile will be reviewed and activated once confirmed, and we will reach out to you with your account information.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 30),
            const Text(
              'Company email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                enabledBorder: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4C88B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Back to login
                },
                child: const Text(
                  'Back to login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7BA273),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
