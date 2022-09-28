import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:test1/home.dart';
import 'package:test1/messages.dart';
import 'package:test1/profile_client.dart';
import 'package:test1/profile_trainer.dart';
import 'package:test1/search.dart';


class MainScreen extends StatefulWidget{
  final String email;

  const MainScreen({Key? key, required this.email}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState(email: email);
}

class _MainScreenState extends State<MainScreen>{
  final String email;
  _MainScreenState({Key? key, required this.email});


  int pageIndex = 0;
  bool isTrainer = false;
  Future home(BuildContext context) async{
    await FirebaseFirestore.instance.collection("userinfo").where('email', isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        if(result.data()['type'].toString() == "Trainer") {
          isTrainer = true;
        } else {
          isTrainer = false;
        }
      });
    });
  }

  Widget getPage(int index) {
    home(context);
    switch (index){
      case 0:
        return HomeScreen(email: email);

      case 1:
        return Search(email: email);

      case 2:
        return Messages(email: email);

      case 3:
        if(isTrainer) {
          return Profile_Trainer_Screen(email: email);
        } else {
          return Profile_Client_Screen(email: email);
        }

      default:
        return HomeScreen(email: email);
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getPage(pageIndex),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
    currentIndex: pageIndex,
    onTap: (value){
      setState(() {
        pageIndex = value;
      });
    },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          backgroundColor: Colors.red,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
          backgroundColor: Colors.green,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.messenger_rounded),
          label: 'Messages',
          backgroundColor: Colors.purple,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
          backgroundColor: Colors.pink,
        ),
      ],
    ),
    );
  }

}