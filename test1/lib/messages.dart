import 'dart:html';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recase/recase.dart';
import 'package:test1/userMessaging.dart';


class Messages extends StatefulWidget {
  final String email;
  Messages({Key? key, required this.email}) : super(key: key);

  @override
  _MessagesState createState() => _MessagesState(email);
}

class _MessagesState extends State<Messages> {
  final String email;

_MessagesState(this.email);

  Future<List<User>>userSearch() async{
    List<User> users = [];
    List<String> recipients = [];
    var collection = FirebaseFirestore.instance.collection('messages');
    var docSnapshot = await collection.doc(email).get();
    if (docSnapshot.exists) {
      Map<String, dynamic>? responseJson = docSnapshot.data();
      for(int i = 0; i < docSnapshot.data()!.length; i++){
        recipients.add(responseJson!.values.elementAt(i));
      }
      await FirebaseFirestore.instance.collection("userinfo").where('email', whereIn: recipients).get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) {
          User user = User(result.data()['name'].toString(),
              result.data()['email'].toString(),
              result.data()['image'].toString(),"");
          users.add(user);

        });
      });
      for(int i = 0; i < users.length; i++){
        await FirebaseFirestore.instance
            .collection("messages")
            .doc(email)
            .collection(users[i].email)
            .orderBy("createdAt", descending: true).limit(1)
            .get()
            .then((querySnapshot) {
          users[i].text = querySnapshot.docs[0]["text"];
        });
      }
      }
    else{
      print("There are no messages");
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    userSearch();
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages"),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: userSearch(),
            builder: (BuildContext context, AsyncSnapshot snapshot){
              var count;
              snapshot.hasData ? count = snapshot.data.length : count = 0;
              return Expanded(
                child: ListView.builder(
                    itemCount: count,
                    itemBuilder: (BuildContext context, int index){
                      if(snapshot.data == null){
                        return Container(
                            child: Center(
                                child: Text("Loading...")
                            )
                        );
                      }else{
                        ReCase name = new ReCase(snapshot.data[index].name);
                        return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: Image.network(snapshot.data[index].image_url).image,
                            ),
                            title: Text(name.titleCase, style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            )),
                            subtitle: Text(snapshot.data[index].text, style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            )),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => userMessaging(email: email, recipientEmail: snapshot.data[index].email, recipientName: name.titleCase)));
                            }
                        );
                      }
                    }
                ),
              );
            },
          ),
        ]
      ),
    );
  }
}

class User {
  final String name;
  final String email;
  final String image_url;
  String text;


  User(this.name, this.email, this.image_url, this.text);
}