import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<String> connections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConnections();
  }

Future<void> fetchConnections() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  if (token == null) {
    if (!mounted) return;
    setState(() => isLoading = false);
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/connections'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = List<String>.from(jsonDecode(response.body));
      data.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        connections = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (_) {
    if (!mounted) return;
    setState(() => isLoading = false);
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
        automaticallyImplyLeading: false,
        title: const Text(
          'messages',
          style: TextStyle(
            color: Color(0xFF618B4A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(color: Color(0xFF618B4A), thickness: 2),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : connections.isEmpty
              ? const Center(child: Text("No connections to message."))
              : ListView.builder(
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        connections[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Tap to view messages'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: connections[index],
                        );
                      },
                    );
                  },
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
      currentIndex: 3,
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