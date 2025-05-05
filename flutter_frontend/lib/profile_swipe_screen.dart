import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileSwipeScreen extends StatefulWidget {
  const ProfileSwipeScreen({super.key});

  @override
  State<ProfileSwipeScreen> createState() => _ProfileSwipeScreenState();
}

class _ProfileSwipeScreenState extends State<ProfileSwipeScreen> {
  List<Map<String, dynamic>> profiles = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  if (token == null) {
    if (!mounted) return;
    setState(() => isLoading = false);
    return;
  }

  final response = await http.get(
    Uri.parse('https://expant-backend.onrender.com/matches_today'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (!mounted) return;

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List<dynamic>;
    setState(() {
      profiles = data.cast<Map<String, dynamic>>();
      isLoading = false;
    });
  } else {
    setState(() => isLoading = false);
  }
}

void swipeRight() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  final profile = profiles[currentIndex];

  await http.post(
    Uri.parse('https://expant-backend.onrender.com/create_connection'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'username': profile['username']}),
  );

  if (!mounted) return;

  setState(() {
    currentIndex++;
  });
}


  void swipeLeft() {
  setState(() {
    currentIndex++;
  });
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F1DE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profiles.isEmpty || currentIndex >= profiles.length) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F1DE),
        body: const Center(child: Text("No more profiles 🫶")),
        bottomNavigationBar: _buildBottomNavBar(context),
      );
    }

    final profile = profiles[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Discover",
          style: TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(thickness: 2, color: Color(0xFF618B4A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 340,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(profile["university"] ?? ""),
                        Text(profile["company"] ?? ""),
                        const SizedBox(height: 8),
                        Text(
                          "${profile["first_name"] ?? ""} ${profile["last_name"] ?? ""}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(profile["pronouns"] ?? "", style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(profile["bio"] ?? "", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 230,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Located: ${profile["location"] ?? ""}"),
                        Text("Field: ${profile["field"] ?? ""}"),
                        Text("Job Status: ${profile["job_status"] ?? ""}"),
                        const SizedBox(height: 8),
                        const Text("Interests:"),
                        Wrap(
                          spacing: 6,
                          children: List<Widget>.from(
                            (profile["interests"] ?? []).map<Widget>(
                              (interest) => Chip(
                                label: Text(interest),
                                backgroundColor: const Color(0xFFF2CC8F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: swipeLeft,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text("Skip", style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: swipeRight,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Like", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

    Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF2CC8F),
      selectedItemColor: const Color(0xFF618B4A),
      unselectedItemColor: const Color(0xFF3B2C2F),
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/forum_list');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/job_board_user_page');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/profile_swipe');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/messages');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile_page');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Match'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
    }
  }