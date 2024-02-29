import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_caption_flutter_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search.dart';
import 'upload.dart';
import 'favorites.dart';
import 'login.dart';
import 'home.dart';
import 'profile.dart'; // Assuming you have a Profile widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Add this line
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String? userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserAvatar();
  }

  void _fetchUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      print("Fetched user avatar URL: ${docSnapshot.data()?['avatar']}");
      setState(() {
        userAvatarUrl = docSnapshot.data()?['avatar'];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print("Selected index: $_selectedIndex");
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    print("User is logged in: $isLoggedIn");
    Widget profileIcon = Icon(Icons.account_circle); // Default profile icon

    if (isLoggedIn && userAvatarUrl != null) {
      // Use AssetImage for local assets
      profileIcon = CircleAvatar(
        backgroundImage: AssetImage(userAvatarUrl!),
      );
    }

    return Scaffold(
      body: _getScreenWidget(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: profileIcon,
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getScreenWidget() {
    // Check if the user is signed in
    final user = FirebaseAuth.instance.currentUser;
    switch (_selectedIndex) {
      case 0:
        return const Home();
      case 1:
      if (user != null) {
        return const Search();
      } else {
        return const Login();
      }
      case 2:
        if (user != null) {
          return const Upload();
        } else {
          return const Login();
        }
      case 3:
      if (user != null) {
        return const Favorites();
      } else {
        return const Login();
      }
      case 4:
        if (user != null) {
          // User is signed in, navigate to Profile
          return Profile(onAvatarUpdated: (String newPath) {
            setState(() {
              userAvatarUrl = newPath;
            });
          }); // Ensure you have a Profile widget with callback
        } else {
          // User is not signed in, navigate to Login
          return const Login();
        }
    }
    // This line will execute if none of the cases match
    return const Home();
  }
}
