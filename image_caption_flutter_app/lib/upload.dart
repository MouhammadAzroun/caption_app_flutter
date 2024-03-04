import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final ImagePicker _picker = ImagePicker();

  Future<void> uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
        String imageUrl = await snapshot.ref.getDownloadURL();
        saveImageUrl(imageUrl, userId);
      } catch (e) {
        print(e);
      }
    }
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
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadImage,
          child: const Text('Upload Image'),
        ),
      ),
    );
  }
}
