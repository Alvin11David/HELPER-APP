import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Side_Bar.dart';
import 'package:helper/Worker%20Dashboard/Worker_Details_Screen.dart';
import '../Components/Bottom_Nav_Bar.dart';

class NearYouProvidersScreen extends StatefulWidget {
  const NearYouProvidersScreen({super.key});

  @override
  State<NearYouProvidersScreen> createState() => _NearYouProvidersScreenState();
}

class _NearYouProvidersScreenState extends State<NearYouProvidersScreen> {
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();
  Position? _currentPos;
  bool _locLoading = true;
  String? _locError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locError = 'Location services are disabled.';
          _locLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locError = 'Location permissions are denied.';
            _locLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locError = 'Location permissions are permanently denied.';
          _locLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPos = position;
        _locLoading = false;
      });
    } catch (e) {
      setState(() {
        _locError = 'Error getting location: $e';
        _locLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // Top bar
              SizedBox(
                height: 70,
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: w * 0.04,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _sidebarKey.currentState?.toggleDrawer(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              UserName(),
                            ],
                          ),
                        ],
                      ),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Text(
                  'Service Providers Near You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _locLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _locError != null
                    ? Center(
                        child: Text(
                          _locError!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : _currentPos == null
                    ? const Center(
                        child: Text(
                          "Unable to get your location",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('serviceProviders')
                            .where('isActive', isEqualTo: true)
                            .where(
                              'onboardingStep',
                              isEqualTo: 'skills_job_details_done',
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final latLng = data['workplaceLatLng'] as GeoPoint?;
                            if (latLng == null) return false;

                            // Calculate distance
                            final distance = Geolocator.distanceBetween(
                              _currentPos!.latitude,
                              _currentPos!.longitude,
                              latLng.latitude,
                              latLng.longitude,
                            );

                            // Return providers within 50km (adjust as needed)
                            return distance <= 50000; // 50km in meters
                          }).toList();

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No service providers found near you',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final businessName =
                                  data['businessName'] ?? 'Unknown';
                              final jobCategory =
                                  data['jobCategoryName'] ?? 'Unknown';
                              final skills = data['skillsDescription'] ?? '';
                              final latLng =
                                  data['workplaceLatLng'] as GeoPoint?;
                              final distance = latLng != null
                                  ? Geolocator.distanceBetween(
                                          _currentPos!.latitude,
                                          _currentPos!.longitude,
                                          latLng.latitude,
                                          latLng.longitude,
                                        ) /
                                        1000 // to km
                                  : 0.0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(businessName),
                                  subtitle: Text(
                                    '$jobCategory\n${distance.toStringAsFixed(1)} km away\n$skills',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkerDetailsScreen(
                                                workerId: doc.id,
                                                providerId: '',
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('View Details'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

              // Bottom nav
              BottomNavBar(currentIndex: 0),
            ],
          ),
        ),
      ),
      drawer: SideBar(key: _sidebarKey),
    );
  }
}
