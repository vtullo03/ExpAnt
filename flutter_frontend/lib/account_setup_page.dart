import 'package:flutter/material.dart';

class AccountSetupPage extends StatefulWidget {
  const AccountSetupPage({super.key});

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _employment = TextEditingController();
  final _startDate = TextEditingController();

  String? selectedPronoun;
  String? selectedIndustry;
  String? selectedEducation;

  final List<String> pronouns = ['She/Her', 'He/Him', 'They/Them', 'Other'];
  final List<String> industries = ['Tech', 'Healthcare', 'Education', 'Finance'];
  final List<String> educationLevels = ['High School', 'Bachelor’s', 'Master’s', 'PhD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Welcome to ExpAnt! Let’s\nset up your account!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7BA273)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text("Tell us a bit about yourself.", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedPronoun,
                hint: const Text('Pronouns'),
                items: pronouns.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (value) => setState(() => selectedPronoun = value),
              ),

              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedIndustry,
                hint: const Text('Field/Industry'),
                items: industries.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (value) => setState(() => selectedIndustry = value),
              ),

              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedEducation,
                hint: const Text('Education diploma, Bachelor’s, etc.'),
                items: educationLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => selectedEducation = value),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: _employment, decoration: const InputDecoration(labelText: 'Employment')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(controller: _startDate, decoration: const InputDecoration(labelText: 'Start date')),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/customize_profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA273),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text("Next", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
