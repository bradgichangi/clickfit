import 'dart:core';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:recase/recase.dart';
import 'package:test1/home.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test1/login.dart';
import 'dart:convert';

import 'package:test1/userProfile.dart';


class Search extends StatefulWidget {
  final String email;
  const Search({Key? key, required this.email}) : super(key: key);

  @override
  _SearchState createState() => _SearchState(this.email);
}

class _SearchState extends State<Search> {
  final String email;
  TextEditingController search = TextEditingController();
  String test = "";
  bool searchType = false;
  var expert = <Map>[];
  _SearchState(this.email);


  Future<List<User>>userSearch() async{
    List<User> users = [];

    if(search.text != "") {
      await FirebaseFirestore.instance.collection("userinfo")
          .where('name', isGreaterThanOrEqualTo: search.text,
        isLessThan: search.text.substring(0, search.text.length - 1) +
            String.fromCharCode(
                search.text.codeUnitAt(search.text.length - 1) + 1),
      ).get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) async {
          if (result.data()['email'].toString() != email) {
            String dist = "";
            try {
              dist = await distance(double.parse(result.data()['latitude']),
                  double.parse(result.data()['longitude']));
            } catch (e) {
              print(e);
            }
            User user = User(result.data()['name'].toString(),
                result.data()['email'].toString(),
                result.data()['image'].toString(),
                double.parse(result.data()['latitude']),
                double.parse(result.data()['longitude']),
                dist);
            users.add(user);
          }
        });
      });
    }
    else{
    await FirebaseFirestore.instance.collection("userinfo")
        .where('name', isGreaterThanOrEqualTo: search.text
    ).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        if(result.data()['email'].toString() != email) {
          String dist = "";
          try{
            dist = await distance(double.parse(result.data()['latitude']), double.parse(result.data()['longitude']));
          }catch(e){print(e);}
          User user = User(result.data()['name'].toString(),
              result.data()['email'].toString(),
              result.data()['image'].toString(),
              double.parse(result.data()['latitude']),
              double.parse(result.data()['longitude']),
              dist);
          users.add(user);
        }
      });
    });
    }
    Comparator<User> sortByDist = (a, b) => a.distance.compareTo(b.distance);
    users.sort(sortByDist);
    return users;
  }

  Future<List<User>> expertiseSearch() async{
    List<User> users = [];
    List<String> emails = [];
    List<String> checked = [];
    List<String> id_array = [];
    for(int i = 0; i < expert.length; i++){
      if(expert[i]['isChecked'] == true){
        checked.add(expert[i]['name']);
      }
    }
    await FirebaseFirestore.instance.collection("expertise").where('name', whereIn: checked).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        id_array.add(result.data()['email']);
      });
    });
    await FirebaseFirestore.instance.collection("userexpertise").where('exp_id', whereIn: id_array).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        emails.add(result.data()['email']);
      });
    });
    await FirebaseFirestore.instance.collection("userinfo").where('email', whereIn: emails).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) async{
        User user = User(result.data()['name'], result.data()['email'], result.data()['image'], 0.0, 0.0, "");
        users.add(user);
      });
    });
    return users;
  }


  Future<String> distance(double lat, double long) async{
    final Location location = new Location();
    var _locationData = await location.getLocation();
    var _distanceInMeters = await Geolocator.distanceBetween(
      double.parse(_locationData.latitude.toString()),
      double.parse(_locationData.longitude.toString()),
      lat,
      long,
    );
    return (_distanceInMeters/1000).toStringAsFixed(1);
  }



  Future<List<Map>> getCheckbox() async{
    var expertise_id = [];
    await FirebaseFirestore.instance.collection("expertise").get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        expert.add({'name' : result.data()['name'].toString(), 'isChecked' : false});
        expertise_id.add(result.data()['id'].toString());
      });
    });
    return expert;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Search"),
      ),
      body: Container(
      child: Column(
        children: [
          TextFormField(
            controller: search,
            decoration: const InputDecoration(
              labelText: 'Search for user here',
            ),
            onChanged: (search){
              userSearch();
              setState(() {});
            },
          ),

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
                        title: Text(name.titleCase),
                          subtitle: snapshot.data[index].distance != "" ? Text(snapshot.data[index].distance+" km away") : Text(''),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => userProfile(email: email, followingEmail: snapshot.data[index].email, followingName: snapshot.data[index].name)));
                          }
                      );
                      }
                    }
                ),
              );
            },
          ),
          ],
      )
      ),
    );
  }
}

class User {
  final String name;
  final String email;
  final String image_url;
  final double latitude;
  final double longitude;
  final String distance;
  User(this.name, this.email, this.image_url, this.latitude, this.longitude, this.distance);
}