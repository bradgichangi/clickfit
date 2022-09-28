import 'dart:html';
import 'dart:io' as io;
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:test1/main_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';


class Edit_Profile_Client extends StatefulWidget{
  final String email;

  const Edit_Profile_Client({Key? key, required this.email}) : super(key: key);
  @override
  EditProfileState createState() => EditProfileState(email: email);
}

class EditProfileState extends State<Edit_Profile_Client> {
  final String email;

  EditProfileState({Key? key, required this.email});

  TextEditingController name = TextEditingController();
  TextEditingController oldPassword = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  TextEditingController bioInput = TextEditingController();



  Future initial() async{
    await FirebaseFirestore.instance.collection("userinfo").where("email", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        name.text = result.data()['name'].toString();
        bioInput.text = result.data()['bio'].toString();
      });
    });
  }


  uploadImage() async{
    var user = _auth.currentUser;
    FileUploadInputElement input = FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files!.first;
      final reader = FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((event) async{
        var snapshot = await FirebaseStorage.instance.ref().child('profile/'+user!.uid+'/displayImage').putBlob(file);
        var url = await snapshot.ref.getDownloadURL();
        await user.updatePhotoURL(url);
        await FirebaseFirestore.instance
            .collection('userinfo')
            .doc(user.uid)
            .update({
          'image': url,
        });
      });
    });
  }


  _openPopup(context) {
    Alert(
        context: context,
        title: "Change Password",
        content: Column(
          children: <Widget>[
            TextFormField(
              controller: oldPassword,
              obscureText: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.lock),
                labelText: 'Current Password',
              ),
            ),
            TextFormField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(
                icon: const Icon(Icons.lock),
                labelText: 'New Password',
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: (){
              //changePassword(context);
              editPassword();
              Navigator.pop(context);
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }


  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<User>> getUserInfo() async{
    List<User> users = [];
    await FirebaseFirestore.instance.collection("userinfo").where("email", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        User user = User(_auth.currentUser!.displayName.toString(), email, _auth.currentUser!.photoURL.toString(), result.data()['bio'].toString(), "", "");
        users.add(user);
      });
    });
    print(users.length.toString() + " users");
    return users;
  }


  editProfile() async{
    var user = _auth.currentUser;
    FirebaseFirestore.instance
        .collection('userinfo')
        .doc(user!.uid)
        .update({
      'name': name.text.toLowerCase(),
      'bio': bioInput.text,
    });
    user.updateDisplayName(name.text.toLowerCase());

    try{
      await FirebaseFirestore.instance
          .collection('userexpertise')
          .where('email', isEqualTo: email)
          .get()
          .then((snapshot) {
        for(DocumentSnapshot ds in snapshot.docs){
          ds.reference.delete();
        }
      });}
    catch(e){
      print(e);
    }
  }


  editPassword() async {
    final user = await _auth.currentUser;
    final cred = EmailAuthProvider.credential(
        email: email, password: oldPassword.text);

    user!.reauthenticateWithCredential(cred).then((value) {
      user.updatePassword(newPassword.text).then((_) {

      }).catchError((error) {
        print(error);
      });
    }).catchError((err) {

    });}

  int check = 0;
  @override
  Widget build(BuildContext context) {
    initial();
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Edit Profile"),
        ),
        body: SingleChildScrollView(
          child: FutureBuilder(
            future: getUserInfo(),
            builder: (BuildContext context, AsyncSnapshot snapshot){
              if(snapshot.data == null){
                return Container(
                    child: const Center(
                        child: const Text("Loading...")
                    )
                );
              } else {
                return Container(
                    child: Column(
                        children: <Widget>[
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 70.0,
                            child: ClipRRect(
                              child: Image.network(snapshot.data[0].image_url),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              child: const Text('Upload Image'),
                              onPressed: () async{
                                print('Pressed');
                                uploadImage();
                              }
                          ),
                          TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'Name',
                            ),
                          ),
                          TextFormField(
                            controller: bioInput,
                            decoration: const InputDecoration(
                              icon: const Icon(Icons.wysiwyg),
                              labelText: 'Bio',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                              SizedBox(height: 10),
                              Divider(),
                              SizedBox(height: 10),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            child: const Text('Change Password'),
                            onPressed: () {
                              print('Pressed');
                              _openPopup(context);
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            child: const Text('Save'),
                            onPressed: () {
                              //update(context);
                              editProfile();
                              setState(() {});
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

class CheckBoxState{
  final String title;
  bool value;

  CheckBoxState({
    required this.title,
    this.value = false,
  });
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