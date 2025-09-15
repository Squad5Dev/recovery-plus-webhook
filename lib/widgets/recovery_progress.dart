import 'package:flutter/material.dart';

class RecoveryProgressWidget extends StatelessWidget {
  final DateTime? surgeryDate;

  const RecoveryProgressWidget({Key? key, this.surgeryDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (surgeryDate == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Please set your surgery date in profile',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final difference = now.difference(surgeryDate!).inDays;
    final recoveryPercentage = (difference / 30 * 100).clamp(0, 100).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recovery Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Progress circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${recoveryPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Day $difference of recovery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onBackground),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Surgery date: ${_formatDate(surgeryDate!)}',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
