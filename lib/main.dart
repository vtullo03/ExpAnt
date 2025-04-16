import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MessageScreen(),
    );
  }
}

class MessageScreen extends StatelessWidget {
  final List<Map<String, String>> messages = [
    {'name': 'Jungkook'},
    {'name': 'Vitoria Tullo'},
    {'name': 'Leanna Moy'},
    {'name': 'Maria Jones'},
    {'name': 'Pedro Pascal'},
    {'name': 'Timothee Chalamet'},
    {'name': 'Lady Gaga'},
    {'name': 'Sarah Lamond'},
    {'name': 'Gregory Bear'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1DE), // beige background
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Color(0xFF618B4A),
            height: 2.0,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
            ),
        title: Text(
          messages[index]['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF252525),
          ),
        ),
        subtitle: const Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(name: messages[index]['name']!),
      ),
    );
  },
);

        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF2CC8F),
        selectedItemColor: Color(0xFF618B4A),
        unselectedItemColor: Color(0xFF3B2C2F),
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) {
              Navigator.pop(context); // 💚 back to message list
            }
          },
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(
            AssetImage('assets/notebook.png'),
            size: 24,
          ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
            AssetImage('assets/suitcase.png'),
            size: 24,
          ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
            AssetImage('assets/ant.png'),
            size: 24,
          ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
            AssetImage('assets/person.png'),
            size: 24,
          ),
            label: '',
          ),
        ],
      ),
    );
  }
}
