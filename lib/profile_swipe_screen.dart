import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_swipe_screen.dart';
import 'chat_screen.dart';
import 'main.dart';

class ProfileSwipeScreen extends StatefulWidget {
  const ProfileSwipeScreen({super.key});

  @override
  State<ProfileSwipeScreen> createState() => _ProfileSwipeScreenState();
}

class _ProfileSwipeScreenState extends State<ProfileSwipeScreen> {
  List<Map<String, dynamic>> profiles = [
    {
      "bio": "Rockstar with a passion for front-end frameworks.",
      "images": [],
      "interests": ["React", "Music Theory", "VR Development"],
      "font_color": 0xFF005522,
      "background_color": 0xFFF4F1DE, // background of whole screen
      "font_type": 1,
      "pronouns": "they/them",
      "university": "Stage Lights Academy",
      "company": "Fazbear Innovations",
      "field": "Tech",
      "location": "Brooklyn, United States",
      "first_name": "Bonnie",
      "last_name": "Bunny",
      "job_status": "Open to work",
    },
    {
      "bio": "Building dreams with code and caffeine ☕",
      "images": [],
      "interests": ["Flutter", "Startups", "Product Design"],
      "font_color": 0xFF6B3E26,
      "background_color": 0xFFF4F1DE,
      "font_type": 1,
      "pronouns": "she/her",
      "university": "NYU",
      "company": "DreamTech",
      "field": "Software Engineering",
      "location": "New York, United States",
      "first_name": "Sarah",
      "last_name": "Lamond",
      "job_status": "Hiring!",
    },
  ];

  int currentIndex = 0;

  void swipeLeft() {
    setState(() {
      if (currentIndex < profiles.length - 1) {
        currentIndex++;
      }
    });
  }

  void swipeRight() {
    setState(() {
      if (currentIndex < profiles.length - 1) {
        currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty || currentIndex >= profiles.length) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F1DE),
        body: const Center(child: Text("No more profiles 🫶")),
      );
    }

    final profile = profiles[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Discover",
          style: TextStyle(
            color: Color(0xFF618B4A),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(
            thickness: 2,
            color: Color(0xFF618B4A),
          ),
        ),
      ),
      body: Center(
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              swipeRight();
            } else {
              swipeLeft();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Business Card at top (WHITE!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, // 🤍 White business card
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          profile["university"] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile["company"] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${profile["first_name"]} ${profile["last_name"]}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(profile["font_color"]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile["pronouns"] ?? "",
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile["bio"] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grey Image Box
                  Container(
                    height: 230,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Located: ${profile["location"]}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Field: ${profile["field"]}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Job Status: ${profile["job_status"]}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Interests:",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: List.generate(profile["interests"].length, (index) {
                            return Chip(
                              label: Text(
                                profile["interests"][index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3B2C2F),
                                ),
                              ),
                              backgroundColor: const Color(0xFFF2CC8F),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
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
      bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF2CC8F),
      selectedItemColor: const Color(0xFF618B4A),
      unselectedItemColor: const Color(0xFF3B2C2F),
      currentIndex: 2,
      onTap: (index) {
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  MessageScreen()),
          );
        }
      },
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/notebook.png'), size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/suitcase.png'), size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/ant.png'), size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/person.png'), size: 24),
            label: '',
          ),
        ],
      ),
    );
  }
}

