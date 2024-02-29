import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  bool _passwordVisible = false; // Moved here
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateSignUpButtonState);
    _emailController.addListener(_updateSignUpButtonState);
    _passwordController.addListener(_updateSignUpButtonState);
  }

  void _updateSignUpButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _usernameController.removeListener(_updateSignUpButtonState);
    _emailController.removeListener(_updateSignUpButtonState);
    _passwordController.removeListener(_updateSignUpButtonState);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isSignUpButtonEnabled() {
    return _usernameController.text.isNotEmpty &&
           _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _selectedImagePath != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Keep this to avoid resizing due to keyboard
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center( // Use Center to align everything in the middle
        child: SingleChildScrollView( // Allows scrolling when the keyboard is visible
          padding: const EdgeInsets.all(20.0), // Adjust padding as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the column itself
            children: <Widget>[
              Center( // Center the stack in the middle of the screen
                child: Stack(
                  alignment: Alignment.bottomRight, // Position the edit icon at the bottom right of the avatar
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showImagePicker(context);
                      },
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue,
                        child: _selectedImagePath == null
                          ? const Icon(Icons.account_circle, size: 120, color: Colors.white)
                          : Image.asset(_selectedImagePath!, fit: BoxFit.cover),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue, // Match the icon button background to the theme or avatar ring
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white, // Add a white border for better visibility
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white), // Ensure icon color contrasts well with the background
                        onPressed: () {
                          _showImagePicker(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSignUpButtonEnabled() ? () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    // Before signing out, send verification email
                    if (userCredential.user != null && !userCredential.user!.emailVerified) {
                      await userCredential.user!.sendEmailVerification();
                    }
                    // Immediately sign out the user after account creation
                    await FirebaseAuth.instance.signOut();
                    
                    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                      'username': _usernameController.text,
                      'email': _emailController.text,
                      'avatar': _selectedImagePath, // Save the selected avatar's path
                    });
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text("Success"),
                          content: Text("An email has been sent to ${_emailController.text} Please verify your email address before logging in."),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Error"),
                        content: Text(e.toString()),
                        actions: <Widget>[
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: const Text("Okay"),
                          ),
                        ],
                      ),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choose an image"),
          content: Container(
            height: 360, // Adjust height as necessary
            width: double.maxFinite,
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0, // Space between columns
              mainAxisSpacing: 8.0, // Space between rows
              childAspectRatio: 1, // Aspect ratio for the children
              children: <String>[
                'assets/images/Avatars/bear.png',
                'assets/images/Avatars/blond_woman.png',
                'assets/images/Avatars/cat.png',
                'assets/images/Avatars/chicken.png',
                'assets/images/Avatars/dog.png',
                'assets/images/Avatars/fox.png',
                'assets/images/Avatars/girl.png',
                'assets/images/Avatars/gorilla.png',
                'assets/images/Avatars/panda.png',
                'assets/images/Avatars/rabbit.png',
                'assets/images/Avatars/user.png',
                'assets/images/Avatars/woman.png',
              ].map((String path) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImagePath = path;
                      Navigator.of(context).pop();
                    });
                  },
                  child: Image.asset(path, fit: BoxFit.cover),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
