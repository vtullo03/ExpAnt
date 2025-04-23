import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';


class ForumDetailPage extends StatefulWidget {
  final int forumId;

  const ForumDetailPage({super.key, required this.forumId});

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  Map<String, dynamic>? forum;
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchForumDetails();
  }

  Future<void> fetchForumDetails() async {
    print("Fetching forum with ID: ${widget.forumId}");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    final forumResponse = await http.get(
      Uri.parse('https://expant-backend.onrender.com/forums/${widget.forumId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("Forum status: ${forumResponse.statusCode}");
    print("Forum body: ${forumResponse.body}");

    if (forumResponse.statusCode == 200) {
      final forumData = jsonDecode(forumResponse.body);

      final List<Map<String, dynamic>> parsedComments =
          List<Map<String, dynamic>>.from(forumData['comments'] ?? []);

      setState(() {
        forum = {
          'id': widget.forumId,
          ...forumData,
        };
        comments = parsedComments;
        isLoading = false;
      });
    } else {
      print("Failed to load forum.");
      setState(() => isLoading = false);
    }
  }

  Future<void> submitComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || _commentController.text.trim().isEmpty) return;

    final response = await http.post(
      Uri.parse('https://expant-backend.onrender.com/create_comment/${widget.forumId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': _commentController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _commentController.clear();
      await fetchForumDetails(); //refresh forum after submitting this comment
    } else {
      print("Failed to submit comment: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : forum == null
              ? const Center(child: Text("Forum not found."))
              : Column(
                  children: [
                    //Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFF8B3A3A),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 35,),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    //Main content
                    Expanded(
                      child: ListView(
                        children: [
                          //Forum details: title, username, timestamp, ID(?)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  forum!['title'] ?? '[title]',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF7BA273),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${forum!['username']} • ${formatTimestamp(forum!['created_time'])}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  forum!['description'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),

                          // Comments header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Text(
                                  "Comments",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: Color(0xFF7BA273)),
                                ),
                                const Spacer(),
                                const Icon(Icons.comment_outlined),
                                const SizedBox(width: 4),
                                Text(comments.length.toString()),
                              ],
                            ),
                          ),
                          const Divider(),

                          //Comments list
                          ...comments.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final comment = entry.value;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "@${comment['username']} • ${formatTimestamp(comment['created_at'])}",
                                    style: const TextStyle(fontWeight: FontWeight.bold,)),
                                  const SizedBox(height: 4),
                                  Text(comment['description'] ?? '', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          //Comment input
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: _commentController,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Write a comment...",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          //Submit button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: submitComment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7BA273),
                                    ),
                                    child: const Text(
                                      "+ Comment",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
