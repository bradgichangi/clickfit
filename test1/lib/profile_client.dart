import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';
import 'package:test1/edit_profile_trainer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test1/main.dart';

import 'edit_profile_client.dart';

class Profile_Client_Screen extends StatefulWidget{
  final String email;
  Profile_Client_Screen({Key? key, required this.email}) : super(key: key);


  @override
  Profile_Client createState() => Profile_Client(email: email);
}

class Profile_Client extends State<Profile_Client_Screen>{
  final String email;
  Profile_Client({Key? key, required this.email});

  String noOfFollowing = "";
  String noOfFollowers = "";
  Future<String> getFollowing() async{
    await FirebaseFirestore.instance.collection("followers")
        .where("user_email", isEqualTo: email)
        .get().then((querySnapshot) {
      noOfFollowing = querySnapshot.size.toString();
    });
    return noOfFollowing;
  }

  Future<String> getFollowers() async{
    await FirebaseFirestore.instance.collection("followers")
        .where("following_email", isEqualTo: email)
        .get().then((querySnapshot) {
      noOfFollowers = querySnapshot.size.toString();
    });
    return noOfFollowers;
  }

  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<User>> getUserInfo() async{
    getFollowing();
    getFollowers();
    print("Following: "+noOfFollowing);
    print("Followers: "+noOfFollowers);
    List<User> users = [];
    await FirebaseFirestore.instance.collection("userinfo").where("email", isEqualTo: email)
        .get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        User user = User(
            _auth.currentUser!.displayName.toString(),
            email,
            _auth.currentUser!.photoURL.toString(),
            result.data()['bio'].toString(),
            noOfFollowers,
            noOfFollowing);
        users.add(user);
      });
    });
    return users;
  }


  Future<List<Post>> getPosts() async{
    List<Post> posts = [];
    await FirebaseFirestore.instance.collection("posts").where("id", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        Post post = Post(result.data()["id"].toString(), result.data()["text"].toString(), "", "");
        posts.add(post);
      });
    });
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

  logout() async{
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (context) => MyHomePage(title: 'ClickFit')),
            (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    getUserInfo();
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
                ReCase name = new ReCase(snapshot.data[0].name);
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
                                      child: FutureBuilder(
                                        future: getFollowing(),
                                        builder: (BuildContext context, AsyncSnapshot snapshot){
                                          if(snapshot.data == null){
                                            return Container(
                                                child: Center(child: Text(""))
                                            );
                                          }
                                          else{
                                            return Text(
                                              "Following \n"+snapshot.data[0],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      child: FutureBuilder(
                                        future: getFollowers(),
                                        builder: (BuildContext context, AsyncSnapshot snapshot){
                                          if(snapshot.data == null){
                                            return Container(
                                                child: Center(child: Text(""))
                                            );
                                          }
                                          else{
                                            return Text(
                                              "Followers \n"+snapshot.data[0],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            );
                                          }
                                        },
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
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  child: Text('Edit Profile'),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => Edit_Profile_Client(email: email)));
                                  },
                                ),
                                const SizedBox(height: 10, width: 20),
                                ElevatedButton(
                                  child: Text('Log Out'),
                                  onPressed: () {
                                    logout();
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
                                                child: Text("")
                                            )
                                        );
                                      }else{
                                        ReCase name = ReCase(snapshot.data[0].name);
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