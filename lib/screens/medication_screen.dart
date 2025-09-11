import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';
import 'package:recoveryplus/services/notification_service.dart';

class MedicationScreen extends StatefulWidget {
  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController();

  // State variables
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _showForm = false;
  bool _isLoading = false;
  User? _user;
  DatabaseService? _databaseService;

  // Services
  late final NotificationService _notificationService;
  final Map<String, int> _medicationNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _databaseService = DatabaseService(uid: _user!.uid);
    }

    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _user == null ? _buildAuthRequiredScreen() : _buildMainContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Medication Manager'),
      backgroundColor: Colors.blue.shade700,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_showForm ? Icons.close : Icons.add),
          onPressed: _toggleFormVisibility,
          tooltip: _showForm ? 'Close form' : 'Add medication',
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        if (_showForm) _buildAddMedicationForm(),
        Expanded(child: _buildMedicationList()),
      ],
    );
  }

  Widget _buildAuthRequiredScreen() {
    return Center(
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
            'Please sign in to manage medications',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _initializeServices, child: Text('Retry')),
        ],
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
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 16),
              _buildMedicationField(),
              SizedBox(height: 12),
              _buildDosageField(),
              SizedBox(height: 12),
              _buildTimeField(),
              SizedBox(height: 16),
              _buildFormButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationField() {
    return TextFormField(
      controller: _medicationController,
      decoration: InputDecoration(
        labelText: 'Medication Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.medication),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter medication name' : null,
    );
  }

  Widget _buildDosageField() {
    return TextFormField(
      controller: _dosageController,
      decoration: InputDecoration(
        labelText: 'Dosage (e.g., 500mg, 1 tablet)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.line_weight),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter dosage' : null,
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _timeController,
      decoration: InputDecoration(
        labelText: 'Time',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.access_time),
      ),
      readOnly: true,
      onTap: _selectTime,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please select time' : null,
    );
  }

  Widget _buildFormButtons() {
    return _isLoading
        ? CircularProgressIndicator()
        : Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelForm,
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
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add Medication'),
                ),
              ),
            ],
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
          return _buildEmptyState();
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

  Widget _buildEmptyState() {
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

  Widget _buildMedicationCard(
    String docId,
    Map<String, dynamic> data,
    bool isTaken,
  ) {
    final notificationId = _medicationNotificationIds[docId];
    final hasScheduledNotification =
        notificationId != null &&
        _notificationService.isNotificationScheduled(notificationId);

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
            if (hasScheduledNotification)
              Text(
                '🔔 Reminder set',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
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
              onChanged: (value) =>
                  _updateMedicationStatus(docId, value ?? false),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteMedication(docId),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _toggleFormVisibility() {
    setState(() => _showForm = !_showForm);
  }

  Future<void> _selectTime() async {
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
  }

  void _cancelForm() {
    setState(() => _showForm = false);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _addMedication();
    }
  }

  Future<void> _addMedication() async {
    if (_databaseService == null) return;

    setState(() => _isLoading = true);

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await _databaseService!.addMedication(
        _medicationController.text.trim(),
        _dosageController.text.trim(),
        _timeController.text.trim(),
      );

      await _notificationService.scheduleBackgroundCompatibleReminder(
        id: notificationId,
        medicationName: _medicationController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: _selectedTime,
      );

      _medicationNotificationIds[_medicationController.text.trim()] =
          notificationId;

      _showSuccess('Medication added with reminder!');
      _resetForm();
    } catch (error) {
      _showError('Failed to add medication: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMedicationStatus(String docId, bool taken) async {
    if (_databaseService == null) return;

    try {
      await _databaseService!.updateMedication(docId, taken);
      _showSuccess('Medication marked as ${taken ? 'taken' : 'not taken'}');
    } catch (error) {
      _showError('Failed to update medication: $error');
    }
  }

  Future<void> _deleteMedication(String docId) async {
    if (_databaseService == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                final notificationId = _medicationNotificationIds[docId];
                if (notificationId != null) {
                  await _notificationService.cancelNotification(notificationId);
                  _medicationNotificationIds.remove(docId);
                }

                await _databaseService!.deleteMedication(docId);
                _showSuccess('Medication deleted successfully');
              } catch (error) {
                _showError('Failed to delete medication: $error');
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _resetForm() {
    _medicationController.clear();
    _dosageController.clear();
    _timeController.clear();
    setState(() => _showForm = false);
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
