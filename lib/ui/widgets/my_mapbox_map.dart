// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
//
// import 'package:flutter/material.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
//
// class MyMapboxMap extends StatefulWidget {
//   final Function(MapboxMapController)? onMapCreated;
//   final VoidCallback? onMapStyleLoadedCallback;
//   final CameraPosition initialCameraPosition;
//
//   const MyMapboxMap({
//     super.key,
//     this.onMapCreated,
//     this.onMapStyleLoadedCallback,
//     required this.initialCameraPosition,
//   });
//
//   @override
//   State<MyMapboxMap> createState() => _MyMapboxMapState();
// }
//
// class _MyMapboxMapState extends State<MyMapboxMap> {
//   bool myLocationEnabled = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Permission.location.isGranted.then((value) {
//     //   myLocationEnabled = value;
//     // });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MapboxMap(
//       accessToken:
//           'sk.eyJ1IjoidmFuZGVydmFpeiIsImEiOiJjbTA1azhkNjEwNDF2MmtzNHA0eWJ3eTR0In0.cSGmIeLW1Wc44gyBBWJsYA',
//       myLocationEnabled: myLocationEnabled,
//       onMapCreated: (mapBoxController) {
//         widget.onMapCreated?.call(mapBoxController);
//       },
//       onStyleLoadedCallback: () {
//         widget.onMapStyleLoadedCallback?.call();
//
//         setState(() {
//           myLocationEnabled = true;
//         });
//       },
//       myLocationRenderMode: MyLocationRenderMode.GPS,
//       initialCameraPosition: widget.initialCameraPosition,
//     );
//   }
// }
