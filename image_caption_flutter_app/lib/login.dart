import 'package:flutter/material.dart';
import 'createAccount.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // This line is removed
import 'main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _passwordVisible = false; // Add this line
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Define a blue color theme
    Color blueThemeColor = Colors.blue.shade300;
    TextStyle linkStyle = TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold);

    return Scaffold(
      // Use a gradient background
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topRight,
        //     end: Alignment.bottomLeft,
        //     colors: [
        //       Colors.blue.shade50,
        //       Colors.blue.shade100,
        //     ],
        //   ),
        // ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or name
                const FlutterLogo(size: 100),
                const SizedBox(height: 30.0),

                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    prefixIcon: Icon(Icons.email, color: blueThemeColor),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible, // Use _passwordVisible here
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    prefixIcon: Icon(Icons.lock, color: blueThemeColor),
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
                const SizedBox(height: 20.0),

                // Login Button
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Attempt to sign in the user with Firebase Authentication
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      // Check if email is verified
                      var user = FirebaseAuth.instance.currentUser;
                      if (user != null && !user.emailVerified) {
                        // If not verified, show a message or handle accordingly
                        // For example, sign the user out and ask them to verify their email
                        await FirebaseAuth.instance.signOut();
                        // Show a message to the user about email verification
                      } else {
                        // Navigate back to MyHomePage which will check the auth status and show the appropriate page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MyHomePage()),
                          (Route<dynamic> route) => false,
                          );
                      }
                    } on FirebaseAuthException catch (e) {
                      // If sign in fails, display an alert dialog with the error
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Login Failed"),
                          content: Text(e.message ?? "An unknown error occurred"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: const Text("Okay"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    foregroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                    child: Text('Log in', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Sign up TextButton
                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Sign up',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to createAccount.dart
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateAccount()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
