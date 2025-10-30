import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final googleMap = Completer<GoogleMapController>();
  MapType mapType = MapType.normal;
  final Set<Marker> _markers = <Marker>{};
  CameraPosition? cameraPosition;
  StreamSubscription? streamingPostion;

  markerIcon() async {
    await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(45, 45)),
      'assets/icon.png',
    );
  }

  checkPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
      return;
    }
    if (status == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final target = LatLng(position.latitude, position.longitude);

    setState(() {
      cameraPosition = CameraPosition(target: target, zoom: 16);
      _markers.add(
        Marker(
          position: target,
          markerId: MarkerId('id'),
          infoWindow: InfoWindow(title: 'current'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
    });
  }

  startStreamLocation() {
    streamingPostion = Geolocator.getPositionStream().listen((posstion) {
      print('lat: ${posstion.latitude} | long: ${posstion.longitude}');
    });
  }

  stopStreamLocation() {
    if (streamingPostion != null) {
      streamingPostion!.cancel();
    }
  }

  @override
  void initState() {
    checkPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = (cameraPosition == null);
    return Scaffold(
      floatingActionButton: isLoading
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // FloatingActionButton(
                //   onPressed: () async {
                //     final controller = await googleMap.future;
                //     await controller.animateCamera(
                //       CameraUpdate.newCameraPosition(
                //         CameraPosition(
                //           target: LatLng(31.940960, 35.888723),
                //           zoom: 16,
                //         ),
                //       ),
                //     );
                //   },
                //   child: Icon(Icons.location_city),
                // ),
                // SizedBox(width: 20),
                // FloatingActionButton(
                //   onPressed: () async {
                //     if (mapType == MapType.satellite) {
                //       setState(() {
                //         mapType = MapType.normal;
                //       });
                //     } else {
                //       setState(() {
                //         mapType = MapType.satellite;
                //       });
                //     }
                //   },
                //   child: Icon(Icons.map),
                // ),
                // SizedBox(width: 20),
                // FloatingActionButton(
                //   onPressed: () async {
                //     checkPermission();
                //   },
                //   child: Icon(Icons.my_location),
                // ),
                ElevatedButton(
                  onPressed: () {
                    startStreamLocation();
                  },
                  child: Text('start', style: TextStyle(fontSize: 30)),
                ),
                SizedBox(width: 50),
                ElevatedButton(
                  onPressed: () {
                    stopStreamLocation();
                  },
                  child: Text('stop', style: TextStyle(fontSize: 30)),
                ),
              ],
            ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              myLocationButtonEnabled: false,
              initialCameraPosition: cameraPosition!,
              onTap: (target) {
                setState(() {
                  _markers.add(
                    Marker(
                      position: target,
                      markerId: MarkerId('id'),
                      infoWindow: InfoWindow(title: 'tapped'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  );
                });
              },
              markers: _markers,
              mapType: mapType,
              onMapCreated: (controller) {
                googleMap.complete(controller);
              },
            ),
    );
  }
}
