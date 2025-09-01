import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';
import 'package:recoveryplus/services/notification_service.dart';

class MedicationScreen extends StatefulWidget {
  @override
  _RealMedicationScreenState createState() => _RealMedicationScreenState();
}

class _RealMedicationScreenState extends State<MedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _showForm = false;
  bool _isLoading = false;
  User? _user;
  DatabaseService? _databaseService;

  late NotificationService _notificationService; // ✅ declare it

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _notificationService = NotificationService();
    NotificationService()
        .requestPermissions(); // request notification permissions
  }

  void _initializeUser() {
    // Get user directly from Firebase Auth
    _user = FirebaseAuth.instance.currentUser;
    print('🔥 Direct user from Firebase: ${_user?.uid}');

    if (_user != null) {
      _databaseService = DatabaseService(uid: _user!.uid);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 Building Medication Screen');
    print('🔥 User UID: ${_user?.uid}');
    print('🔥 User email: ${_user?.email}');

    // Show loading if still initializing
    if (_user == null) {
      return _buildAuthRequiredScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Manager'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showForm) _buildAddMedicationForm(),
          Expanded(child: _buildMedicationList()),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "immediate",
              onPressed: () {
                _notificationService.showImmediateNotification(
                  id: 999,
                  medicationName: "Test Medicine",
                  dosage: "1 pill",
                );
              },
              child: const Icon(Icons.notifications_active),
            ),
            const SizedBox(height: 10), // ✅ this is perfectly valid
            FloatingActionButton(
              heroTag: "scheduled",
              onPressed: () {
                final now = TimeOfDay.now();
                final oneMinuteLater = TimeOfDay(
                  hour: now.minute == 59 ? (now.hour + 1) % 24 : now.hour,
                  minute: (now.minute + 1) % 60,
                );

                _notificationService.scheduleMedicationReminder(
                  id: 1000,
                  medicationName: "Scheduled Test",
                  dosage: "2 pills",
                  time: oneMinuteLater,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⏰ Notification scheduled in 1 minute"),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.timer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthRequiredScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Manager'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Authentication Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Please sign in to access medications',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate back to auth
                Navigator.pop(context);
              },
              child: Text('Go to Sign In'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _initializeUser,
              child: Text('Retry Authentication Check'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicationForm() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Medication',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _medicationController,
                decoration: InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g., 500mg, 1 tablet)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.line_weight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                      _timeController.text =
                          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              _isLoading
                  ? CircularProgressIndicator()
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showForm = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _addMedication();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Add Medication'),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    if (_databaseService == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService!.medicationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading medications'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final medications = snapshot.data?.docs ?? [];

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No medications added yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first medication',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            final data = medication.data() as Map<String, dynamic>;
            final isTaken = data['taken'] ?? false;

            return _buildMedicationCard(medication.id, data, isTaken);
          },
        );
      },
    );
  }

  Widget _buildMedicationCard(
    String docId,
    Map<String, dynamic> data,
    bool isTaken,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isTaken ? Colors.green.shade100 : Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medication,
            color: isTaken ? Colors.green : Colors.blue.shade700,
          ),
        ),
        title: Text(
          data['medication'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isTaken ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${data['dosage'] ?? ''}'),
            Text('Time: ${data['time'] ?? ''}'),
            if (data['createdAt'] != null)
              Text(
                'Added: ${_formatDate(data['createdAt']?.toDate())}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isTaken,
              onChanged: (value) {
                _updateMedicationStatus(docId, value ?? false);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteMedication(docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedication() async {
    if (_databaseService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService!.addMedication(
        _medicationController.text.trim(),
        _dosageController.text.trim(),
        _timeController.text.trim(),
      );
      // ✅ Schedule notification
      await _notificationService.scheduleMedicationReminder(
        id: DateTime.now().millisecondsSinceEpoch.remainder(
          100000,
        ), // unique ID
        medicationName: _medicationController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: _selectedTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _medicationController.clear();
      _dosageController.clear();
      _timeController.clear();
      setState(() {
        _showForm = false;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add medication: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMedicationStatus(String docId, bool taken) async {
    if (_databaseService == null) return;

    try {
      await _databaseService!.updateMedication(docId, taken);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medication marked as ${taken ? 'taken' : 'not taken'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update medication: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMedication(String docId) async {
    if (_databaseService == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Medication'),
          content: Text('Are you sure you want to delete this medication?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _databaseService!.deleteMedication(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Medication deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete medication: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
