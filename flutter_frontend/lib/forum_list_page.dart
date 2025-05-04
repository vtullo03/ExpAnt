import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'forum_detail_page.dart';


class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  List<Map<String, dynamic>> forums = [];
  List<Map<String, dynamic>> filteredForums = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchForums();
    _searchController.addListener(_filterForums);
  }

  void _filterForums() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredForums = forums.where((forum) {
        final title = forum['title']?.toLowerCase() ?? '';
        final description = forum['description']?.toLowerCase() ?? '';
        return title.contains(query) || description.contains(query);
      }).toList();
    });
  }

  Future<void> fetchForums() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  if (token == null) {
    print('No token found');
    return;
  }

  final response = await http.get(
    Uri.parse('https://expant-backend.onrender.com/feed'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  print('DEBUG raw response.body = ${response.body}');

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body) as List;

      final List<Map<String, dynamic>> loadedForums = [];

      for (final forumSummary in data) {
        final forumId = forumSummary['id'];
        final fullForumResponse = await http.get(
          Uri.parse('https://expant-backend.onrender.com/forums/$forumId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (fullForumResponse.statusCode == 200) {
          final fullForum = jsonDecode(fullForumResponse.body);
          fullForum['id'] = forumId; // Ensure ID is included
          loadedForums.add(fullForum);
        } else {
          print('Failed to fetch forum $forumId: ${fullForumResponse.body}');
        }
      }

      setState(() {
        forums = loadedForums;
        filteredForums = loadedForums;
        isLoading = false;
      });
    } catch (e) {
      print('DEBUG error during JSON decoding: $e');
    }
  } else {
    print('Failed to load forums: ${response.body}');
  }
}




    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Forum",
          style: TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(thickness: 2, color: Color(0xFF618B4A)),
        ),
      ),
        body: Column(
          children: [
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredForums.isEmpty
                  ? const Center(child: Text("No forums to display."))
                  : ListView.builder(
                      itemCount: filteredForums.length,
                      itemBuilder: (context, index) {
                        final forum = filteredForums[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForumDetailPage(forumId: forum['id']),
                                  ),
                                );
                              }, 
                              child: ListTile(
                                title: Text(
                                  forum['title'] ?? '[title]',
                                  style: const TextStyle(
                                    color: Color(0xFF7BA273),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${forum['username'] ?? '[unknown]'} • ${formatTimestamp(forum['created_time'] ?? '')}",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                  trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.comment_outlined, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      (forum['comments']?.length ?? 0).toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Divider(thickness: 1),
                          ],
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.pushNamed(context, '/create_forum');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BA273),
                    ),
                    child: const Text(
                      '+ Create post',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
String formatTimestamp(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '[unknown time]';
  try {
    final dt = DateTime.parse(raw); // No need to .toUtc() unless required
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(dt);
  } catch (e) {
    print('DEBUG timestamp parsing failed for: $raw');
    return '[invalid time]';
  }
}

Widget _buildBottomNavBar(BuildContext context) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF2CC8F),
        selectedItemColor: const Color(0xFF618B4A),
        unselectedItemColor: const Color(0xFF3B2C2F),
        currentIndex: 0,
        onTap: (index) {
          if (index == 0){
            Navigator.pushReplacementNamed(context, '/forum_list');
          }

          if (index == 1){
            Navigator.pushReplacementNamed(context, '/job_board_user_page');
          }

          if (index == 2){
            Navigator.pushReplacementNamed(context, '/profile_swipe');
          }

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/messages');
          
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        ],
      );
    }

}

