import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:recase/recase.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:test1/edit_profile_trainer.dart';
import 'package:test1/userMessaging.dart';


class userProfile extends StatefulWidget {
  final String email, followingEmail, followingName;
  const userProfile({Key? key, required this.email, required this.followingEmail, required this.followingName}) : super(key: key);

  @override
  _userProfileState createState() => _userProfileState(email, followingEmail, followingName);
}

class _userProfileState extends State<userProfile> {
  final String email, followingEmail, followingName;

  _userProfileState(this.email, this.followingEmail, this.followingName);
  TextEditingController message = TextEditingController();

  bool isFollowing = false;
  String choice = "";

  Future<bool> followings() async{
    int num = 0;
    await FirebaseFirestore.instance.collection("followers")
        .where("user_email", isEqualTo: email)
        .where("following_email", isEqualTo: followingEmail).get().then((querySnapshot) {
      print(querySnapshot.size);
      num = querySnapshot.size;
    });
    if(num > 0) {
      isFollowing = true;
    } else {
      isFollowing = false;
    }
    return isFollowing;
  }

  followButton() async{
    if(!isFollowing){
      FirebaseFirestore.instance.collection('followers').add({
        'id' : "test",
        'user_email': email,
        'following_email': followingEmail,
      });
      print('Followed');
    }
    else{
      FirebaseFirestore.instance
          .collection("followers")
          .where("user_email", isEqualTo : email)
          .where("following_email", isEqualTo : followingEmail)
          .get().then((value){
        value.docs.forEach((element) {
          FirebaseFirestore.instance.collection("followers").doc(element.id).delete().then((value){
            print("Unfollowed");
          });
        });
      });
    }
    Timer(Duration(milliseconds: 200), (){
      setState((){
        isFollowing = !isFollowing;
      });
    });
  }


