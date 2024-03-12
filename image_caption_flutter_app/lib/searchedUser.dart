import 'package:flutter/material.dart';

class SearchedUser extends StatelessWidget {
  final Map<String, dynamic> user;

  const SearchedUser({Key? key, required this.user}) : super(key: key);

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
            CircleAvatar(
              backgroundImage: AssetImage(user['avatar']),
              radius: 50,
            ),
            SizedBox(height: 20),
            Text(user['username'], style: Theme.of(context).textTheme.headline4),
            // Add more user details here
          ],
        ),
      ),
    );
  }
}