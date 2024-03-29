import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'allComments.dart';

class Favorites extends StatelessWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: userId == null
          ? Center(child: Text('Please log in to view favorites.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('favorites').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final favoriteDocs = snapshot.data?.docs.where((doc) {
                  final docData = doc.data() as Map<String, dynamic>?;
                  return docData?.containsKey(userId) == true && docData![userId] == true;
                }).toList() ?? [];

                return ListView.builder(
                  itemCount: favoriteDocs.length,
                  itemBuilder: (context, index) {
                    final favoriteId = favoriteDocs[index].id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('images').doc(favoriteId).get(),
                      builder: (context, itemSnapshot) {
                        if (itemSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!itemSnapshot.hasData) {
                          return ListTile(
                            title: Text('Item not found'),
                          );
                        }

                        final itemData = itemSnapshot.data!.data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AllComments(imageUrl: itemData['imageUrl'], imageId: favoriteId)),
                            );
                          },
                          child: Card(
                            elevation: 5, // Adds shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15), 
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5), 
                            color: Colors.white,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                  child: Image.network(itemData['imageUrl'], width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<Map<String, String>>(
                                          future: getUserInfo(itemData['uploader']),
                                          builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold));
                                            } else if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
                                            } else {
                                              return Text(snapshot.data!['username'] ?? 'Unknown User', style: TextStyle(fontWeight: FontWeight.bold));
                                            }
                                          },
                                        ),
                                        SizedBox(height: 5),
                                        Text('Tap to view comments', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => removeFavorite(favoriteId),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<Map<String, String>> getUserInfo(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
      return {
        'username': userData['username'] ?? 'Unknown User',
        'avatar': userData['avatar'] ?? 'assets/images/Avatars/default.png',
      };
    } else {
      return {
        'username': 'Unknown User',
        'avatar': 'assets/images/Avatars/default.png',
      };
    }
  }

  Future<void> removeFavorite(String imageId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance.collection('favorites').doc(imageId);
    final doc = await docRef.get();
    if (doc.exists && doc.data()![userId] == true) {
      await docRef.update({userId: FieldValue.delete()});
    }
  }
}
