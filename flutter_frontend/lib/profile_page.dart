import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'forum_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  List<dynamic> forumPosts = [];
  bool isLoading = true;
  bool isEditing = false;

  final picker = ImagePicker();
  File? newProfilePic;
  File? newBackground;
  final TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final username = prefs.getString('username');

    if (token == null || username == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final profileRes = await http.get(
        Uri.parse('https://expant-backend.onrender.com/match_profile/$username'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final forumRes = await http.get(
        Uri.parse('https://expant-backend.onrender.com/feed'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (profileRes.statusCode == 200 && forumRes.statusCode == 200) {
        final decodedProfile = jsonDecode(profileRes.body);
        final List<dynamic> allForums = jsonDecode(forumRes.body);

        final List<Map<String, dynamic>> myForums = [];

        for (final forumSummary in allForums) {
          if (forumSummary['username'] == username) {
            final forumId = forumSummary['id'];
            final fullForumResponse = await http.get(
              Uri.parse('https://expant-backend.onrender.com/forums/$forumId'),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (!mounted) return;

            if (fullForumResponse.statusCode == 200) {
              final fullForum = jsonDecode(fullForumResponse.body);
              fullForum['id'] = forumId;
              myForums.add(fullForum);
            }
          }
        }

        if (!mounted) return;
        setState(() {
          profileData = decodedProfile;
          forumPosts = myForums;
          bioController.text = profileData?['bio'] ?? '';
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        debugPrint(
            'Error fetching profile or forums: ${profileRes.body} | ${forumRes.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Exception in fetchProfile: $e');
    }
  }

  Future<void> pickImage(bool isProfile) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          newProfilePic = File(pickedFile.path);
        } else {
          newBackground = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final username = prefs.getString('username');
    if (token == null || username == null) return;

    final updatedProfile = {
      "bio": bioController.text,
      "images": [],              // TODO: hook up Cloudinary upload
      "font_color": 0,
      "background_color": 0,
      "font_type": 0,
      "pronouns": "",
      "university": "",
      "company": "",
      "field": "",
      "location": "",
      "first_name": profileData?['first_name'] ?? "",
      "last_name": profileData?['last_name'] ?? "",
    };

    final res = await http.post(
      Uri.parse('https://expant-backend.onrender.com/update_match_profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedProfile),
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      fetchProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${res.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F1DE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7BA273),
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // edit / save toggle
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) saveChanges();
              setState(() => isEditing = !isEditing);
            },
          ),

          IconButton(
            icon: const Icon(Icons.menu), 
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: isEditing ? () => pickImage(false) : null,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: newBackground != null
                      ? DecorationImage(
                          image: FileImage(newBackground!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: newBackground == null
                    ? const Center(child: Text('Background Placeholder'))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isEditing ? () => pickImage(true) : null,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    newProfilePic != null ? FileImage(newProfilePic!) : null,
                child: newProfilePic == null
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profileData?['username'] ?? 'Unknown User',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isEditing
                  ? TextField(
                      controller: bioController,
                      decoration:
                          const InputDecoration(labelText: 'Edit your bio'),
                    )
                  : Text(
                      bioController.text,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const Divider(thickness: 1.5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('My Forum Posts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...forumPosts.map(
              (post) => ListTile(
                title: Text(post['title'] ?? 'No title'),
                subtitle: Text(
                  post['description'] ?? 'No content',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForumDetailPage(forumId: post['id']),
                  ),
                ),
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
      currentIndex: 4,
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
