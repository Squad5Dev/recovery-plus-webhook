// appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:recoveryplus/models/appointment.dart';
import 'package:recoveryplus/services/appointment_service.dart';
import 'package:recoveryplus/widgets/appointment_form.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentsScreen extends StatefulWidget {
  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userProfile = userDoc.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddAppointmentDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Upcoming'),
                    selected: _selectedIndex == 0,
                    onSelected: (selected) {
                      setState(() {
                        _selectedIndex = selected ? 0 : _selectedIndex;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Past'),
                    selected: _selectedIndex == 1,
                    onSelected: (selected) {
                      setState(() {
                        _selectedIndex = selected ? 1 : _selectedIndex;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child: _selectedIndex == 0
                ? _buildUpcomingAppointments()
                : _buildPastAppointments(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return StreamBuilder<List<Appointment>>(
      stream: AppointmentService.getUpcomingAppointments(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No upcoming appointments',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Use the + button to add your first appointment',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _buildAppointmentCard(appointment, false);
          },
        );
      },
    );
  }

  Widget _buildPastAppointments() {
    return StreamBuilder<List<Appointment>>(
      stream: AppointmentService.getAppointments(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading past appointments',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        // Filter for past appointments (completed or date in past)
        final pastAppointments = appointments.where((appt) {
          return appt.isCompleted || appt.dateTime.isBefore(DateTime.now());
        }).toList();

        if (pastAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No past appointments',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Completed appointments will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort by date (newest first)
        pastAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return ListView.builder(
          itemCount: pastAppointments.length,
          itemBuilder: (context, index) {
            final appointment = pastAppointments[index];
            return _buildAppointmentCard(appointment, true);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isPast) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : Colors.blue.shade700,
          child: Icon(Icons.calendar_today, color: Colors.white, size: 20),
        ),
        title: Text(
          appointment.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isPast ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. ${appointment.doctorName}'),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(appointment.dateTime),
            ),
            if (appointment.location.isNotEmpty) Text(appointment.location),
            if (appointment.hospitalContact.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 16),
                    SizedBox(width: 4),
                    Text(appointment.hospitalContact),
                  ],
                ),
              ),
            if (appointment.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Notes: ${appointment.notes}'),
              ),
          ],
        ),
        trailing: isPast
            ? IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteAppointment(appointment),
              )
            : PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(child: Text('Edit'), value: 'edit'),
                  PopupMenuItem(
                    child: Text('Mark Complete'),
                    value: 'complete',
                  ),
                  if (appointment.hospitalContact.isNotEmpty)
                    PopupMenuItem(
                      child: Text('Request via WhatsApp'),
                      value: 'whatsapp',
                    ),
                  PopupMenuItem(child: Text('Delete'), value: 'delete'),
                ],
                onSelected: (value) =>
                    _handleAppointmentAction(value, appointment),
              ),
        onTap: !isPast ? () => _editAppointment(appointment) : null,
      ),
    );
  }

  void _handleAppointmentAction(String action, Appointment appointment) {
    switch (action) {
      case 'edit':
        _editAppointment(appointment);
        break;
      case 'complete':
        _markAsCompleted(appointment);
        break;
      case 'whatsapp':
        _requestAppointmentViaWhatsApp(appointment);
        break;
      case 'delete':
        _deleteAppointment(appointment);
        break;
    }
  }

  void _editAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentForm(
        appointment: appointment,
        onSave: (updatedAppointment) async {
          try {
            await AppointmentService.updateAppointment(updatedAppointment);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Appointment updated successfully')),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating appointment: ${e.toString()}'),
              ),
            );
          }
        },
      ),
    );
  }

  void _markAsCompleted(Appointment appointment) async {
    try {
      await AppointmentService.markAsCompleted(appointment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Appointment'),
        content: Text(
          'Are you sure you want to delete this appointment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppointmentService.deleteAppointment(appointment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // ADD THIS MISSING METHOD
  void _showAddAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppointmentForm(
        onSave: (appointment) async {
          try {
            await AppointmentService.addAppointment(appointment);
            Navigator.pop(context);

            // Show option to request appointment via WhatsApp
            if (appointment.hospitalContact.isNotEmpty) {
              _showWhatsAppRequestDialog(appointment);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Appointment added successfully')),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding appointment: ${e.toString()}'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showWhatsAppRequestDialog(Appointment appointment) {
    // First validate if the phone number is valid
    String formattedNumber = _formatPhoneNumber(appointment.hospitalContact);
    bool hasValidContact = formattedNumber.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Added'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your appointment has been added to your list.'),
            if (!hasValidContact) ...[
              SizedBox(height: 12),
              Text(
                'Note: The contact number provided may not be valid for WhatsApp.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Appointment added successfully')),
              );
            },
            child: Text('Not Now'),
          ),
          if (hasValidContact)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestAppointmentViaWhatsApp(appointment);
              },
              child: Text('Request via WhatsApp'),
            ),
        ],
      ),
    );
  }

  void _requestAppointmentViaWhatsApp(Appointment appointment) async {
    if (appointment.hospitalContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No contact number available for this appointment'),
        ),
      );
      return;
    }

    try {
      // Clean and format the phone number
      String phoneNumber = _formatPhoneNumber(appointment.hospitalContact);

      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid phone number format')));
        return;
      }

      // Create detailed message with all appointment information and user profile
      String message = await _createDetailedAppointmentMessage(appointment);

      // Create the WhatsApp URL
      String url =
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        // Fallback to regular SMS
        String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
        if (await canLaunch(smsUrl)) {
          await launch(smsUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch messaging app. Please check if WhatsApp is installed.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<String> _createDetailedAppointmentMessage(
    Appointment appointment,
  ) async {
    String date = DateFormat(
      'EEEE, MMMM dd, yyyy',
    ).format(appointment.dateTime);
    String time = DateFormat('hh:mm a').format(appointment.dateTime);

    // Get user profile data
    String userName = user?.displayName ?? 'Patient';
    String userEmail = user?.email ?? '';
    String userAge = _userProfile?['age']?.toString() ?? 'Not specified';
    String userGender = _userProfile?['gender']?.toString() ?? 'Not specified';
    String userBloodGroup =
        _userProfile?['bloodGroup']?.toString() ?? 'Not specified';
    String userMedicalHistory =
        _userProfile?['medicalHistory']?.toString() ?? 'None';

    return '''
Hello, I would like to request an appointment with the following details:

*PATIENT INFORMATION*
👤 *Name*: ${appointment.userName}
📧 *Email*: $userEmail
📞 *Phone*: ${appointment.userContact?.isNotEmpty == true ? appointment.userContact! : 'Will provide'}
🎂 *Age*: ${appointment.userAge}
🚻 *Gender*: ${appointment.userGender}
🩸 *Blood Group*: $userBloodGroup
📋 *Medical History*: ${appointment.medicalHistory}

*APPOINTMENT DETAILS*
📋 *Type*: ${appointment.title}
👨‍⚕️ *Doctor*: Dr. ${appointment.doctorName}
📅 *Preferred Date*: $date
⏰ *Preferred Time*: $time
📍 *Location*: ${appointment.location.isNotEmpty ? appointment.location : 'To be confirmed'}

*CONTACT INFORMATION*
🏥 *Hospital Contact*: ${appointment.hospitalContact.isNotEmpty ? appointment.hospitalContact : 'Not provided'}

${appointment.notes.isNotEmpty ? '📝 *Additional Notes*: ${appointment.notes}' : ''}

Please confirm if this time works or let me know your available slots.

Looking forward to your response.

Thank you!
''';
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) return '';

    // If number starts with 0, remove it
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Add country code if not present (adjust for your region)
    if (!cleaned.startsWith('+')) {
      // Check if it already has country code
      if (cleaned.length <= 10) {
        cleaned = '1$cleaned'; // Default to US/Canada (+1)
      }
    }

    return cleaned;
  }
}
