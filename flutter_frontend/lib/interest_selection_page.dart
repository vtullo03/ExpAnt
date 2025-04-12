import 'package:flutter/material.dart';

class InterestSelectionPage extends StatefulWidget {
  const InterestSelectionPage({super.key});

  @override
  State<InterestSelectionPage> createState() => _InterestSelectionPageState();
}

class _InterestSelectionPageState extends State<InterestSelectionPage> {
  final List<String> interests = [
    'Coding', 'Gaming', 'Travelling',
    'Cooking', 'Drawing', 'Golfing', 
    'Music', 'Astrology', 'Food'
  ];
  final Set<String> selected = {};

  void toggleInterest(String interest) {
    setState(() {
      if (selected.contains(interest)) {
        selected.remove(interest);
      } else {
        selected.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
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
              "What are your\ninterests?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7BA273),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "These will help us connect you with\nlike-minded people.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            const Text(
              "To start, select at least three interests!\nYou can edit these later.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Interest buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: interests.map((interest) {
                final isSelected = selected.contains(interest);
                return OutlinedButton(
                  onPressed: () => toggleInterest(interest),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? const Color(0xFF7BA273) : Colors.transparent,
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: selected.length >= 3
                  ? () {
                      // TODO: Save selected interests to backend
                      Navigator.pushNamed(context, '/home');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Next", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
