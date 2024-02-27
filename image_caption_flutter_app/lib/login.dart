import 'package:flutter/material.dart';
import 'createAccount.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // This line is removed
import 'main.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _passwordVisible = false; // Add this line
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
                FlutterLogo(size: 100),
                SizedBox(height: 30.0),

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
                SizedBox(height: 16.0),

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
                SizedBox(height: 20.0),

                // Login Button
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Attempt to sign in the user with Firebase Authentication
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      // Navigate back to MyHomePage which will check the auth status and show the appropriate page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                        );
                    } on FirebaseAuthException catch (e) {
                      // If sign in fails, display an alert dialog with the error
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text("Login Failed"),
                          content: Text(e.message ?? "An unknown error occurred"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: Text("Okay"),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                    child: Text('Log in', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20.0),

                // Sign up TextButton
                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Sign up',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to createAccount.dart
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateAccount()),
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
