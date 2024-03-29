import 'package:flutter/material.dart';
import 'createAccount.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _passwordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    
    Color blueThemeColor = Colors.blue.shade300;
    TextStyle linkStyle = TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold);

    return Scaffold(
      
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                const FlutterLogo(size: 100),
                const SizedBox(height: 30.0),

                
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

                
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
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

                
                ElevatedButton(
                  onPressed: () async {
                    try {
                      
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      
                      var user = FirebaseAuth.instance.currentUser;
                      if (user != null && !user.emailVerified) {
                        
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
                          backgroundColor: Colors.white,
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
