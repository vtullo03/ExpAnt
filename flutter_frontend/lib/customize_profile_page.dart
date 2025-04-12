import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // COLORPICKER PACKAGE

class CustomizeProfilePage extends StatefulWidget {
  const CustomizeProfilePage({super.key});

  @override
  State<CustomizeProfilePage> createState() => _CustomizeProfilePageState();
}

class _CustomizeProfilePageState extends State<CustomizeProfilePage> {
  final _bioController = TextEditingController();
  Color fontColor = Colors.black;
  Color backgroundColor = Colors.white;
  int selectedFontType = 0;

  final fontOptions = {
    0: 'Sans',
    1: 'Serif',
    2: 'Monospace',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Skip for now
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4C88B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Skip for now",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Next, let’s\ncustomize\nyour profile!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7BA273),
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                "This information will be used to\ncreate your “business card,” which\nyour potential connections will see.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 32),

              const Align(
                alignment: Alignment.centerLeft,
                  child: Text(
                    "Bio (briefly introduce yourself)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 6),
              const SizedBox(height: 8),
              TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Tell us a little about you...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
                 ),
               ),


              const SizedBox(height: 30),

              // Font Color Picker
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Font Color (default black)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDialog<Color>(
                    context: context,
                    builder: (_) => _ColorPickerDialog(initial: fontColor),
                  );
                  if (picked != null) setState(() => fontColor = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: fontColor,
                    border: Border.all(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Background Color Picker
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Background color (default white)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDialog<Color>(
                    context: context,
                    builder: (_) => _ColorPickerDialog(initial: backgroundColor),
                  );
                  if (picked != null) setState(() => backgroundColor = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Next Button
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/select_interests');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7BA273),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pick a color"),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: color,
          onColorChanged: (c) => setState(() => color = c),
          availableColors: [
            Colors.white,
            Colors.black,
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.orange,
            Colors.purple,
            Colors.brown,
            Colors.grey,
            Colors.teal,
            Colors.pink,
            Colors.indigo,
            Colors.yellow,
          ],
          layoutBuilder: (context, colors, child) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((Color color) {
                return GestureDetector(
                  onTap: () => setState(() => this.color = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.black),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text("Select"),
        )
      ],
    );
  }
}
