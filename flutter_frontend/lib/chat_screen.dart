import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String name; // Receiver name

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  String? currentUsername;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    currentUsername = prefs.getString('username');
    await _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('https://expant-backend.onrender.com/messages/${widget.name}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['messages'];

        setState(() {
          messages = data.map<Map<String, dynamic>>((msg) => {
            'text': msg['messages'],
            'time': msg['timestamp'] ?? '',
            'isMe': msg['user_1'] == currentUsername,
          }).toList();
          isLoading = false;
        });

        await Future.delayed(Duration(milliseconds: 200));
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        print('Error fetching messages: ${response.body}');
      }
    } catch (e) {
      print('Fetch error: $e');
    }
  }

  Future<void> _sendMessage() async {
  if (_controller.text.trim().isEmpty || currentUsername == null) return;

  final text = _controller.text.trim();
  final timestamp = TimeOfDay.now().format(context);
  _controller.clear();

  setState(() {
    messages.add({'text': text, 'time': timestamp, 'isMe': true});
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse('https://expant-backend.onrender.com/create_message'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': widget.name, //receiver
        'message': text,
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to send message: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Send failed: ${response.body}")),
      );
    }
  } catch (e) {
    print('Send error: $e');
  }

  await Future.delayed(const Duration(milliseconds: 100));
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent + 3,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7E7),
        elevation: 0,
        title: Row(
          children: [
            //const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            const SizedBox(width: 10),
            Text(widget.name, style: const TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold)),
          ],
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
                : messages.isEmpty
                    ? const Center(child: Text("No messages yet."))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return Column(
                            crossAxisAlignment: msg['isMe']
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['time'],
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: msg['isMe'] ? const Color(0xFFF2CC8F) : const Color(0xFF2B4035),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['text'],
                                  style: TextStyle(
                                    color: msg['isMe'] ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: const Color(0xFF8C3D47),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "start a message...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: _sendMessage,
                          color: const Color(0xFF618B4A),
                        ),
                      ],
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
}
