import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  // Function to pick an image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadImageToFirestore() async {
    if (_imageFile != null) {
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(_imageFile!);
        String imageUrl = await snapshot.ref.getDownloadURL();
        await saveImageUrl(imageUrl, userId);
        // After successful upload, show the alert dialog
        _showUploadSuccessDialog();
      } catch (e) {
        print(e);
      }
    }
  }

  void _showUploadSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Complete'),
          content: Text('Your picture has been published.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveImageUrl(String imageUrl, String userId) async {
    await FirebaseFirestore.instance.collection('images').add({
      'uploader': userId,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Image'),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white, // Light shade for the container
                  borderRadius: BorderRadius.circular(100), // Circular shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: _imageFile == null
                    ? Icon(
                        Icons.camera_alt,
                        color: Colors.blue,
                        size: 50,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.file(
                          _imageFile!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Tap to select an image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: uploadImageToFirestore,
              icon: Icon(Icons.cloud_upload),
              label: Text('Publish Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

