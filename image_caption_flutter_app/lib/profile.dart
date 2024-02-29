import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

class Profile extends StatefulWidget {
  final Function(String) onAvatarUpdated;
  const Profile({Key? key, required this.onAvatarUpdated}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userData;
  TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: 'Enter new username'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                if (_usernameController.text.isNotEmpty) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'username': _usernameController.text,
                    });
                    setState(() {
                      userData!['username'] = _usernameController.text;
                    });
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateUserAvatar(String path) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'avatar': path,
      });
      widget.onAvatarUpdated(path); // Call the callback function
      fetchUserData(); // Assuming fetchUserData() fetches the latest user data and updates the UI
    }
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
                    updateUserAvatar(path);
                    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: userData == null
            ? CircularProgressIndicator() // Show loading indicator while data is being fetched
            : SingleChildScrollView( // Allows for scrolling if content doesn't fit
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40), // Add some spacing at the top
                    Center( // Center the stack in the middle of the screen
                      child: Stack(
                        alignment: Alignment.bottomRight, // Position the edit icon at the bottom right of the avatar
                        children: [
                          CircleAvatar(
                            radius: 70, // Increase the radius size here
                            backgroundColor: Colors.blue.shade100, // Changed to blue theme
                            child: userData!['avatar'] != null 
                                ? ClipOval(
                                    child: Image.asset(
                                      userData!['avatar'],
                                      fit: BoxFit.cover,
                                      width: 140.0, // Increase the width to match the new radius
                                      height: 140.0, // Increase the height to match the new radius
                                    ),
                                  )
                                : Icon(
                                    Icons.person, // Default icon
                                    size: 70, // Adjust the size of the icon to match the new radius
                                    color: Colors.white, // Icon color
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
                    SizedBox(height: 20), // Add some spacing
                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Adjust margins as needed
                      child: ListTile(
                        title: Text('Username'),
                        subtitle: Text(userData!['username'] ?? 'Not available'),
                        leading: Icon(Icons.person, color: Colors.blue), // Changed to blue theme
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _changeUsername(context),
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: ListTile(
                        title: Text('Email'),
                        subtitle: Text(userData!['email'] ?? 'Not available'),
                        leading: Icon(Icons.email, color: Colors.blue), // Changed to blue theme
                      ),
                    ),
                    // Add more fields as needed
                    SizedBox(height: 20), // Add some spacing
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MyHomePage()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Use a more vibrant blue
                        foregroundColor: Colors.white, // Ensure text is white
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), // Adjust padding
                        textStyle: TextStyle(
                          fontSize: 16, // Adjust font size
                          fontWeight: FontWeight.bold, // Make text bold
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                    SizedBox(height: 20), // Add some spacing
                    ElevatedButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          try {
                            // First, delete the user data from Firestore
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                            
                            // Then, delete the user account from Firebase Authentication
                            await user.delete();
                            
                            // After deleting both the user data and account, sign out the user
                            await FirebaseAuth.instance.signOut();
                            
                            // Finally, navigate the user back to the MyHomePage or a login screen
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MyHomePage()),
                              (Route<dynamic> route) => false,
                            );
                          } catch (e) {
                            print("Error deleting account and user data: $e");
                            // Handle errors, such as showing an error message to the user
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, // Use a red color for delete action
                        foregroundColor: Colors.white, // Ensure text is white
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), // Adjust padding
                        textStyle: TextStyle(
                          fontSize: 16, // Adjust font size
                          fontWeight: FontWeight.bold, // Make text bold
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
