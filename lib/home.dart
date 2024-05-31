     import 'package:flutter/material.dart';
    import 'package:firebase_database/firebase_database.dart';
    import 'package:geolocator/geolocator.dart';
    import 'package:google_maps_flutter/google_maps_flutter.dart';
    import 'package:permission_handler/permission_handler.dart';
    import 'dart:typed_data';
    import 'package:flutter/services.dart';
    import 'dart:typed_data';
    import 'dart:ui' as ui;
    import 'dart:async';
    import 'package:flutter/services.dart';

import 'add_compte_camion.dart';

    class Home extends StatefulWidget {
    final String userId;

    Home({required this.userId});

    @override
    _HomeState createState() => _HomeState();
    }

    class _HomeState extends State<Home> {
    late GoogleMapController _mapController;
    late LatLng _currentPosition;
    bool _mapLoaded = false;
    late DatabaseReference _camionRef;
    late DatabaseReference _poubelleRef;
    late ValueNotifier<Map<dynamic, dynamic>?> _camionInfoNotifier;
    Set<Marker> _markers = Set<Marker>();
    List<Polyline> _polylines = [];
    double distanceInKm = 0.0;
    bool _isAdmin = false;


    @override
    void initState() {
    super.initState();
    _currentPosition = LatLng(0.0, 0.0);
    _getCurrentLocation();
    _camionRef = FirebaseDatabase.instance.reference().child('comptes_camions').child(widget.userId);
    _camionInfoNotifier = ValueNotifier(null);
    _camionRef.onValue.listen((event) {
    if (event.snapshot.value != null) {
    Map<dynamic, dynamic>? camionInfo = event.snapshot.value as Map<dynamic, dynamic>?;
    _camionInfoNotifier.value = camionInfo;
    if (camionInfo != null && camionInfo['typeUser'] == 'admin') {
        setState(() {
            _isAdmin = true;
        });
    }
    _updateMarkers();
    }
    });
    _poubelleRef = FirebaseDatabase.instance.reference().child('poubelles');
    _poubelleRef.onValue.listen((event) {
    if (event.snapshot.value != null) {
    Map<dynamic, dynamic>? poubelles = event.snapshot.value as Map<dynamic, dynamic>?;
    _updatePoubelleMarkers(poubelles);
    }
    });
    _addOtherCamionsMarkers();
    }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.orange,
        actions: [
          if (_isAdmin) // Afficher le bouton uniquement si l'utilisateur est admin
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCompteCamionPage()),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<Map<dynamic, dynamic>?>(
              valueListenable: _camionInfoNotifier,
              builder: (context, camionInfo, child) {
                if (camionInfo != null && camionInfo.containsKey('nom') && camionInfo.containsKey('prenom')) {
                  String nom = camionInfo['nom'];
                  String prenom = camionInfo['prenom'];
                  String numeroCamion = camionInfo['numero_camion'] ?? '';
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '$nom $prenom',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text('Numéro de camion: $numeroCamion'),
                    ],
                  );
                }
                return SizedBox();
              },
            ),
          ),
        ],
      ),
    body: Stack(
    children: [
    GoogleMap(
    onMapCreated: _onMapCreated,
    initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14.0),
    markers: _mapLoaded ? _markers : Set<Marker>(),
    polylines: _polylines.toSet(),
    ),
    Positioned(
    top: 50.0,
    right: 15.0,
    child: GestureDetector(
    onTap: () {
    _showCamionInfo();
    },
    child: Column(
    children: [
    Icon(Icons.directions_bus),
    ValueListenableBuilder<Map<dynamic, dynamic>?>(
    valueListenable: _camionInfoNotifier,
    builder: (context, camionInfo, child) {
    if (camionInfo != null && camionInfo.containsKey('numero_camion')) {
    String numeroCamion = camionInfo['numero_camion'] ?? '';
    return Text(numeroCamion);
    }
    return SizedBox();
    },
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    );
    }

    void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
    _mapLoaded = true;
    });
    }

    Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
    try {
    Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
    _currentPosition = LatLng(position.latitude, position.longitude);
    _storeCamionLocation(position.latitude, position.longitude);
    });
    } catch (e) {
    print('Erreur lors de l\'obtention de la position de l\'utilisateur : $e');
    }
    } else {
    print('L\'utilisateur a refusé l\'autorisation de localisation.');
    }
    }

    void _storeCamionLocation(double latitude, double longitude) {
    _camionRef.update({
    'latitude': latitude,
    'longitude': longitude,
    }).then((_) {
    print('Position du camion mise à jour avec succès.');
    }).catchError((error) {
    print('Erreur lors de la mise à jour de la position du camion : $error');
    });
    }

    void _updateMarkers() {
    _markers.clear();
    _markers.add(
    Marker(
    markerId: MarkerId('currentLocation'),
    position: _currentPosition,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: InfoWindow(
    title: 'Current Location',
    snippet: _getCamionSnippet(),
    ),
    ),
    );
    setState(() {});
    }

    String _getCamionSnippet() {
    String numeroCamion = '';
    if (_camionInfoNotifier.value != null && _camionInfoNotifier.value!.containsKey('numero_camion')) {
    numeroCamion = _camionInfoNotifier.value!['numero_camion'] ?? '';
    }
    return 'Numéro de camion: $numeroCamion';
    }

    void _showCamionInfo() {
    showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: Text('Informations sur le camion'),
    content: SingleChildScrollView(
    child: ValueListenableBuilder<Map<dynamic, dynamic>?>(
    valueListenable: _camionInfoNotifier,
    builder: (context, camionInfo, child) {
    if (camionInfo != null && camionInfo.containsKey('nom') && camionInfo.containsKey('prenom')) {
    String nom = camionInfo['nom'];
    String prenom = camionInfo['prenom'];
    String numeroCamion = camionInfo['numero_camion'] ?? '';
    return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text('Nom: $nom'),
    Text('Prénom: $prenom'),
    Text('Numéro de camion: $numeroCamion'),
    ],
    );
    }
    return SizedBox();
    },
    ),
    ),
    actions: <Widget>[
    TextButton(
    child: Text('Fermer'),
    onPressed: () {
    Navigator.of(context).pop();
    },
    ),
    ],
    );
    },
    );
    }
    Future<void> _updatePoubelleMarkers(Map<dynamic, dynamic>? poubelles) async {
    List<Marker> markers = [];

    if (poubelles != null) {
    for (var entry in poubelles.entries) {
    double latitude = (entry.value['latitude'] ?? 0).toDouble();
    double longitude = (entry.value['longitude'] ?? 0).toDouble();
    double distance = (entry.value['distance'] ?? 0).toDouble();
    bool estPleine = distance <= 10.0;
    String iconPath = estPleine ? 'assets/pleine.ico' : 'assets/vide.ico';
    BitmapDescriptor icon = await _getResizedBitmapDescriptor(iconPath, width: 100, height: 100);
    markers.add(
    Marker(
    markerId: MarkerId(entry.key.toString()),
    position: LatLng(latitude, longitude),
    icon: icon,
    infoWindow: InfoWindow(
    title: 'Poubelle ${entry.value['numero']}',
    snippet: estPleine ? 'Pleine' : 'Vide',
    ),
    onTap: () {
    },
    ),
    );
    }
    }

    _markers.addAll(markers);
    _updateNearestPoubelle(poubelles);
    setState(() {});
    }


    Future<BitmapDescriptor> _getResizedBitmapDescriptor(String iconPath, {int width = 110, int height = 110}) async {
    ByteData imageData = await rootBundle.load(iconPath);
    Uint8List bytes = Uint8List.view(imageData.buffer);
    ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: width, targetHeight: height);
    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image resizedImage = fi.image;
    ByteData? resizedImageData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    if (resizedImageData != null) {
    Uint8List resizedBytes = resizedImageData.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedBytes);
    } else {
    throw 'Failed to resize image';
    }
    }

    void _updateNearestPoubelle(Map<dynamic, dynamic>? poubelles) {
    LatLng nearestPoubellePosition = findNearestPoubellePosition(poubelles);
    distanceInKm = calculateDistanceInKm(nearestPoubellePosition);
    _addPolyline(nearestPoubellePosition);
    }
    double calculateDistanceInKm(LatLng nearestPoubellePosition) {
    double distanceInMeters = Geolocator.distanceBetween(
    _currentPosition.latitude,
    _currentPosition.longitude,
    nearestPoubellePosition.latitude,
    nearestPoubellePosition.longitude,
    );
    return distanceInMeters / 1000;
    }
    LatLng findNearestPoubellePosition(Map<dynamic, dynamic>? poubelles) {
    double minDistance = double.infinity;
    LatLng nearestPoubellePosition = _currentPosition;
    if (poubelles != null && poubelles.isNotEmpty) {
    poubelles.forEach((key, value) {
    if (value['distance'] <= 10) {
    double latitude = (value['latitude'] ?? 0).toDouble();
    double longitude = (value['longitude'] ?? 0).toDouble();
    double distance = Geolocator.distanceBetween(
    _currentPosition.latitude,
    _currentPosition.longitude,
    latitude,
    longitude,
    );

    if (distance < minDistance) {
    minDistance = distance;
    nearestPoubellePosition = LatLng(latitude, longitude);
    }
    }
    });
    }

    return nearestPoubellePosition;
    }

    void _addPolyline(LatLng nearestPoubellePosition) {
    Polyline polyline = Polyline(
    polylineId: PolylineId('nearestPoubelle'),
    points: [
    _currentPosition,
    nearestPoubellePosition,
    ],
    color: Colors.green,
    width: 5,
    );
    _polylines.add(polyline);

    _addInvisibleMarkers(nearestPoubellePosition);

    setState(() {});
    }

    void _addInvisibleMarkers(LatLng nearestPoubellePosition) async {
    List<LatLng> intermediatePoints = _calculateIntermediatePoints(nearestPoubellePosition);

    LatLng middlePoint = intermediatePoints[intermediatePoints.length ~/ 2];

    BitmapDescriptor poubelleIcon = await BitmapDescriptor.fromAssetImage(
    ImageConfiguration(devicePixelRatio: 2.5),
    'assets/tick.png',
    );

    _markers.add(
    Marker(
    markerId: MarkerId('middlePoint'),
    position: middlePoint,
    icon: poubelleIcon,
    onTap: () {
    _showPoubelleDialog(nearestPoubellePosition);
    },
    ),
    );
    }

    List<LatLng> _calculateIntermediatePoints(LatLng nearestPoubellePosition) {

    const numberOfSegments = 10;
    List<LatLng> intermediatePoints = [];
    LatLng start = _currentPosition;
    double deltaLat = (nearestPoubellePosition.latitude - _currentPosition.latitude) / numberOfSegments;
    double deltaLng = (nearestPoubellePosition.longitude - _currentPosition.longitude) / numberOfSegments;

    for (int i = 1; i < numberOfSegments; i++) {
    double lat = _currentPosition.latitude + deltaLat * i;
    double lng = _currentPosition.longitude + deltaLng * i;
    intermediatePoints.add(LatLng(lat, lng));
    }
    intermediatePoints.add(nearestPoubellePosition);
    return intermediatePoints;
    }

    void _showPoubelleDialog(LatLng nearestPoubellePosition) {
    showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: Text('Distance à la poubelle la plus proche'),
    content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text('Distance: ${distanceInKm.toStringAsFixed(2)} km'),
    ],
    ),
    actions: <Widget>[
    ElevatedButton(
    onPressed: () {
    double latitude = nearestPoubellePosition.latitude;
    double longitude = nearestPoubellePosition.longitude;
    _updatePoubelleStatut(latitude, longitude);
    Navigator.of(context).pop();
    },
    child: Text('Choisir cette poubelle'),
    ),
    TextButton(
    onPressed: () {
    Navigator.of(context).pop();
    },
    child: Text('Annuler'),
    ),
    ],
    );
    },
    );
    }
    void _updatePoubelleStatut(double latitude, double longitude) {
    DatabaseReference _poubelleRef = FirebaseDatabase.instance.reference().child('poubelles');

    _poubelleRef.once().then((event) {
    if (event.snapshot.value != null) {
    Map<dynamic, dynamic>? poubelles = event.snapshot.value as Map<dynamic, dynamic>?;

    if (poubelles != null && poubelles.isNotEmpty) {
    String? poubelleId;
    poubelles.forEach((key, value) {
    double poubelleLatitude = (value['latitude'] ?? 0).toDouble();
    double poubelleLongitude = (value['longitude'] ?? 0).toDouble();

    if (poubelleLatitude == latitude && poubelleLongitude == longitude) {
    poubelleId = key;
    }
    });

    if (poubelleId != null) {
    _poubelleRef.child(poubelleId!).update({
    'statut': 'oui',
    }).then((_) {
    print('Statut de la poubelle mise à jour avec succès.');
    }).catchError((error) {
    print('Erreur lors de la mise à jour du statut de la poubelle : $error');
    });
    } else {
    print('Aucune poubelle trouvée avec les coordonnées spécifiées.');
    }
    } else {
    print('Aucune poubelle disponible.');
    }
    } else {
    print('Aucune donnée de poubelle trouvée.');
    }
    }).catchError((error) {
    print('Erreur lors de la récupération des données de la poubelle: $error');
    });
    }


    void _addOtherCamionsMarkers() {
    FirebaseDatabase.instance.reference().child('comptes_camions').once().then((snapshot) {
    if (snapshot.snapshot.value != null) {
    Map<dynamic, dynamic>? camions = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (camions != null) {
    camions.forEach((key, value) {
    if (key != widget.userId) {
    double latitude = value['latitude'] ?? 0.0;
    double longitude = value['longitude'] ?? 0.0;
    String nom = value['nom'] ?? '';
    String prenom = value['prenom'] ?? '';
    String numeroCamion = value['numero_camion'] ?? '';

    _markers.add(
    Marker(
    markerId: MarkerId(key.toString()),
    position: LatLng(latitude, longitude),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    infoWindow: InfoWindow(
    title: '$nom $prenom',
    snippet: 'Numéro de camion: $numeroCamion',
    ),
    ),
    );
    }
    });
    setState(() {});
    }
    }
    });
    }
    }