
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:test1/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test1/signup.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // Replace with actual values
    options: FirebaseOptions(
        apiKey: "AIzaSyB_JXr-56FWrTuGJzAuGMHkOwqlDm1avjo",
        authDomain: "project-11459.firebaseapp.com",
        projectId: "project-11459",
        storageBucket: "project-11459.appspot.com",
        messagingSenderId: "479835220710",
        appId: "1:479835220710:web:f6672c762058f98d0aa927",
        measurementId: "G-D5CE3WQ2ZW"
    ),

  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickFit',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'ClickFit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();


  void login(BuildContext context) async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: password.text);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainScreen(email: email.text)),(Route<dynamic> route) => false);
    }
    catch(e){
      String error = "";
      if(e.toString().contains("auth/invalid-email")) error = "Invalid Email";
      else if(e.toString().contains("auth/wrong-password")) error = "Incorrect Password";
      Fluttertoast.showToast(
          msg: error,  // message
          toastLength: Toast.LENGTH_SHORT, // length
          gravity: ToastGravity.CENTER,    // location
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.white // duration
      );
      print(e
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
                              border: OutlineInputBorder(

                              ),
                              labelText: 'Enter your email',
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

                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              child: Text('Log In'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 125, vertical: 15),
                              ),
                              onPressed: () {
                                print('Pressed');
                                login(context);
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                            child: Text('Sign Up'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => Signup()));
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
