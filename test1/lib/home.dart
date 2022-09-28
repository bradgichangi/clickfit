import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recase/recase.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test1/search.dart';



class HomeScreen extends StatefulWidget{
  final String email;
  HomeScreen({Key? key, required this.email}) : super(key: key);


  @override
  Home createState() => Home(email: email);
}

class Home extends State<HomeScreen>{
  final String email;
  Home({Key? key, required this.email});
  TextEditingController text = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  bool isTrainer = false;
  Image? image;


  _openPopup(context) {
    Alert(
        context: context,
        title: "Write A Post",
        content: Column(
          children: <Widget>[
            TextFormField(
              controller: text,
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
              //post();
              writePost(text.text);
              Navigator.pop(context);
            },
            child: Text(
              "Post",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
    setState(() {});
  }

  FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> info = [];


  Future<List<Post>> getPosts() async{
    List<String> following = [];
    List<Post> posts = [];
    await FirebaseFirestore.instance.collection("followers").where("user_email", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        following.add(result.data()['following_email'].toString());
      });
      following.add(email);
    });
    await FirebaseFirestore.instance.collection("posts").where("id", whereIn: following).get().then((querySnapshot) {
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
      await FirebaseFirestore.instance.collection("userinfo")
          .where('email', isEqualTo: posts[i].id).get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) {
          userName = result.data()['name'].toString();
          userImg = result.data()['image'].toString();
        });
      });
      posts[i].name = userName; posts[i].image_url = userImg;
    }
    return posts;
  }

  writePost(String text){
    FirebaseFirestore.instance.collection('posts').add({
      'id': email,
      'text': text,
      "createdAt" : FieldValue.serverTimestamp(),
    });
  }


  getLocation() async{
    try{
    final Location location = new Location();
    var _locationData = await location.getLocation();
    var user = _auth.currentUser;
    FirebaseFirestore.instance
        .collection('userinfo')
        .doc(user!.uid)
        .update({
      'latitude': _locationData.latitude.toString(),
      'longitude': _locationData.longitude.toString(),
    });} catch (e) {print(e);}
  }

  String img = "";

  FilePickerResult? pickedFile;


  @override
  Widget build(BuildContext context) {
    posts();
    getLocation();
    print(_auth.currentUser!.uid);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Home"),
      ),
        body: Scaffold(
          body: Column(
            children: [
              FutureBuilder(
                future: posts(),
                builder: (BuildContext context, AsyncSnapshot snapshot){
                  var count;
                  snapshot.hasData ? count = snapshot.data.length : count = 0;
                  print("Count: " + count.toString());
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
                            ReCase name = new ReCase(snapshot.data[index].name);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: Image.network(snapshot.data[index].image_url).image,
                              ),
                              title: Text(name.titleCase, style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              )),
                              subtitle: Text(snapshot.data[index].text, style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              )),
                            );
                          }
                        }
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.post_add),
            onPressed: () async{
              print('Pressed');
              _openPopup(context);
            },
          ),
        ),
    );
  }
}

class Post {
  final String id;
  String name;
  final String text;
  String image_url;
  Post(this.id, this.text, this.image_url, this.name);
}

class UserInfo {
  final String name;
  final String image_url;
  UserInfo(this.name, this.image_url);
}