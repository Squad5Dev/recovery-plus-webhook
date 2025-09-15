import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox.shrink();

    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(user.uid)
          .collection('pain_logs')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final painData = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PainData(
            date: data['timestamp']?.toDate() ?? DateTime.now(),
            painLevel: (data['painLevel'] ?? 0).toDouble(), // Convert to double
          );
        }).toList();

        return SfCartesianChart(
          title: ChartTitle(
            text: 'Pain Level Trend',
            textStyle: TextStyle(color: theme.colorScheme.onBackground),
          ),
          primaryXAxis: DateTimeAxis(
            labelStyle: TextStyle(color: theme.colorScheme.onSurface),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 10,
            labelStyle: TextStyle(color: theme.colorScheme.onSurface),
          ),
          series: [
            LineSeries<PainData, DateTime>(
              dataSource: painData,
              xValueMapper: (PainData pain, _) => pain.date,
              yValueMapper: (PainData pain, _) => pain.painLevel,
              color: theme.colorScheme.primary,
              markerSettings: MarkerSettings(
                isVisible: true,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PainData {
  final DateTime date;
  final double painLevel; // Changed to double

  PainData({required this.date, required this.painLevel});
}
