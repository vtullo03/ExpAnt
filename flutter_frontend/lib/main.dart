import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; //fonts
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'organization_registration_page.dart';
import 'account_setup_page.dart';
import 'customize_profile_page.dart';
import 'interest_selection_page.dart';
import 'forum_list_page.dart';
import 'create_forum_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Flask Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.lexendDecaTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/organization_registration': (context) => const OrganizationRegistrationPage(),
        '/account_setup': (context) => const AccountSetupPage(),
        '/customize_profile': (context) => const CustomizeProfilePage(),
        '/select_interests': (context) => const InterestSelectionPage(),
        '/forum_list': (context) => const ForumListPage(),
        '/create_forum': (context) => const CreateForumPage(),
      },
    );
  }
}
