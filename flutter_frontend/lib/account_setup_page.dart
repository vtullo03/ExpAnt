import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountSetupPage extends StatefulWidget {
  const AccountSetupPage({super.key});

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _employment = TextEditingController();
  final _cityState = TextEditingController();

  String? selectedPronoun;
  String? selectedIndustry;
  String? selectedEducation;
  String? selectedCountry;

  final List<String> pronouns = ['She/Her', 'He/Him', 'They/Them', 'Other'];
  final List<String> industries = ['Tech', 'Healthcare', 'Education', 'Finance'];
  final List<String> educationLevels = ['High School Diploma', 'Bachelor’s', 'Master’s', 'PhD', 'Other'];
  final List<String> countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'India',
    'Germany',
    'Other',
  ];

  Future<void> submitProfileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token found.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://expant-backend.onrender.com/update_match_profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'company': _employment.text.trim(),
      'location': '${_cityState.text.trim()}, ${selectedCountry ?? ''}',
      'pronouns': selectedPronoun ?? '',
      'field': selectedIndustry ?? '',
      'university': selectedEducation ?? '',
      }
    ),

    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pushNamed(context, '/customize_profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile info: ${response.body}')),
      );
    }
  }

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
                    child: TextField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'First name'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
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
                hint: const Text('Highest completed education'),
                items: educationLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => selectedEducation = value),
              ),

              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                hint: const Text('Country'),
                items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => selectedCountry = value),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: _cityState,
                decoration: const InputDecoration(labelText: 'City/State'),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _employment,
                      decoration: const InputDecoration(labelText: 'Current place of employment'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: submitProfileInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA273),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
