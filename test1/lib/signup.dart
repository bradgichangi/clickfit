import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


import 'dart:convert';

import 'package:test1/main_screen.dart';

class Signup extends StatelessWidget{
  TextEditingController email = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController password = TextEditingController();


  FirebaseAuth _auth = FirebaseAuth.instance;
  void register(String choice, BuildContext context) async{
    try{
      await _auth
          .createUserWithEmailAndPassword(email: email.text, password: password.text);
      User? user = _auth.currentUser;
      user!.updateDisplayName(name.text.toLowerCase());
      user.updatePhotoURL('https://firebasestorage.googleapis.com/v0/b/project-11459.appspot.com/o/images%2Fdefault_profile.png?alt=media&token=9ed8a36b-9e77-4d19-b092-2e189ec9bba7');
      FirebaseFirestore.instance
          .collection("userinfo")
          .doc(user.uid)
          .set({
        "email": email.text,
        "name": name.text.toLowerCase(),
        "bio": "",
        "image" : 'https://firebasestorage.googleapis.com/v0/b/project-11459.appspot.com/o/images%2Fdefault_profile.png?alt=media&token=9ed8a36b-9e77-4d19-b092-2e189ec9bba7',
        "type" : choice
      });
      print(email.text);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainScreen(email: email.text)),(Route<dynamic> route) => false);
    } on FirebaseAuthException catch(e){
      String error = "";
      if(e.code == 'weak-password'){
        error = 'The password provided is too weak';
      }
      else if(e.code == 'email-already-in-use'){
        error = 'The account already exists for that email';
      }
      else{
        error = "Invalid email";
      }
      Fluttertoast.showToast(
          msg: error,  // message
          toastLength: Toast.LENGTH_SHORT, // length
          gravity: ToastGravity.CENTER,    // location
          timeInSecForIosWeb: 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("img/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,

    children: <Widget>[
      Container(
        width: 700,
        child: Column(
          children: <Widget>[
            SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: email,
                  maxLength: 20,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  decoration: const InputDecoration(
                    fillColor: Color(0xF5383838),
                    filled: true,
                    counterText: "",
                    border: OutlineInputBorder(),
                    labelText: 'Enter your email',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: TextFormField(
                    controller: name,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                    decoration: const InputDecoration(
                      fillColor: Color(0xF5383838),
                      filled: true,
                      border: OutlineInputBorder(),
                      labelText: 'Enter your name',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: TextFormField(
                    controller: password,
                    maxLength: 20,
                    obscureText: true,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                    decoration: const InputDecoration(
                      fillColor: Color(0xF5383838),
                      filled: true,
                      counterText: "",
                      border: OutlineInputBorder(),
                      labelText: 'Enter your password',
                    ),
                  ),
                ),
              Padding(padding: EdgeInsets.only(top: 20),
              child:
                ElevatedButton(
                  child: Text('Sign Up Trainer'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  onPressed: () {
                    print('Pressed');
                    register("Trainer", context);
                  },
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 20),
                child:
                ElevatedButton(
                  child: Text('Sign Up Client'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 105, vertical: 15),
                  ),
                  onPressed: () {
                    print('Pressed');
                    register("Client", context);
                  },
                ),
              ),
              ],
            ),
        ),
        ],
      ),
      ),
    ],
    ),/* add child content here */
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

}