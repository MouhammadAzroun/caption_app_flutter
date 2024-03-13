import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'searchedUser.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: searchQuery.isNotEmpty 
                  ? FirebaseFirestore.instance.collection('users')
                      .where('username', isGreaterThanOrEqualTo: searchQuery)
                      .where('username', isLessThanOrEqualTo: searchQuery + '\uf8ff')
                      .snapshots()
                  : Stream.empty(),
              builder: (context, snapshot) {
                if (searchQuery.isEmpty) {
                  return Center(
                    child: Text("Search for user by username"),
                  );
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index].data() as Map<String, dynamic>;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchedUser(user: user, userId: users[index].id)),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(user['avatar']),
                        ),
                        title: Text(user['username']),
                      ),
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
}
