import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'AllComments.dart';
import 'package:vibration/vibration.dart';

class MyPosts extends StatefulWidget {
  const MyPosts({Key? key}) : super(key: key);

  @override
  _MyPostsState createState() => _MyPostsState();
}

class _MyPostsState extends State<MyPosts> {
  String? selectedCardId;

  Future<Map<String, List<Map<String, dynamic>>>> fetchUserImages() async {
    final user = FirebaseAuth.instance.currentUser;
    final List<Map<String, dynamic>> images = [];

    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('uploader', isEqualTo: user.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        var imageData = doc.data() as Map<String, dynamic>;
        imageData['id'] = doc.id; 
        imageData['timestamp'] = doc['timestamp']; 
        images.add(imageData);
      }
    }

    // Sort images by timestamp in descending order before grouping
    images.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    // After fetching and sorting images, group them by date
    final Map<String, List<Map<String, dynamic>>> groupedImages = {};
    for (var image in images) {
      final timestamp = image['timestamp'] as Timestamp;
      final formattedDate = DateFormat('MM/dd/yyyy').format(timestamp.toDate());
      groupedImages.putIfAbsent(formattedDate, () => []).add(image);
    }
    return groupedImages;
  }

  Future<void> deleteImage(String imageId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('images').doc(imageId).delete();

    // Delete all comments associated with the image
    var commentsSnapshot = await firestore.collection('comments').doc(imageId).collection('imageComments').get();
    for (var doc in commentsSnapshot.docs) {
      await doc.reference.delete();

      // Delete all votes associated with each comment
      await firestore.collection('votes').doc(doc.id).delete();
    }

    // Delete the image from favorites
    await firestore.collection('favorites').doc(imageId).delete();

    // Trigger a state update to reflect changes in the UI
    setState(() {
      // This is a simple way to refresh the UI after deletion
    });
  }

  // Add a method to refresh the posts
  void refreshPosts() {
    setState(() {
      // This will trigger a rebuild of the widget, effectively refreshing the posts
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Posts'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: fetchUserImages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No posts found.'));
                }
                final groupedImages = snapshot.data!;
                return ListView.builder(
                  itemCount: groupedImages.keys.length,
                  itemBuilder: (context, index) {
                    String date = groupedImages.keys.elementAt(index);
                    List<Map<String, dynamic>> imagesForDate = groupedImages[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(date, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        GridView.count(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(), 
                          childAspectRatio: 0.8, 
                          children: imagesForDate.map((image) {
                            return ImageCard(
                              key: ValueKey(image['id']),
                              image: image,
                              onDelete: () => deleteImage(image['id']),
                              onSelect: () {},
                              isSelected: selectedCardId == image['id'], 
                              updateSelectedCardId: (String? id) { 
                                setState(() {
                                  selectedCardId = id;
                                });
                              },
                              refreshPosts: refreshPosts, 
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Text(
              "Long press on a post to delete it.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageCard extends StatefulWidget {
  final Map<String, dynamic> image;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final bool isSelected;
  final Function(String?) updateSelectedCardId;
  final Function refreshPosts;

  const ImageCard({
    Key? key,
    required this.image,
    required this.onDelete,
    required this.onSelect,
    required this.isSelected,
    required this.updateSelectedCardId,
    required this.refreshPosts,
  }) : super(key: key);

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  bool _isDeleteIconVisible = false; 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllComments(
              imageUrl: widget.image['imageUrl'],
              imageId: widget.image['id'],
            ),
          ),
        ).then((_) {
          setState(() {
            _isDeleteIconVisible = false; 
          });
          widget.refreshPosts(); 
        });
      },
      onLongPress: () async {
        // Toggle the visibility of the delete icon on long press
        setState(() {
          _isDeleteIconVisible = !_isDeleteIconVisible;
        });
        // Check if the device can vibrate and provide feedback
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        }
      },
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Image.network(widget.image['imageUrl'], fit: BoxFit.cover),
                ),
              ],
            ),
          ),
          if (_isDeleteIconVisible) // Show delete icon if _isDeleteIconVisible is true
            Positioned(
              right: 4,
              top: 4,
              child: CircleAvatar(
                backgroundColor: Colors.white, // White circular background
                child: IconButton(
                  icon: Image.asset('assets/images/Upload/trash_can.gif'),
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Image.asset('assets/images/Upload/trash_can.gif', width: 20, height: 20),
                            SizedBox(width: 8), 
                            Text('Confirm'),
                          ],
                        ),
                        content: Text('Are you sure you want to delete this post?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                              widget.onDelete();
                            },
                            child: Text('Yes'),
                          ),
                        ],
                      ),
                    ).then((result) {
                      if (result ?? false) {
                        // Hide the delete icon after deletion
                        setState(() {
                          _isDeleteIconVisible = false;
                        });
                      }
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
