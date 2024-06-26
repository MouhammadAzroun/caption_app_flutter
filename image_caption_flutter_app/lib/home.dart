import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'allComments.dart';
import 'searchedUser.dart';

class Home extends StatelessWidget {
  Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('images').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data?.docs ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    TextEditingController commentController = TextEditingController();
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(10), 
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, String>>(
                                      future: getUserInfo(items[index]['uploader']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: AssetImage('assets/images/Avatars/default.png'),
                                            ),
                                            title: Text('Loading username...'),
                                          );
                                        }
                                        return GestureDetector(
                                          onTap: () {
                                            fetchUserDataById(items[index]['uploader']).then((userData) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => SearchedUser(user: userData, userId: items[index]['uploader'])),
                                              );
                                            });
                                          },
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: AssetImage(snapshot.data!['avatar'] ?? 'assets/images/Avatars/default.png'),
                                            ),
                                            title: Text(snapshot.data!['username'] ?? 'Unknown User'),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => showImagePreview(context, items[index]['imageUrl']),
                                      child: Image.network(items[index]['imageUrl'], width: double.infinity, height: 300, fit: BoxFit.cover),
                                    ),
                                    SizedBox(height: 8),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance.collection('comments').doc(items[index].id).collection('imageComments').orderBy('timestamp').snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator());
                                        }
                                        final comments = snapshot.data?.docs ?? [];
                                        if (comments.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("No captions have been written on this image", style: TextStyle(color: Colors.grey)),
                                          );
                                        }
                                        return FutureBuilder<QueryDocumentSnapshot?>(
                                          future: _getTopCommentByLikes(comments),
                                          builder: (context, topCommentSnapshot) {
                                            if (!topCommentSnapshot.hasData) {
                                              return Center(child: CircularProgressIndicator());
                                            }
                                            final topComment = topCommentSnapshot.data;
                                            if (topComment == null) {
                                              return SizedBox.shrink(); 
                                            }
                                            return FutureBuilder<Map<String, String>>(
                                              future: getUserInfo(topComment['commenter']),
                                              builder: (context, userSnapshot) {
                                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage: AssetImage('assets/images/Avatars/default.png'),
                                                    ),
                                                    title: Text('Loading username...'),
                                                    subtitle: Text(topComment['text']),
                                                  );
                                                }
                                                return GestureDetector(
                                                  onTap: () {
                                                    fetchUserDataById(topComment['commenter']).then((userData) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => SearchedUser(user: userData, userId: topComment['commenter']),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                  child: StreamBuilder<DocumentSnapshot>(
                                                    stream: FirebaseFirestore.instance.collection('votes').doc(topComment.id).snapshots(),
                                                    builder: (context, voteSnapshot) {
                                                      if (!voteSnapshot.hasData) {
                                                        return ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundImage: AssetImage(userSnapshot.data!['avatar'] ?? 'assets/images/Avatars/default.png'),
                                                          ),
                                                          title: Text(userSnapshot.data!['username'] ?? 'Unknown User'),
                                                          subtitle: Text(topComment['text']),
                                                          trailing: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Image.asset('assets/images/Emojis/sleeping.png', width: 24), 
                                                              SizedBox(width: 8),
                                                              Text('...', style: TextStyle(fontWeight: FontWeight.bold)), 
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                      Map<String, dynamic> votes = voteSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                                                      int voteCount = votes.length;
                                                      bool hasVoted = votes.containsKey(FirebaseAuth.instance.currentUser?.uid);
                                                      return ListTile(
                                                        leading: CircleAvatar(
                                                          backgroundImage: AssetImage(userSnapshot.data!['avatar'] ?? 'assets/images/Avatars/default.png'),
                                                        ),
                                                        title: Text(userSnapshot.data!['username'] ?? 'Unknown User'),
                                                        subtitle: Text(topComment['text']),
                                                        trailing: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            FirebaseAuth.instance.currentUser != null ? IconButton(
                                                              icon: Image.asset(hasVoted ? 'assets/images/Emojis/laughing.png' : 'assets/images/Emojis/sleeping.png', width: 24),
                                                              onPressed: () {
                                                                upvoteComment(topComment.id, FirebaseAuth.instance.currentUser!.uid);
                                                              },
                                                            ) : Image.asset('assets/images/Emojis/sleeping.png', width: 24),
                                                            SizedBox(width: 8), 
                                                            Text('$voteCount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AllComments(imageUrl: items[index]['imageUrl'], imageId: items[index].id)),
                                        );
                                      },
                                      child: Text('All captions...', style: TextStyle(color: Colors.blue)),
                                    ),
                                    SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: FirebaseAuth.instance.currentUser != null ? TextField(
                                        controller: commentController,
                                        decoration: InputDecoration(
                                          labelText: 'Add a caption...',
                                          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0), 
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30.0), 
                                            borderSide: BorderSide(width: 0.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30.0),
                                            borderSide: BorderSide(width: 0.5, color: const Color.fromARGB(255, 30, 30, 30)), 
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30.0),
                                            borderSide: BorderSide(width: 1, color: Colors.blue), 
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(Icons.send, color: Colors.blue),
                                            onPressed: () {
                                              final currentUser = FirebaseAuth.instance.currentUser;
                                              if (commentController.text.trim().isNotEmpty && currentUser != null) {
                                                addComment(items[index].id, commentController.text.trim(), currentUser.uid);
                                                commentController.clear(); 
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Caption submitted.')),
                                                );
                                                FocusScope.of(context).unfocus();
                                              }
                                            },
                                          ),
                                        ),
                                      ) : SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseAuth.instance.currentUser?.uid != null ? FirebaseFirestore.instance.collection('favorites').doc(items[index].id).snapshots() : Stream.empty(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                Map<String, dynamic> favorites = snapshot.data!.data() as Map<String, dynamic>;
                                bool isFavorited = favorites.containsKey(FirebaseAuth.instance.currentUser!.uid) && favorites[FirebaseAuth.instance.currentUser!.uid] == true;
                                return IconButton(
                                  icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: isFavorited ? Colors.red : Color.fromARGB(255, 173, 173, 173)),
                                  onPressed: () => toggleFavorite(items[index].id),
                                );
                              } else {
                                return IconButton(
                                  icon: Icon(Icons.favorite_border, color: Color.fromARGB(255, 173, 173, 173)),
                                  onPressed: () => toggleFavorite(items[index].id),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: items.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 10), 
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> addComment(String imageId, String text, String userId) async {
    await FirebaseFirestore.instance.collection('comments').doc(imageId).collection('imageComments').add({
      'commenter': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upvoteComment(String commentId, String userId) async {
    DocumentReference commentVoteRef = FirebaseFirestore.instance.collection('votes').doc(commentId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(commentVoteRef);

      if (!snapshot.exists) {
        transaction.set(commentVoteRef, {userId: true});
      } else {
        Map<String, dynamic> data = snapshot.data()! as Map<String, dynamic>;
        if (data[userId] == true) {
          transaction.update(commentVoteRef, {userId: FieldValue.delete()});
        } else {
          transaction.update(commentVoteRef, {userId: true});
        }
      }
    });
  }

  Future<int> getVoteCount(String commentId) async {
    DocumentSnapshot voteSnapshot = await FirebaseFirestore.instance.collection('votes').doc(commentId).get();

    if (voteSnapshot.exists) {
      Map<String, dynamic> votes = voteSnapshot.data() as Map<String, dynamic>;
      // Count how many fields are in the document, each field represents an upvote
      int voteCount = votes.length;
      return voteCount;
    } else {
      return 0;
    }
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

  Future<QueryDocumentSnapshot?> _getTopCommentByLikes(List<QueryDocumentSnapshot> comments) async {
    QueryDocumentSnapshot? topComment;
    int maxLikes = -1;
    for (var comment in comments) {
      final likeCount = await getVoteCount(comment.id);
      if (likeCount > maxLikes) {
        maxLikes = likeCount;
        topComment = comment;
      }
    }
    return topComment;
  }

  Future<void> toggleFavorite(String imageId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance.collection('favorites').doc(imageId);

    final doc = await docRef.get();
    if (doc.exists) {
      // Check if the current user has already favorited the image
      if (doc.data()![userId] == true) {
        // If yes, remove the favorite by deleting the user's ID from the document
        await docRef.update({userId: FieldValue.delete()});
      } else {
        // If not, add the favorite by setting the user's ID to true
        await docRef.update({userId: true});
      }
    } else {
      // If the document doesn't exist, create it and set the user's ID to true
      await docRef.set({userId: true});
    }
  }

  void showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer( // Allows users to pinch-to-zoom
              panEnabled: false,
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

  Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()! as Map<String, dynamic>;
    } else {
      return {
        'username': 'Unknown User',
        'avatar': 'assets/images/Avatars/default.png',
      };
    }
  }
}