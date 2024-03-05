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
        title: const Text('Upload Image'),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: _imageFile == null
                        ? Image.asset(
                            'assets/images/Upload/upload.png',
                            width: 300,
                            height: 300,
                          )
                        : Image.file(
                            _imageFile!,
                            width: 300,
                            height: 300,
                          ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select an Image',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your image will be stored securely.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: uploadImageToFirestore,
                icon: Icon(Icons.cloud_upload),
                label: Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

