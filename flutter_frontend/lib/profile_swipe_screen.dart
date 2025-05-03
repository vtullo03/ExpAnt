import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_screen.dart';
import 'message_screen.dart';

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

    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/matches_today'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        profiles = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } else {
      print('Failed to fetch matches: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  void swipeLeft() {
    setState(() {
      if (currentIndex < profiles.length - 1) currentIndex++;
    });
  }

  void swipeRight() {
    setState(() {
      if (currentIndex < profiles.length - 1) currentIndex++;
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
      );
    }

    final profile = profiles[currentIndex];
    print("Color used for name: ${profile["font_color"]}");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Discover",
          style: TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(thickness: 2, color: Color(0xFF618B4A)),
        ),
      ),
      body: Center(
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            direction == DismissDirection.startToEnd ? swipeRight() : swipeLeft();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Business Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(profile["university"] ?? "", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(profile["company"] ?? "", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          "${profile["first_name"] ?? ""} ${profile["last_name"] ?? ""}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            //color: Color(profile["font_color"] ?? 0xFF000000),
                            color: Color(0xFF000000 | ((profile["font_color"] ?? 0x000000) & 0xFFFFFF)),

                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(profile["pronouns"] ?? "", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Text(profile["bio"] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                        
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Placeholder image
                  Container(
                    height: 230,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
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
                        Text("Located: ${profile["location"] ?? ""}", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text("Field: ${profile["field"] ?? ""}", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text("Job Status: ${profile["job_status"] ?? ""}", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        const Text("Interests:", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: List<Widget>.from(
                            (profile["interests"] ?? []).map<Widget>(
                              (interest) => Chip(
                                label: Text(interest, style: const TextStyle(fontSize: 11, color: Color(0xFF3B2C2F))),
                                backgroundColor: const Color(0xFFF2CC8F),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      /*
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF2CC8F),
        selectedItemColor: const Color(0xFF618B4A),
        unselectedItemColor: const Color(0xFF3B2C2F),
        currentIndex: 2,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/notebook.png')), label: ''),
          BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/suitcase.png')), label: ''),
          BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/ant.png')), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: ''),
          BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/person.png')), label: ''),
        ],
      ), */
    );
  }
}
