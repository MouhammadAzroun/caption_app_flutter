import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'searchedUser.dart'; 

class AllComments extends StatelessWidget {
  final String imageUrl;
  final String imageId;
  const AllComments({super.key, required this.imageUrl, required this.imageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All captions'),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => showImagePreview(context, imageUrl), // Use the imageUrl passed to the AllComments widget
            child: Image.network(imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchAndSortCommentsByLikes(imageId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return FutureBuilder<Map<String, String>>(
                      future: getUserInfo(comment['commenter']),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        return GestureDetector(
                          onTap: () {
                            fetchUserDataById(comment['commenter']).then((userData) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchedUser(user: userData, userId: comment['commenter']),
                                ),
                              );
                            });
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(userSnapshot.data!['avatar']!),
                            ),
                            title: Text(userSnapshot.data!['username'] ?? 'Unknown'),
                            subtitle: Text(comment['text'] ?? ''),
                            trailing: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('votes').doc(comment.id).snapshots(),
                              builder: (context, voteSnapshot) {
                                if (!voteSnapshot.hasData) {
                                  return Text('...');
                                }
                                Map<String, dynamic> votes = voteSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                                int voteCount = votes.length;
                                bool hasVoted = votes.containsKey(FirebaseAuth.instance.currentUser?.uid);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: hasVoted ? Image.asset('assets/images/Emojis/laughing.png', width: 24) : Image.asset('assets/images/Emojis/sleeping.png', width: 24),
                                      onPressed: () => upvoteComment(comment.id, FirebaseAuth.instance.currentUser!.uid),
                                    ),
                                    Text('$voteCount'),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10), // Adds padding around the dialog
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer( // Allows users to pinch-to-zoom
              panEnabled: false, // Set it to false to prevent panning.
              boundaryMargin: EdgeInsets.all(80),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> fetchAndSortCommentsByLikes(String imageId) async {
    var commentsSnapshot = await FirebaseFirestore.instance.collection('comments').doc(imageId).collection('imageComments').get();
    List<QueryDocumentSnapshot> comments = commentsSnapshot.docs;

    List<Map<String, dynamic>> commentsWithLikes = [];
    for (var comment in comments) {
      var likeCount = await getVoteCount(comment.id);
      commentsWithLikes.add({
        'comment': comment,
        'likeCount': likeCount,
      });
    }

    commentsWithLikes.sort((a, b) => b['likeCount'].compareTo(a['likeCount']));

    List<QueryDocumentSnapshot> sortedComments = commentsWithLikes.map((e) => e['comment'] as QueryDocumentSnapshot).toList();

    return sortedComments;
  }

  Future<int> getVoteCount(String commentId) async {
    var voteSnapshot = await FirebaseFirestore.instance.collection('votes').doc(commentId).get();
    if (!voteSnapshot.exists) {
      return 0;
    }
    Map<String, dynamic> votes = voteSnapshot.data() as Map<String, dynamic>;
    return votes.length;
  }

  Future<Map<String, String>> getUserInfo(String commenterId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(commenterId).get();
    Map<String, String> userInfo = {
      'username': userDoc['username'] ?? 'Unknown',
      'avatar': userDoc['avatar'] ?? 'default_avatar.png',
    };
    return userInfo;
  }

  Future<void> upvoteComment(String commentId, String userId) async {
    final docRef = FirebaseFirestore.instance.collection('votes').doc(commentId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        transaction.set(docRef, {userId: true});
      } else {
        Map<String, dynamic> votes = snapshot.data() as Map<String, dynamic>;
        if (votes.containsKey(userId)) {
          transaction.update(docRef, {userId: FieldValue.delete()});
        } else {
          transaction.update(docRef, {userId: true});
        }
      }
    });
  }

  Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic> userData = {
      'username': userDoc['username'] ?? 'Unknown',
      'avatar': userDoc['avatar'] ?? 'default_avatar.png',
    };
    return userData;
  }
}