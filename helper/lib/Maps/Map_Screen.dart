import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import '../Components/Bottom_Nav_Bar.dart';
import '../Components/User_Name.dart'; // Add this import
import '../Components/Side_Bar.dart'; // Add this import
import '../Components/User_Avatar_Circle.dart'; // Add this import
// Add this import
import '../Employer Dashboard/job_detail_booking_screen.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? worker;
  final GeoPoint? destinationLatLng;
  final String? destinationLabel;
  final bool startNavigation;
  const MapScreen({
    super.key,
    this.worker,
    this.destinationLatLng,
    this.destinationLabel,
    this.startNavigation = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();
  final String _googleApiKey = 'AIzaSyBUJXjLSEFn_8OfVkaaLAIHYGUcGJEDD9w';
  final bool _showFilters = false;
  String? selectedFilter;
  Position? userPosition;
  List<String> topRatedCategories = [];
  Map<String, double> categoryRatings = {};

  late Widget _avatarWidget;

  late GoogleMapController mapController;

  final LatLng _center = const LatLng(
    45.521563,
    -122.677433,
  ); // Fallback center
  LatLng? _currentPosition; // To store current location
  final Set<Marker> _markers = {}; // To add a marker for current location
  final Set<Polyline> _polylines = {}; // To add polylines for routes
  List? _currentSteps; // To store current route steps
  LatLng? _destination; // To store destination for distance check
  StreamSubscription<Position>? _positionStream; // For location updates

  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _suggestions = [];

  int _selectedIndex = 1;

  late TextEditingController _controller;
  late FocusNode _focusNode;

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  IconData _getDirectionIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'straight':
        return Icons.arrow_upward;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.fork_left;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      default:
        return Icons.directions;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic if needed
  }

  Future<void> _getUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied. Please enable them in settings.',
          ),
        ),
      );
      return;
    }

    userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getTopRatedCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      topRatedCategories.clear();
      categoryRatings.clear();

      for (var categoryDoc in categoriesSnapshot.docs) {
        final categoryName = categoryDoc['name'] as String?;
        if (categoryName != null) {
          final rating = await _getCategoryRatings(categoryName);
          if (rating >= 4.0) {
            topRatedCategories.add(categoryName);
            categoryRatings[categoryName] = rating;
          }
        }
      }
    } catch (e) {
      print('Error fetching top rated categories: $e');
    }
  }

  Future<double> _getCategoryRatings(String categoryName) async {
    try {
      final providersSnapshot = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .where('category', isEqualTo: categoryName)
          .get();

      double totalRating = 0.0;
      int count = 0;

      for (var providerDoc in providersSnapshot.docs) {
        final providerId = providerDoc.id;
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(providerId)
            .collection('reviews')
            .get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          final rating = reviewDoc['rating'] as num?;
          if (rating != null) {
            totalRating += rating.toDouble();
            count++;
          }
        }
      }

      return count > 0 ? totalRating / count : 0.0;
    } catch (e) {
      print('Error fetching ratings for category $categoryName: $e');
      return 0.0;
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return null;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied. Please enable them in settings.',
          ),
        ),
      );
      return null;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final currentPos = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = currentPos;
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });

    // Move camera to current location
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
    );
    return currentPos;
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('serviceProviders')
        .get();
    _workers = snapshot.docs.map((doc) => doc.data()).toList();

    // Fetch status for each worker
    for (var i = 0; i < _workers.length; i++) {
      final uid = _workers[i]['uid'] as String?;
      if (uid != null) {
        // Fetch isOnline from users
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          _workers[i]['isOnline'] = userData?['isOnline'] ?? false;
        }
        // Fetch status from bookings
        final activeBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceProviderId', isEqualTo: uid)
            .where('status', whereIn: ['in_progress', 'started'])
            .limit(1)
            .get();
        _workers[i]['status'] = activeBookings.docs.isNotEmpty
            ? 'On Job'
            : 'Available';
      }
    }

    for (var worker in _workers) {
      final latLng = worker['workplaceLatLng'] as GeoPoint?;
      final portfolioFiles = worker['portfolioFiles'] as List<dynamic>?;
      if (latLng != null &&
          portfolioFiles != null &&
          portfolioFiles.isNotEmpty) {
        final imageUrl = portfolioFiles[0] as String;
        final marker = await _createMarkerFromImage(
          imageUrl,
          LatLng(latLng.latitude, latLng.longitude),
          worker['uid'] ?? 'unknown',
          worker,
        );
        setState(() {
          _markers.add(marker);
        });
      }
    }
  }

  void _handleWorkerNavigation() async {
    final worker = widget.worker!;
    final uid = worker['uid'] as String?;
    if (uid != null) {
      // Fetch isOnline from users
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        worker['isOnline'] = userData?['isOnline'] ?? false;
      }
      // Fetch status from bookings
      final activeBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: uid)
          .where('status', whereIn: ['in_progress', 'started'])
          .limit(1)
          .get();
      worker['status'] = activeBookings.docs.isNotEmpty
          ? 'On Job'
          : 'Available';
    }

    final latLng = worker['workplaceLatLng'] as GeoPoint?;
    if (latLng != null) {
      final position = LatLng(latLng.latitude, latLng.longitude);
      final portfolioFiles = worker['portfolioFiles'] as List<dynamic>?;
      if (portfolioFiles != null && portfolioFiles.isNotEmpty) {
        final imageUrl = portfolioFiles[0] as String;
        final marker = await _createMarkerFromImage(
          imageUrl,
          position,
          worker['uid'] ?? 'worker',
          worker,
        );
        setState(() {
          _markers.add(marker);
        });
      } else {
        // Add a default marker if no portfolio
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(worker['uid'] ?? 'worker'),
              position: position,
              infoWindow: InfoWindow(title: worker['businessName'] ?? 'Worker'),
            ),
          );
        });
      }
      // Center the map on the worker's location
      mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 15.0));
      // Show the bottom sheet
      _showWorkerDetails(worker);
    }
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<Marker> _createMarkerFromImage(
    String url,
    LatLng position,
    String id,
    Map<String, dynamic> worker,
  ) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final ui.Image image = await _loadImage(bytes);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;
    final radius = 18.0;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Determine stroke color based on status
    Color strokeColor;
    final status = worker['status'] as String? ?? 'Not Available';
    final isOnline = worker['isOnline'] as bool? ?? false;
    if (status == 'Available') {
      strokeColor = Colors.green;
    } else if (status == 'On Job') {
      strokeColor = Colors.orange;
    } else {
      strokeColor = Colors.red;
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius + 0.5, strokePaint);

    // Clip to circle and draw image
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, 36, 36),
      paint,
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(37, 37); // Adjusted for thinner stroke
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: BitmapDescriptor.bytes(pngBytes),
      onTap: () => _showWorkerDetails(worker),
    );
  }

  Future<Map<String, dynamic>> _getWorkerRating(String providerId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('serviceProviders')
        .doc(providerId)
        .collection('reviews')
        .get();
    double total = 0;
    int count = reviewsSnapshot.docs.length;
    for (var doc in reviewsSnapshot.docs) {
      final rating = doc['rating'] as num?;
      if (rating != null) total += rating.toDouble();
    }
    double average = count > 0 ? total / count : 0.0;
    return {'average': average, 'count': count};
  }

  void _onSearchChanged() {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final filtered = _workers
        .where((worker) {
          final location = worker['workplaceLocationText']?.toLowerCase() ?? '';
          final category = worker['jobCategoryName']?.toLowerCase() ?? '';
          final categoryId = worker['jobCategoryId']?.toLowerCase() ?? '';
          final business = worker['businessName']?.toLowerCase() ?? '';
          return location.contains(query) ||
              category.contains(query) ||
              categoryId.contains(query) ||
              business.contains(query);
        })
        .map(
          (worker) => {
            'text':
                '${worker['businessName']} - ${worker['jobCategoryName']} in ${worker['workplaceLocationText']}',
            'worker': worker,
          },
        )
        .toList();
    setState(() => _suggestions = filtered);
  }

  void _showWorkerDetails(Map<String, dynamic> worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final workerLatLng = worker['workplaceLatLng'] as GeoPoint?;
        final distance = (_currentPosition != null && workerLatLng != null)
            ? Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                workerLatLng.latitude,
                workerLatLng.longitude,
              )
            : 0.0;
        final distanceText = distance > 1000
            ? '${(distance / 1000).toStringAsFixed(1)} km'
            : '${distance.toInt()} m';
        return SizedBox(
          width: double.infinity,
          height: 560,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenWidth * 0.04,
                      left: screenWidth * 0.04,
                    ),
                    child: Text(
                      worker['businessName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.04),
                    child: Text(
                      worker['workplaceLocationText'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        worker['status'] == 'On Job'
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenWidth * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  'On Job',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenWidth * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  'Available',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                        GestureDetector(
                          onTap: () => _showDirections(worker),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenWidth * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions, color: Colors.black),
                                const SizedBox(width: 4),
                                const Text(
                                  'Directions',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height:
                        screenWidth *
                        0.32, // Height for huge rectangular images
                    child: GridView(
                      scrollDirection: Axis.horizontal,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                          ),
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children:
                          (worker['portfolioFiles'] as List<dynamic>? ?? [])
                              .take(4)
                              .map(
                                (url) => GestureDetector(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (context) =>
                                        Dialog(child: Image.network(url)),
                                  ),
                                  child: Container(
                                    height: screenWidth * 0.3,
                                    width: screenWidth * 0.4,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(url as String),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About me',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker['skillsDescription'] ??
                            'No description available',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailBookingScreen(
                                serviceProviderId: worker['uid'] ?? '',
                                businessName:
                                    worker['businessName'] ?? 'Provider',
                                profession:
                                    worker['jobCategoryName'] ?? 'Service',
                                amount: worker['amount'] ?? 0,
                                pricingType: worker['pricingType'] ?? 'fixed',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: screenWidth * 0.35,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenWidth * 0.04,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Book',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: screenWidth * 0.02,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.black),
                        const SizedBox(width: 4),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getWorkerRating(worker['uid'] ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Loading...');
                            }
                            if (snapshot.hasError) {
                              return const Text('N/A');
                            }
                            final data = snapshot.data!;
                            final average = data['average'] as double;
                            final count = data['count'] as int;
                            return Row(
                              children: [
                                Text(average.toStringAsFixed(1)),
                                const SizedBox(width: 4),
                                Text('($count)'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(distanceText),
                        const SizedBox(width: 4),
                        const Text(
                          'from you',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDirections(Map<String, dynamic> worker) async {
    print('Directions tapped');
    LatLng? origin = _currentPosition;
    if (origin == null) {
      print('Getting current location...');
      origin = await _getCurrentLocation();
      print('Got location: $origin');
    }
    final dest = worker['workplaceLatLng'] as GeoPoint?;
    print('Origin: $origin, Dest: $dest');
    if (origin == null || dest == null) {
      print('Location data not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data not available')),
      );
      return;
    }
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&key=$_googleApiKey';
      print('Fetching directions from: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      final data = json.decode(response.body);
      print('Response data status: ${data['status']}');
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        final steps = legs['steps'] as List;
        final polylinePoints = _decodePolyline(
          route['overview_polyline']['points'],
        );

        // Calculate bounds
        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        for (var point in polylinePoints) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: Colors.orange,
              width: 5,
            ),
          );
        });

        // Animate camera to fit the route
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

        setState(() {
          _currentSteps = steps;
          _destination = LatLng(dest.latitude, dest.longitude);
        });

        // Start location tracking for navigation
        _positionStream?.cancel();
        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5, // Update every 5 meters
              ),
            ).listen((Position position) {
              final current = LatLng(position.latitude, position.longitude);
              setState(() {
                _currentPosition = current;
                // Update marker
                _markers.removeWhere(
                  (m) => m.markerId.value == 'currentLocation',
                );
                _markers.add(
                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: current,
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  ),
                );
              });
              // Animate camera to current location
              mapController.animateCamera(CameraUpdate.newLatLng(current));
              // Check distance to destination
              if (_destination != null) {
                final distance = Geolocator.distanceBetween(
                  current.latitude,
                  current.longitude,
                  _destination!.latitude,
                  _destination!.longitude,
                );
                if (distance < 50) {
                  // Within 50 meters
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have reached the destination!'),
                    ),
                  );
                  // Stop tracking
                  _positionStream?.cancel();
                  _positionStream = null;
                  setState(() {
                    _polylines.clear();
                    _currentSteps = null;
                    _destination = null;
                  });
                }
              }
            });

        // Close the modal
        Navigator.of(context).pop();
      } else {
        print(
          'Failed with status: ${data['status']}, error: ${data['error_message']}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to get directions: ${data['status']} ${data['error_message'] ?? ''}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching directions')),
      );
    }
  }

  Future<void> _handleDestinationNavigation() async {
    final dest = widget.destinationLatLng;
    if (dest == null) return;
    LatLng? origin = _currentPosition;
    if (origin == null) {
      origin = await _getCurrentLocation();
    }
    if (origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data not available')),
      );
      return;
    }

    final destLatLng = LatLng(dest.latitude, dest.longitude);
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          infoWindow: InfoWindow(
            title: widget.destinationLabel ?? 'Destination',
          ),
        ),
      );
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&key=$_googleApiKey';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        final steps = legs['steps'] as List;
        final polylinePoints = _decodePolyline(
          route['overview_polyline']['points'],
        );

        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        for (var point in polylinePoints) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: Colors.orange,
              width: 5,
            ),
          );
          _currentSteps = steps;
          _destination = destLatLng;
        });

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

        _positionStream?.cancel();
        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
              ),
            ).listen((Position position) {
              final current = LatLng(position.latitude, position.longitude);
              setState(() {
                _currentPosition = current;
                _markers.removeWhere(
                  (m) => m.markerId.value == 'currentLocation',
                );
                _markers.add(
                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: current,
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  ),
                );
              });
              mapController.animateCamera(CameraUpdate.newLatLng(current));
              if (_destination != null) {
                final distance = Geolocator.distanceBetween(
                  current.latitude,
                  current.longitude,
                  _destination!.latitude,
                  _destination!.longitude,
                );
                if (distance < 50) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have reached the destination!'),
                    ),
                  );
                  _positionStream?.cancel();
                  _positionStream = null;
                  setState(() {
                    _polylines.clear();
                    _currentSteps = null;
                    _destination = null;
                  });
                }
              }
            });

        if (widget.startNavigation && _currentSteps != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showStepsModal();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to get directions: ${data['status']} ${data['error_message'] ?? ''}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching directions')),
      );
    }
  }

  void _showStepsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: _currentSteps!.length,
            itemBuilder: (context, index) {
              final step = _currentSteps![index] as Map<String, dynamic>;
              final instruction = step['html_instructions'] as String;
              final maneuver = step['maneuver'] as String?;
              final icon = _getDirectionIcon(maneuver);
              final cleanInstruction = instruction.replaceAll(
                RegExp(r'<[^>]*>'),
                '',
              );
              return ListTile(
                leading: Icon(icon, color: Colors.black),
                title: Text(cleanInstruction),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _avatarWidget = UserAvatarCircle();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onSearchChanged);
    _getCurrentLocation().then((_) {
      if (widget.destinationLatLng != null) {
        _handleDestinationNavigation();
      } else if (widget.worker != null) {
        _handleWorkerNavigation();
      } else {
        _loadWorkers();
      }
    }); // Request location on load and then load workers or handle worker
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target:
                    _currentPosition ??
                    _center, // Use current position if available, else fallback
                zoom: 11.0,
              ),
              markers: _markers, // Add markers to the map
              polylines: _polylines, // Add polylines for routes
            ),

            Positioned(
              top: 20,
              right: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _avatarWidget,
                  ),
                  const SizedBox(width: 10),
                  Stack(children: [
                    ],
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showFilters ? 130 : 175,
              left: _showFilters ? w * 0.04 : -500,
              child: SizedBox(
                width: w - 2 * w * 0.04,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => GestureDetector(
                        onTap: () async {
                          setState(() {
                            selectedFilter = index == 0
                                ? 'Nearest'
                                : index == 1
                                ? 'Top Rated'
                                : index == 2
                                ? 'Available'
                                : null;
                          });
                          if (index == 0 && userPosition == null) {
                            await _getUserPosition();
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color:
                                (index == 0 && selectedFilter == 'Nearest') ||
                                    (index == 1 &&
                                        selectedFilter == 'Top Rated') ||
                                    (index == 2 &&
                                        selectedFilter == 'Available')
                                ? Colors.blue[100]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: index == 0
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Nearest',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : index == 1
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Top Rated',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : index == 2
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Available',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _sidebarKey.currentState?.toggleDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.menu, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      UserName(), // Replaced const Text('User', ...) with UserName()
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 75,
              right: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 40,
                    width: w * 0.89,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 10),
                        Icon(Icons.search, color: Colors.black),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search for services here...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.black),
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            Positioned(
              top: w * 0.35,
              right: w * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              top: 135,
              left: w * 0.04,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Available',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('On Job', style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 10),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Offline', style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            if (_suggestions.isNotEmpty)
              Positioned(
                top: 125,
                left: w * 0.04,
                right: w * 0.04,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: Icon(Icons.search, color: Colors.black),
                        title: Text(
                          suggestion['text'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          final worker = suggestion['worker'];
                          final latLng = worker['workplaceLatLng'] as GeoPoint?;
                          if (latLng != null) {
                            mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(latLng.latitude, latLng.longitude),
                                15.0,
                              ),
                            );
                          }
                          _showWorkerDetails(worker);
                          setState(() => _suggestions = []);
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            if (_currentSteps != null)
              Positioned(
                bottom: 80,
                left: screenWidth * 0.5 - 50,
                child: GestureDetector(
                  onTap: _showStepsModal,
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'Steps',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            SideBar(key: _sidebarKey),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}

class DirectionsStepsScreen extends StatelessWidget {
  final List steps;

  const DirectionsStepsScreen({super.key, required this.steps});

  IconData _getDirectionIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'straight':
        return Icons.arrow_upward;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.fork_left;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      default:
        return Icons.directions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directions Steps')),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index] as Map<String, dynamic>;
          final instruction = step['html_instructions'] as String;
          final maneuver = step['maneuver'] as String?;
          final icon = _getDirectionIcon(maneuver);
          // Remove HTML tags from instruction
          final cleanInstruction = instruction.replaceAll(
            RegExp(r'<[^>]*>'),
            '',
          );
          return ListTile(
            leading: Icon(icon, color: Colors.black),
            title: Text(cleanInstruction),
          );
        },
      ),
    );
  }
}
