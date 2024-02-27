import 'package:flutter/material.dart';

class CreateAcount extends StatelessWidget {
  const CreateAcount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CreateAcount'),
      ),
      body: Center(
        child: Text('Welcome to the CreateAcount Page!'),
      ),
    );
  }
}
