import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // ==============================
  // Upload Image and Run Detection
  // ==============================
  static Future<Map<String, dynamic>> uploadImageWeb(
      XFile imageFile,
    double latitude,
    double longitude,
) async {

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("User not authenticated.");
  }

  final idToken = await user.getIdToken();

  if (idToken == null || idToken.isEmpty) {
    throw Exception("Token missing.");
  }

  final bytes = await imageFile.readAsBytes();

  var request = http.MultipartRequest(
    "POST",
    Uri.parse("$baseUrl/detect"),
  );

  request.headers["Authorization"] = "Bearer $idToken";

  request.fields["latitude"] = latitude.toString();
  request.fields["longitude"] = longitude.toString();

  request.files.add(
    http.MultipartFile.fromBytes(
      "file",
      bytes,
      filename: imageFile.name,
    ),
  );

  var response = await request.send();
  var responseData = await response.stream.bytesToString();

  if (response.statusCode != 200) {
    throw Exception("Server Error: $responseData");
  }

  return jsonDecode(responseData);
}

  // ==============================
  // Get Detection History
  // ==============================
  static Future<Map<String, dynamic>> getHistory() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not authenticated.");
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw Exception("Authentication token missing.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/history"),
      headers: {
        "Authorization": "Bearer $idToken",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch history");
    }

    return jsonDecode(response.body);
  }
}