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

  bool get isOwnProfile => viewedUsername == loggedUsername;

  String? viewedUsername;
  String? loggedUsername;

  final picker = ImagePicker();
  File? newProfilePic;
  File? newBackground;

  final TextEditingController bioController        = TextEditingController();
  final TextEditingController firstController      = TextEditingController();
  final TextEditingController lastController       = TextEditingController();
  final TextEditingController pronounsController   = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController companyController    = TextEditingController();
  final TextEditingController fieldController      = TextEditingController();
  final TextEditingController locationController   = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchProfile());
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    loggedUsername = prefs.getString('username');
    viewedUsername = (ModalRoute.of(context)?.settings.arguments as String?) ?? loggedUsername;

    if (token == null || viewedUsername == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final profileRes = await http.get(
        Uri.parse('https://expant-backend.onrender.com/match_profile/$viewedUsername'),
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
          if (forumSummary['username'] == viewedUsername) {
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
          bioController.text        = profileData?['bio']        ?? '';
          firstController.text      = profileData?['first_name'] ?? '';
          lastController.text       = profileData?['last_name']  ?? '';
          pronounsController.text   = profileData?['pronouns']   ?? '';
          universityController.text = profileData?['university'] ?? '';
          companyController.text    = profileData?['company']    ?? '';
          fieldController.text      = profileData?['field']      ?? '';
          locationController.text   = profileData?['location']   ?? '';
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage(bool isProfile) async {
    if (!isOwnProfile) return;
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
    if (!isOwnProfile) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    final Map<String, dynamic> updated = {};
    void add(String key, TextEditingController c) {
      final v = c.text.trim();
      if (v.isNotEmpty) updated[key] = v;
    }

    add('bio',        bioController);
    add('first_name', firstController);
    add('last_name',  lastController);
    add('pronouns',   pronounsController);
    add('university', universityController);
    add('company',    companyController);
    add('field',      fieldController);
    add('location',   locationController);

    if (updated.isEmpty) {
      setState(() => isEditing = false);
      return;
    }

    await http.post(
      Uri.parse('https://expant-backend.onrender.com/update_match_profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updated),
    );

    if (!mounted) return;
    setState(() => isEditing = false);
    fetchProfile();
  }

  Widget _buildTF(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          maxLines: maxLines,
        ),
      );

  Widget _readOnlyLine(String label, String? value) => value == null || value.isEmpty
      ? const SizedBox()
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(value)),
            ],
          ),
        );

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
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          isOwnProfile ? 'My Profile' : (viewedUsername ?? ''),
          style: const TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold),
        ),
        actions: isOwnProfile
            ? [
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
                ),
              ]
            : [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(thickness: 2, color: Color(0xFF618B4A)),
        ),
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
                      ? DecorationImage(image: FileImage(newBackground!), fit: BoxFit.cover)
                      : null,
                ),
                child: newBackground == null ? const Center(child: Text('Background Placeholder')) : null,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isEditing ? () => pickImage(true) : null,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: newProfilePic != null ? FileImage(newProfilePic!) : null,
                child: newProfilePic == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profileData?['username'] ?? 'Unknown User',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isOwnProfile && isEditing) ...[
              _buildTF('First name', firstController),
              _buildTF('Last name', lastController),
              _buildTF('Pronouns', pronounsController),
              _buildTF('University', universityController),
              _buildTF('Company', companyController),
              _buildTF('Field', fieldController),
              _buildTF('Location', locationController),
              _buildTF('Bio', bioController, maxLines: 3),
            ] else ...[
              _readOnlyLine('Name', '${profileData?['first_name'] ?? ''} ${profileData?['last_name'] ?? ''}'),
              _readOnlyLine('Pronouns', profileData?['pronouns']),
              _readOnlyLine('University', profileData?['university']),
              _readOnlyLine('Company', profileData?['company']),
              _readOnlyLine('Field', profileData?['field']),
              _readOnlyLine('Location', profileData?['location']),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
              Text(bioController.text, textAlign: TextAlign.center),
            ],
            const Divider(thickness: 1.5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Forum Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  MaterialPageRoute(builder: (_) => ForumDetailPage(forumId: post['id'])),
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
            if (!isOwnProfile) {
              Navigator.pushReplacementNamed(context, '/profile_page');
            }
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
