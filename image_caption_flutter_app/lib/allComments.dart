import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'searchedUser.dart'; 

class AllComments extends StatefulWidget {
  final String imageUrl;
  final String imageId;

  AllComments({super.key, required this.imageUrl, required this.imageId});

  @override
  _AllCommentsState createState() => _AllCommentsState();
}

class _AllCommentsState extends State<AllComments> {
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All captions'),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => showImagePreview(context, widget.imageUrl),
            child: Image.network(widget.imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchAndSortCommentsByLikes(widget.imageId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data() as Map<String, dynamic>;
                    return FutureBuilder<Map<String, String>>(
                      future: getUserInfo(commentData['commenter']),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        return GestureDetector(
                          onTap: () {
                            fetchUserDataById(commentData['commenter']).then((userData) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchedUser(user: userData, userId: commentData['commenter']),
                                ),
                              );
                            });
                          },
                          onLongPress: () {
                            _showCommentOptions(context, comments[index].id, commentData['text'], widget.imageId, commentData['commenter']);
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(userSnapshot.data!['avatar']!),
                            ),
                            title: Text(userSnapshot.data!['username'] ?? 'Unknown'),
                            subtitle: Text(commentData['text'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance.collection('votes').doc(comments[index].id).snapshots(),
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
                                          onPressed: () => upvoteComment(comments[index].id, FirebaseAuth.instance.currentUser!.uid),
                                        ),
                                        Text('$voteCount'),
                                      ],
                                    );
                                  },
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Add a comment...',
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
                      addComment(widget.imageId, commentController.text.trim(), currentUser.uid);
                      commentController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Caption submitted.')),
                      );
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    }
                  },
                ),
              ),
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
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
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

  Future<void> addComment(String imageId, String text, String userId) async {
    await FirebaseFirestore.instance.collection('comments').doc(imageId).collection('imageComments').add({
      'commenter': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showCommentOptions(BuildContext context, String commentId, String currentText, String imageId, String commenterId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        List<Widget> options = [];
        
        
        if (currentUser?.uid == commenterId) {
          options.addAll([
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editComment(context, commentId, currentText, imageId);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(imageId, commentId);
              },
            ),
          ]);
        }
        
      
        options.add(ListTile(
          leading: Icon(Icons.copy),
          title: Text('Copy'),
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: currentText)).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Comment copied to clipboard.')),
              );
            });
          },
        ));
        
        return SafeArea(
          child: Wrap(
            children: options,
          ),
        );
      },
    );
  }

  Future<void> _editComment(BuildContext context, String commentId, String currentText, String imageId) async {
    String? newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _editController = TextEditingController(text: currentText);
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: _editController,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(_editController.text);
              },
            ),
          ],
        );
      },
    );

    if (newText != null && newText.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('comments').doc(imageId).collection('imageComments').doc(commentId).update({
        'text': newText.trim(),
      });
      setState(() {});
    }
  }

  Future<void> _deleteComment(String imageId, String commentId) async {
    await FirebaseFirestore.instance.collection('comments').doc(imageId).collection('imageComments').doc(commentId).delete();
    setState(() {});
  }
}