import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final googleMapController = Completer<GoogleMapController>();
  MapType mapType = MapType.normal;
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polines = <Polyline>{};

  CameraPosition? cameraPosition;
  StreamSubscription? streamingPostion;
  LatLng? currentLocation;
  LatLng? endLocation;

  getPoliline() async {
    final polyline = PolylinePoints(
      apiKey: "AIzaSyBbsdssB1T_BiP8NAQHTMkoQclo-IwVr0o",
    );
    if (currentLocation != null && endLocation != null) {
      final request = RoutesApiRequest(
        origin: PointLatLng(
          currentLocation!.latitude,
          currentLocation!.longitude,
        ),
        destination: PointLatLng(endLocation!.latitude, endLocation!.longitude),
      );

      final response = await polyline.getRouteBetweenCoordinatesV2(
        request: request,
      );
      // print(response.errorMessage);
      if (response.routes.isNotEmpty) {
        final route = response.routes.first;

        print('time: ${route.durationMinutes} min');
        print('distance: ${route.distanceMeters} m');

        //
        final polylinePoints = route.polylinePoints;
        final points = polylinePoints!
            .map((value) => LatLng(value.latitude, value.longitude))
            .toList();
        _polines.add(
          Polyline(
            polylineId: PolylineId('polyline'),
            points: points,
            color: Colors.red,
          ),
        );
        setState(() {});
      } else {
        print('no routes ');
      }
    } else {
      print('please select a location');
    }
  }

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
          markerId: MarkerId('current'),
          infoWindow: InfoWindow(title: 'current'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
      currentLocation = target;
    });
  }

  startStreamLocation() {
    streamingPostion = Geolocator.getPositionStream().listen((posstion) {
      updateMarkerAndCamera(posstion);
    });
  }

  stopStreamLocation() {
    if (streamingPostion != null) {
      streamingPostion!.cancel();
    }
  }

  updateMarkerAndCamera(Position latLng) async {
    final controller = await googleMapController.future;
    final target = LatLng(latLng.latitude, latLng.longitude); //
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
    setState(() {
      _markers.add(Marker(markerId: MarkerId('current'), position: target));
    });
  }

  latLngToAdress(LatLng latlng) async {
    final place = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(child: Text(place[0].locality.toString())),
      ),
    );
  }

  addressToLatLng() async {
    final latLng = await locationFromAddress("Amman, Wadi Saqra");
    //
    final controller = await googleMapController.future;
    final target = LatLng(latLng[0].latitude, latLng[0].longitude);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
    setState(() {
      _markers.add(Marker(markerId: MarkerId('Amman'), position: target));
    });
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
                // ElevatedButton(
                //   onPressed: () {
                //     startStreamLocation();
                //   },
                //   child: Text('start', style: TextStyle(fontSize: 30)),
                // ),
                // SizedBox(width: 50),
                // ElevatedButton(
                //   onPressed: () {
                //     stopStreamLocation();
                //   },
                //   child: Text('stop', style: TextStyle(fontSize: 30)),
                // ),
                // ElevatedButton(
                //   onPressed: () {
                //     addressToLatLng();
                //   },
                //   child: Text('get locations', style: TextStyle(fontSize: 30)),
                // ),
                ElevatedButton(
                  onPressed: () {
                    getPoliline();
                  },
                  child: Text('get polyline', style: TextStyle(fontSize: 30)),
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
                  endLocation = target;
                });
              },
              markers: _markers,
              polylines: _polines,
              mapType: mapType,
              onMapCreated: (controller) {
                googleMapController.complete(controller);
              },
            ),
    );
  }
}
