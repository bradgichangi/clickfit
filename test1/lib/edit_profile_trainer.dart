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


class Edit_Profile_Trainer extends StatefulWidget{
  final String email;

  const Edit_Profile_Trainer({Key? key, required this.email}) : super(key: key);
  @override
  EditProfileState createState() => EditProfileState(email: email);
}

class EditProfileState extends State<Edit_Profile_Trainer> {
  final String email;

  EditProfileState({Key? key, required this.email});

  TextEditingController name = TextEditingController();
  TextEditingController oldPassword = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  TextEditingController bioInput = TextEditingController();
  TextEditingController newExp = TextEditingController();



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

  var expert = <Map>[];

  Future<List<Map>> getCheckbox() async{
    var expertise_id = [];
    await FirebaseFirestore.instance.collection("expertise").get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        expert.add({'name' : result.data()['name'].toString(), 'isChecked' : false});
        expertise_id.add(result.data()['id'].toString());
      });
    });

    await FirebaseFirestore.instance.collection("userexpertise").where("email", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        for(int i = 0; i < expert.length; i++){
          if(expertise_id[i] == result.data()['exp_id'].toString()){
            setState(() {expert[i]['isChecked'] = true;});
          }
        }
      });
    });
    return expert;
  }

  popup(context) {
    Alert(
        context: context,
        title: "Add Expertise",
        content: Column(
          children: <Widget>[
            TextFormField(
              controller: newExp,
              decoration: InputDecoration(
                icon: Icon(Icons.lock),
                labelText: 'Name',
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: (){
              //addCheckbox(context, newExp.text);
              addExpertise();
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(
              "Add",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
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
              decoration: InputDecoration(
                icon: Icon(Icons.lock),
                labelText: 'Current Password',
              ),
            ),
            TextFormField(
              controller: newPassword,
              obscureText: true,
              decoration: InputDecoration(
                icon: Icon(Icons.lock),
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
            child: Text(
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

  addExpertise() async{
    String count = "";
    await FirebaseFirestore.instance.collection('expertise').get().then((snapshot){
      count = (snapshot.size+1).toString();
    });
    FirebaseFirestore.instance
        .collection("expertise")
        .add({
      "id": count,
      "name": newExp.text,
    });
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
    var exp = [];
    for(int i = 0; i < expert.length; i++){
      await FirebaseFirestore.instance
          .collection('expertise')
          .where('name', isEqualTo: expert[i]['name'])
          .get()
          .then((snapshot) {
        snapshot.docs.forEach((result) {
          if(expert[i]['isChecked'] == true) exp.add(result.data()['id'].toString());
        });
      });
    }

    for(String str in exp){
      FirebaseFirestore.instance
          .collection("userexpertise")
          .add({
        "email": email,
        "exp_id": str,
      });
    }
  }


  editPassword() async {
    final user = await _auth.currentUser;
    final cred = EmailAuthProvider.credential(
        email: email, password: oldPassword.text);
    user!.reauthenticateWithCredential(cred).then((value) {
      user.updatePassword(newPassword.text).then((_) {
      }).catchError((error) {
        if(error.code == "weak-password"){
        Fluttertoast.showToast(
            msg: "The password isn't strong enough",  // message
            toastLength: Toast.LENGTH_SHORT, // length
            gravity: ToastGravity.CENTER,    // location
            timeInSecForIosWeb: 2
        );}
      });
    }).catchError((err) {
      if(err.code == "wrong-password"){
        Fluttertoast.showToast(
            msg: "Incorrect password",  // message
            toastLength: Toast.LENGTH_SHORT, // length
            gravity: ToastGravity.CENTER,    // location
            timeInSecForIosWeb: 2
        );}
    });}

  int check = 0;
  @override
  Widget build(BuildContext context) {
    //getToken();
    //print(x.toString() + "test");
    initial();
    if(check == 0){
      // checkboxes();
      getCheckbox();
      print(expert);
      check++;
    }
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Edit Profile"),
        ),
        body: SingleChildScrollView(
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
                            child: Text('Upload Image'),
                            onPressed: () async{
                              print('Pressed');
                              //pickImage();
                              uploadImage();
                            }
                          ),
                          TextFormField(
                            controller: name,
                            decoration: InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'Name',
                            ),
                          ),
                          TextFormField(
                            controller: bioInput,
                            decoration: InputDecoration(
                              icon: Icon(Icons.wysiwyg),
                              labelText: 'Bio',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text(
                                'Choose your expertise:',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 10),

                              // The checkboxes will be here
                              Column(
                                  children: expert.map((hobby) {
                                    return CheckboxListTile(
                                        value: hobby["isChecked"],
                                        title: Text(hobby["name"]),
                                        onChanged: (newValue) {
                                          setState(() {
                                            hobby["isChecked"] = newValue;
                                          });
                                        });
                                  }).toList()),

                              // Display the result here
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 10),
                            ]),
                          ),
                          ElevatedButton(
                            child: Text('Add new expertise'),
                            onPressed: () {
                              print('Pressed');
                              popup(context);
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            child: Text('Change Password'),
                            onPressed: () {
                              print('Pressed');
                              _openPopup(context);
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            child: Text('Save'),
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