import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddCompteCamionPage extends StatefulWidget {
  @override
  _AddCompteCamionPageState createState() => _AddCompteCamionPageState();
}

class _AddCompteCamionPageState extends State<AddCompteCamionPage> {
  TextEditingController _nomController = TextEditingController();
  TextEditingController _prenomController = TextEditingController();
  TextEditingController _numeroCamionController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _latitudeController = TextEditingController();
  TextEditingController _longitudeController = TextEditingController();

  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un compte camion'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomController,
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _prenomController,
              decoration: InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              controller: _numeroCamionController,
              decoration: InputDecoration(labelText: 'Numéro de camion'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),


            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String nom = _nomController.text;
                String prenom = _prenomController.text;
                String numeroCamion = _numeroCamionController.text;
                String email = _emailController.text;
                String password = _passwordController.text;
                double latitude = double.tryParse(_latitudeController.text) ?? 0.0;
                double longitude = double.tryParse(_longitudeController.text) ?? 0.0;

                _auth.createUserWithEmailAndPassword(email: email, password: password)
                    .then((userCredential) {
                  String userId = userCredential.user!.uid;

                  _database.child('comptes_camions').child(userId).set({
                    'nom': nom,
                    'prenom': prenom,
                    'numero_camion': numeroCamion,
                    'latitude': latitude,
                    'longitude': longitude,
                    'typeUser' : "user"

                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Compte camion ajouté avec succès'),
                    ));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur: $error'),
                    ));
                  });
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur lors de la création de l\'utilisateur: $error'),
                  ));
                });
              },
              child: Text('Ajouter'),
            ),

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _numeroCamionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
