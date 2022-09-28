import 'package:flutter/material.dart';
import 'package:test1/home.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class Login extends StatelessWidget{
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Login Page"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("img/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TextFormField(
              controller: username,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your login',
              ),
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your password',
              ),
            ),
          ],
        ),/* add child content here */
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}