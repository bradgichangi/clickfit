import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';
import 'package:intl/intl.dart';
class userMessaging extends StatefulWidget {
  final String email, recipientEmail, recipientName;

  userMessaging(
      {Key? key,
      required this.email,
      required this.recipientEmail,
      required this.recipientName})
      : super(key: key);

  @override
  _userMessagingState createState() =>
      _userMessagingState(email, recipientEmail, recipientName);
}

class _userMessagingState extends State<userMessaging> {
  final String email, recipientEmail, recipientName;

  _userMessagingState(this.email, this.recipientEmail, this.recipientName);

  TextEditingController message = TextEditingController();

  Future<List<Message>> readMessages() async {
    List<Message> messages = [];
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(email)
        .collection(recipientEmail)
        .orderBy("createdAt")
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        Message message = Message(result.data()['sender'].toString(),
            result.data()['text'].toString(),
            email == result.data()['sender'].toString() ? "Sender" : "Recipient",
            DateFormat.Hm().format(result.data()['createdAt'].toDate()));
        messages.add(message);
      });
    });
    return messages;
  }


  writeMessage() async {
    FirebaseFirestore.instance
        .collection("messages")
        .doc(email)
        .set({
      recipientEmail : recipientEmail
    },SetOptions(merge: true)).then((value) {
    });
    FirebaseFirestore.instance
        .collection("messages")
        .doc(email)
        .collection(recipientEmail)
        .doc()
        .set({
      "sender": email,
      "text": message.text,
      "createdAt" : FieldValue.serverTimestamp()
    }).then((value) {
    });
    FirebaseFirestore.instance
        .collection("messages")
        .doc(recipientEmail)
        .collection(email)
        .doc()
        .set({
      "sender": email,
      "text": message.text,
      "createdAt" : FieldValue.serverTimestamp(),
    }).then((value) {
    });
  }

  Future<List<User>> getUserInfo() async {
    List<User> users = [];
    await FirebaseFirestore.instance
        .collection("userinfo")
        .where('email', isEqualTo: recipientEmail)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        User user = User(
            result.data()['name'].toString(),
            result.data()['email'].toString(),
            result.data()['image'].toString());
        users.add(user);
      });
    });
    return users;
  }

  @override
  Widget build(BuildContext context) {
    readMessages();
    getUserInfo();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: getUserInfo(),
              builder: (BuildContext context, AsyncSnapshot snapshot){
                if(snapshot.data == null){
                  return Container(
                      child: Center(child: Text(""))
                  );
                }
                else{
                  return Image.network(snapshot.data[0].image_url,fit: BoxFit.contain,
                    height: 32,);
                }
              },
            ),
            Container(
                padding: const EdgeInsets.all(8.0), child: Text(new ReCase(recipientName).titleCase)
            )
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: getUserInfo(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return Container(child: Center(child: Text("Loading...")));
              } else {
                return Container(child: Column(children: <Widget>[]));
              }
            },
          ),
          FutureBuilder(
            future: readMessages(),
            builder: (BuildContext context, AsyncSnapshot snapshot2) {
              var count;
              snapshot2.hasData ? count = snapshot2.data.length : count = 0;
              return Expanded(
                child: ListView.builder(
                    itemCount: count,
                    itemBuilder: (BuildContext context, int index) {
                      if (snapshot2.data == null) {
                        return Container(
                            child: Center(child: Text("No messages")));
                      } else {
                        if (snapshot2.data[index].userType == "Sender") {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                            children : [
                              Bubble(
                                margin: BubbleEdges.only(top: 10),
                                alignment: Alignment.topLeft,
                                nip: BubbleNip.leftTop,
                                color: Color.fromRGBO(255, 240, 214, 1.0),
                                child: Text(snapshot2.data[index].text),
                              ),
                              Text(snapshot2.data[index].dateTime, textAlign: TextAlign.left, style: TextStyle(fontSize: 10.0))
                            ]
                          );
                        } else {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                            children : [
                              Bubble(
                                margin: BubbleEdges.only(top: 10),
                                alignment: Alignment.topRight,
                                nip: BubbleNip.rightTop,
                                color: Color.fromRGBO(250, 130, 146, 1.0),
                                child: Text(snapshot2.data[index].text, textAlign: TextAlign.right),
                              ),
                              Text(snapshot2.data[index].dateTime, textAlign: TextAlign.right, style: TextStyle(fontSize: 10.0))
                            ]
                            );
                        }
                      }
                    }),
              );
            },
          ),
          TextFormField(
            controller: message,
            decoration: const InputDecoration(
              labelText: 'Enter message here',
            ),
            onFieldSubmitted: (value){
              writeMessage();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class User {
  final String name;
  final String email;
  final String image_url;

  User(this.name, this.email, this.image_url);
}

class Message {
  String sender;
  final String text;
  String userType;
  String dateTime;

  Message(this.sender, this.text, this.userType, this.dateTime);
}
