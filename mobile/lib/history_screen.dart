import 'package:flutter/material.dart';
import 'services/api_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detection History")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!["data"] ?? [];

          if (records.isEmpty) {
            return const Center(child: Text("No history available"));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final item = records[index];
              return Card(
                child: ListTile(
                  title: Text("Objects: ${item["total_objects"]}"),
                  subtitle: Text(
                      item["detections"].map((d) => d["class"]).join(", ")),
                ),
              );
            },
          );
        },
      ),
    );
  }
}