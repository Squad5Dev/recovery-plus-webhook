import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:recoveryplus/screens/exercise_screen.dart';
import 'package:recoveryplus/screens/medication_screen.dart';
import 'package:recoveryplus/screens/profile_screen.dart';
import 'package:recoveryplus/screens/appointments_screen.dart';
import 'package:recoveryplus/theme/app_theme.dart';
import 'package:recoveryplus/widgets/pain_tracker.dart';
import 'package:recoveryplus/widgets/recovery_progress.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recovery Dashboard'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome section
            _buildWelcomeSection(user.uid),
            SizedBox(height: 20),

            // Recovery Progress
            _buildRecoveryProgress(user.uid),
            SizedBox(height: 20),

            // Medication Summary
            _buildMedicationSummary(user.uid),
            SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(context),
            SizedBox(height: 20),

            // Pain Tracker
            PainTrackerWidget(),
            SizedBox(height: 20),

            // Today's Pain History
            _buildPainHistory(user.uid),
            SizedBox(height: 20),

            // Daily Tips
            _buildDailyTips(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        String userName = 'Patient';
        String surgeryType = 'Recovery';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          userName = data?['name'] ?? 'Patient';
          surgeryType = data?['surgeryType'] ?? 'Recovery';
        }

        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 64,
                  color: Colors.blue.shade700,
                ),
                SizedBox(height: 10),
                Text(
                  'Hello, $userName!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '$surgeryType Recovery Journey',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecoveryProgress(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        DateTime? surgeryDate;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          surgeryDate = data?['surgeryDate']?.toDate();
        }

        return RecoveryProgressWidget(surgeryDate: surgeryDate);
      },
    );
  }

  Widget _buildMedicationSummary(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(userId)
          .collection('medications')
          .where('taken', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final medications = snapshot.data?.docs ?? [];

        if (medications.isEmpty) {
          return SizedBox.shrink();
        }

        return Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medication, color: Colors.orange.shade700),
                    SizedBox(width: 10),
                    Text(
                      'Medication Reminder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'You have ${medications.length} medication(s) to take today',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  'Tap below to manage medications',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context,
                  Icons.medication,
                  'Meds',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.fitness_center,
                  'Exercise',
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExerciseScreen()),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.calendar_today,
                  'Appointments',
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.person,
                  'Profile',
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: Icon(icon, size: 30),
            onPressed: onPressed,
            color: color,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPainHistory(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(userId)
          .collection('pain_logs')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final painLogs = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        final todaysLogs = painLogs.where((log) {
          final timestamp = log['timestamp']?.toDate();
          return timestamp != null &&
              timestamp.day == now.day &&
              timestamp.month == now.month &&
              timestamp.year == now.year;
        }).toList();

        if (todaysLogs.isEmpty) {
          return SizedBox.shrink();
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      "Today's Pain History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Column(
                  children: todaysLogs.map((log) {
                    final data = log.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPainColor(data['painLevel']),
                        child: Text(
                          data['painLevel'].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        'Level ${data['painLevel']}/10',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          data['notes'] != null && data['notes'].isNotEmpty
                          ? Text(data['notes'])
                          : Text('No notes provided'),
                      trailing: Text(
                        _formatTime(data['timestamp']?.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8),
                Divider(),
                Text(
                  'Total entries today: ${todaysLogs.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyTips() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Recovery Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 12),
            _buildTipItem(
              'Take medications as prescribed',
              Icons.medication,
              Colors.blue.shade100,
            ),
            _buildTipItem(
              'Drink plenty of water',
              Icons.local_drink,
              Colors.green.shade100,
            ),
            _buildTipItem(
              'Perform recommended exercises',
              Icons.fitness_center,
              Colors.orange.shade100,
            ),
            _buildTipItem(
              'Rest when feeling tired',
              Icons.hotel,
              Colors.purple.shade100,
            ),
            _buildTipItem(
              'Track your pain levels regularly',
              Icons.analytics,
              Colors.red.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
