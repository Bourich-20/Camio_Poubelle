import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddPoubellePage extends StatefulWidget {
  @override
  _AddPoubellePageState createState() => _AddPoubellePageState();
}

class _AddPoubellePageState extends State<AddPoubellePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _statutController = TextEditingController();

  DatabaseReference _poubelleRef = FirebaseDatabase.instance.reference().child('poubelles');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une poubelle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(labelText: 'Numéro de la poubelle'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le numéro de la poubelle';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _latitudeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Latitude'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la latitude';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _longitudeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Longitude'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la longitude';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Distance'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la distance';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _statutController,
                decoration: InputDecoration(labelText: 'Statut (oui/non)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le statut';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _savePoubelle();
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePoubelle() {
    String numero = _numeroController.text;
    double latitude = double.parse(_latitudeController.text);
    double longitude = double.parse(_longitudeController.text);
    double distance = double.parse(_distanceController.text);
    String statut = _statutController.text;

    _poubelleRef.push().set({
      'numero': numero,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'statut': statut,
    }).then((value) {
      print('Poubelle enregistrée avec succès');
    }).catchError((error) {
      print('Erreur lors de l\'enregistrement de la poubelle: $error');
    });
  }
}
