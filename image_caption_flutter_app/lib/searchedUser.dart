import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'allComments.dart';

class SearchedUser extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId; 

  const SearchedUser({Key? key, required this.user, required this.userId}) : super(key: key); 

  Future<List<Map<String, dynamic>>> fetchUserImages(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('images')
        .where('uploader', isEqualTo: userId)
        .get();
    var images = querySnapshot.docs
        .map((doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id, 
             })
        .toList();

    // Sort images by timestamp in descending order
    images.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, 
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(user['avatar']),
                      radius: 35, 
                    ),
                  ),
                  SizedBox(width: 20), 
                  Text(
                    user['username'],
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchUserImages(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text("No images uploaded by this user.");
                  }
                  final images = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      crossAxisSpacing: 4.0, 
                      mainAxisSpacing: 4.0, 
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final image = images[index];
                      final timestamp = image['timestamp'] as Timestamp; 
                      final formattedDate = DateFormat('MM/dd/yyyy').format(timestamp.toDate());
                      return GridTile(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AllComments(imageUrl: image['imageUrl'], imageId: image['id'])),
                            );
                          },
                          child: Image.network(image['imageUrl'], fit: BoxFit.cover),
                        ),
                        footer: Container(
                          padding: EdgeInsets.all(4.0),
                          color: Colors.black54,
                          child: Text(
                            formattedDate,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}