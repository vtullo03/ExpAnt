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
      final nestedIds = jsonDecode(response.body) as List;
      //Flatten the nested list of forum IDs
      final ids = (nestedIds)
          .expand((item) => item is List ? item : [item])
          .cast<int>()
          .toList();

      print('DEBUG flattened ids = $ids');

      final List<Map<String, dynamic>> loadedForums = [];

      for (final id in ids) {
        final forumResponse = await http.get(
          Uri.parse('https://expant-backend.onrender.com/forums/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (forumResponse.statusCode == 200) {
          final forumData = jsonDecode(forumResponse.body);
          forumData['id'] = id;
          loadedForums.add(forumData);
        }
      }

      setState(() {
        forums = loadedForums;
        filteredForums = loadedForums;
        isLoading = false;
      });
    } catch (e) {
      print('DEBUG error during JSON decoding or flattening: $e');
    }
  } else {
    print('Failed to load forums: ${response.body}');
  }
}


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6E3),
        body: Column(
          children: [
            //Header Bar
            Container(
              color: const Color(0xFF8B3A3A), // deep red background
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6E3), // cream/white pill
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      "Forum",
                      style: TextStyle(
                        color: Color(0xFF7BA273),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),


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
                                      "${forum['username']} • ${formatTimestamp(forum['created_time'])}",
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                    ),
                    child: const Text('Back'),
                  ),
                ),
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
    );
  }

  String formatTimestamp(String raw) {
  try {
    final dt = DateTime.parse(raw).toUtc(); //Ensure UTC for consistency
    return '${DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(dt)} GMT';
  } catch (e) {
    return raw;
  }
}
}

