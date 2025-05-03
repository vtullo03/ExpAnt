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
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://expant-backend.onrender.com/connections'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = List<String>.from(jsonDecode(response.body));
        data.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); // Alphabetical sort
        setState(() {
          connections = data;
          isLoading = false;
        });
      } else {
        print('Failed to fetch connections: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching connections: $e');
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
    );
  }
}