  String noOfFollowing = "";
  String noOfFollowers = "";
  getFollowing() async{
    var count = 0;
    await FirebaseFirestore.instance.collection("followers").where("user_email", isEqualTo: followingEmail).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        count ++;
      });
      print("No. of following: " + count.toString());
      noOfFollowing = count.toString();
    });
  }

  getFollowers() async{
    var count = 0;
    await FirebaseFirestore.instance.collection("followers").where("following_email", isEqualTo: followingEmail).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        //print("Read data:" + result.data().toString());
        count ++;
      });
    });
    print("No. of followers: " + count.toString());
    noOfFollowers = count.toString();
  }

  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<User>> getUserInfo() async{
    getFollowing();
    getFollowers();
    List<User> users = [];
    await FirebaseFirestore.instance.collection("userinfo").where("email", isEqualTo: followingEmail).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        User user = User(result.data()['name'].toString(), followingEmail, result.data()['image'].toString(), result.data()['bio'].toString(), noOfFollowers, noOfFollowing);
        users.add(user);
      });
    });
    print(users.length.toString() + " users");
    return users;
  }

  Future<List<Post>> getPosts() async{
    List<Post> posts = [];
    await FirebaseFirestore.instance.collection("posts").where("id", isEqualTo: followingEmail).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        Post post = Post(result.data()["id"].toString(), result.data()["text"].toString(), "", "");
        posts.add(post);
      });
    });
    print("No. of posts: " + posts.length.toString());
    return posts;
  }

  Future<List<Post>>posts() async{
    List<Post> posts = await getPosts();
    String userName = "";
    String userImg = "";

    for(int i = 0; i < posts.length; i++){
      await FirebaseFirestore.instance.collection("userinfo").where('email', isEqualTo: posts[i].id).get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) {
          userName = result.data()['name'].toString();
          userImg = result.data()['image'].toString();
        });
      });
      posts[i].name = userName;
      posts[i].image_url = userImg;
    }
    return posts;
  }

  String exp = "";

  Future<String> getExpertise() async{
    List<String> arr = [];
    await FirebaseFirestore.instance.collection("userexpertise").where("email", isEqualTo: followingEmail).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        arr.add(result.data()['exp_id'].toString());
      });
    });
    await FirebaseFirestore.instance.collection("expertise").where("id", whereIn: arr).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        exp = exp + result.data()['name'].toString() + ", ";
      });
    });
    exp = exp.substring(0, exp.length - 2);
    print("Expertise: "+exp);

    return exp;
  }

  writeMessage() async {
    FirebaseFirestore.instance
        .collection("messages")
        .doc(email)
        .set({
      followingEmail : followingEmail
    },SetOptions(merge: true)).then((value) {
    });
    FirebaseFirestore.instance
        .collection("messages")
        .doc(followingEmail)
        .set({
      email : email
    },SetOptions(merge: true)).then((value) {
    });
    FirebaseFirestore.instance
        .collection("messages")
        .doc(email)
        .collection(followingEmail)
        .doc()
        .set({
      "sender": email,
      "text": message.text,
      "createdAt" : FieldValue.serverTimestamp()
    }).then((value) {
    });
    FirebaseFirestore.instance
        .collection("messages")
        .doc(followingEmail)
        .collection(email)
        .doc()
        .set({
      "sender": email,
      "text": message.text,
      "createdAt" : FieldValue.serverTimestamp(),
    }).then((value) {
    });
  }

  _openPopup(context) {
    Alert(
        context: context,
        title: "Say Hi!",
        content: Column(
          children: <Widget>[
            TextFormField(
              controller: message,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 5,
              decoration: InputDecoration(
                icon: Icon(Icons.post_add),
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: (){
              writeMessage();
              Timer(Duration(milliseconds: 200), (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => userMessaging(email: email, recipientEmail: followingEmail, recipientName: followingName)));
              });
            },
            child: Text(
              "Send Message",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  @override
  Widget build(BuildContext context) {
    isFollowing = false;
    followings();
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Profile"),
        ),
        body: Container(
          height: (MediaQuery.of(context).size.height),
          child: FutureBuilder(
            future: getUserInfo(),
            builder: (BuildContext context, AsyncSnapshot snapshot){
              if(snapshot.data == null){
                return Container(
                    child: Center(
                        child: Text("Loading...")
                    )
                );
              } else {
                ReCase name = ReCase(snapshot.data[0].name);
                return Container(
                    child: Column(
                        children: <Widget>[
                          const SizedBox(height: 20),
                          Text(
                            name.titleCase,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 70.0,
                                  child: ClipRRect(
                                    child: Image.network(snapshot.data[0].image_url),
                                    borderRadius: BorderRadius.circular(50.0),
                                  ),
                                ),
                                Column(children: <Widget>[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      child: Text(
                                        "Following \n"+snapshot.data[0].following,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      child: Text(
                                        "Followers \n"+snapshot.data[0].followers,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  )]),
                              ]),
                          const SizedBox(height: 10),
                          Text(
                              snapshot.data[0].bio,
                              textAlign: TextAlign.center
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder(
                            future: getExpertise(),
                            builder: (BuildContext context, AsyncSnapshot snapshot){
                              if(snapshot.data == null){
                                return Container(
                                    child: Center(child: Text(""))
                                );
                              }
                              else{
                                return Text(
                                  snapshot.data,
                                  textAlign: TextAlign.center,
                                );
                              }
                            },
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                child: isFollowing ? Text('Unfollow') : Text('Follow'),
                                onPressed: () {
                                followButton();
                                },
                              ),
                              const SizedBox(height: 10, width: 20),
                              ElevatedButton(
                                child: Text('Message'),
                                onPressed: () {
                                  print("Message");
                                  _openPopup(context);
                                  },
                              )
                            ]
                          ),
                          FutureBuilder(
                            future: posts(),
                            builder: (BuildContext context, AsyncSnapshot snapshot2){
                              var count;
                              snapshot2.hasData ? count = snapshot2.data.length : count = 0;
                              return Expanded(
                                child: ListView.builder(
                                    itemCount: count,
                                    itemBuilder: (BuildContext context, int index){
                                      if(snapshot.data == null){
                                        return Container(
                                            child: Center(
                                                child: Text("No Posts")
                                            )
                                        );
                                      }else{
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: Image.network(snapshot.data[0].image_url).image,
                                          ),
                                          title: Text(name.titleCase),
                                          subtitle: Text(snapshot2.data[index].text),
                                        );
                                      }
                                    }
                                ),
                              );
                              // return Container(
                              //   child: Text("It is working"),
                              // );
                            },
                          ),
                        ]
                    )
                );
              }
            },
          ),
        )
    );
  }
}

class User {

  final String name;
  final String email;
  final String image_url;
  final String bio;
  final String followers;
  final String following;

  User(this.name, this.email, this.image_url, this.bio, this.followers, this.following);

}

class Post {
  final String id;
  String name;
  final String text;
  String image_url;
  Post(this.id, this.text, this.image_url, this.name);
}