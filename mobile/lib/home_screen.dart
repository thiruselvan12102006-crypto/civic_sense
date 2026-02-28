import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'history_screen.dart';
import 'widgets/detection_chart.dart';
import 'widgets/animated_background.dart';
import 'widgets/risk_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  XFile? selectedImage;
  Map<String, dynamic>? detectionResult;
  bool loading = false;

  double? latitude;
  double? longitude;

  // ==============================
  // Risk Color
  // ==============================
  Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case "high":
        return Colors.redAccent;
      case "medium":
        return Colors.orangeAccent;
      case "low":
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  // ==============================
  // Get Location
  // ==============================
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    return await Geolocator.getCurrentPosition();
  }

  // ==============================
  // Pick Image
  // ==============================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = picked;
        detectionResult = null;
      });
    }
  }

  // ==============================
  // Run Detection
  // ==============================
  Future<void> runDetection() async {

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image first")),
      );
      return;
    }

    setState(() => loading = true);

    try {

      final position = await _getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;

      final result = await ApiService.uploadImageWeb(
        selectedImage!,
        latitude!,
        longitude!,
      );

      setState(() {
        detectionResult = result;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    final detections = detectionResult?["detections"] ?? [];
    final riskLevel = detectionResult?["risk_level"] ?? "N/A";

    final highConfidenceCount = detections
        .where((item) {
          final confidence = (item["confidence"] as num).toDouble();
          return confidence > 0.8;
        })
        .length;

    final totalObjects = detections.length;
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("CivicSense AI"),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Select Image"),
              ),

              const SizedBox(height: 20),

              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    selectedImage!.path,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: runDetection,
                child: const Text("Run Detection"),
              ),

              const SizedBox(height: 20),

              if (loading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Running AI Model... Please wait")
                  ],
                ),

              const SizedBox(height: 20),

              // ==============================
              // Risk Badge
              // ==============================
              if (detectionResult != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: getRiskColor(riskLevel).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: getRiskColor(riskLevel),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: getRiskColor(riskLevel).withOpacity(0.6),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Text(
                    "Risk Level: $riskLevel",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: getRiskColor(riskLevel),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ==============================
              // Summary Panel
              // ==============================
              if (detectionResult != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Detection Summary",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("📦 Total Objects: $totalObjects"),
                      Text("⚠ High Confidence (>80%): $highConfidenceCount"),
                      Text("🕒 Time: $timestamp"),
                      const Text("📍 Location: Captured"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ==============================
              // Map
              // ==============================
              if (latitude != null && longitude != null)
                RiskMap(
                  latitude: latitude!,
                  longitude: longitude!,
                  riskLevel: riskLevel,
                ),

              const SizedBox(height: 20),

              // ==============================
              // Detection Cards
              // ==============================
              if (detections.isNotEmpty)
                Column(
                  children: [

                    ...detections.map((item) {

                      final confidence =
                          (item["confidence"] as num).toDouble();

                      return Card(
                        color: Colors.white.withOpacity(0.08),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["class"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: confidence,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                              ),
                            ],
                          ),
                        ),
                      );

                    }).toList(),

                    const SizedBox(height: 20),

                    DetectionChart(detections: detections),

                  ],
                ),

              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}