import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String name;

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [
    {
      'text': 'You are so cute Sarah...',
      'time': '11:15pm',
      'isMe': false,
    },
    {
      'text': 'omg i know fr... i be the cutest no cap',
      'time': '11:20pm',
      'isMe': true,
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        'text': _controller.text.trim(),
        'time': TimeOfDay.now().format(context),
        'isMe': true,
      });
      _controller.clear();
    });

    // scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                color: Color(0xFF618B4A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(
            thickness: 2,
            color: Color(0xFF618B4A),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: msg['isMe']
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['time'],
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: msg['isMe']
                              ? const Color(0xFFF2CC8F)
                              : const Color(0xFF2B4035),
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
                  ),
                );
              },
            ),
          ),
          // Real Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: const Color(0xFF8C3D47),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF2CC8F),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black),
                ),
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
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Nav
          Container(
            color: const Color(0xFFF2CC8F),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFFF2CC8F),
              selectedItemColor: const Color(0xFF618B4A),
              unselectedItemColor: const Color(0xFF3B2C2F),
              currentIndex: 3,
              onTap: (index) {
              if (index == 3) {
                  Navigator.pop(context); // 💚 back to message list
                }
              },
              items: const [
                BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/notebook.png'),
                        size: 24),
                    label: ''),
                BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/suitcase.png'),
                        size: 24),
                    label: ''),
                BottomNavigationBarItem(
                    icon:
                        ImageIcon(AssetImage('assets/ant.png'), size: 24),
                    label: ''),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble), label: ''),
                BottomNavigationBarItem(
                    icon:
                        ImageIcon(AssetImage('assets/person.png'), size: 24),
                    label: ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
