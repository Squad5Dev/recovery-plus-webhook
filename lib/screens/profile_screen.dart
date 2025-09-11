import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:recoveryplus/providers/theme_provider.dart'; // Add this import
// Add to your profile_screen.dart imports
import 'package:recoveryplus/services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _RealProfileScreenState createState() => _RealProfileScreenState();
}

class _RealProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surgeryTypeController = TextEditingController();
  final _surgeryDateController = TextEditingController();
  final _doctorNameController = TextEditingController();

  DateTime? _surgeryDate;
  bool _isEditing = false;
  bool _isLoading = false;
  User? _user;
  DatabaseService? _databaseService;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadUserData();
  }

  void _initializeUser() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _databaseService = DatabaseService(uid: _user!.uid);
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('recovery_data')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _surgeryTypeController.text = data['surgeryType'] ?? '';
          _doctorNameController.text = data['doctorName'] ?? '';

          if (data['surgeryDate'] != null) {
            _surgeryDate = data['surgeryDate'].toDate();
            _surgeryDateController.text = _formatDate(_surgeryDate!);
          }
        });
      }
    } catch (error) {
      print('Error loading user data: $error');
    }
  }

  // Add these methods to handle export actions
  Future<void> _exportAllData() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preparing your data export...')));

      await ExportService.exportData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportPainData() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preparing pain data export...')));

      await ExportService.exportPainData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pain data exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update the _exportMedicationData method in profile_screen.dart
  Future<void> _exportMedicationData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preparing medication data export...')),
      );

      await ExportService.exportMedicationData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication data exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // Add this
    final isDarkMode = themeProvider.isDarkMode; // Add this

    if (_user == null) {
      return _buildAuthRequiredScreen(isDarkMode);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: isDarkMode
            ? Colors.grey.shade900
            : Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context, authService);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileAvatar(isDarkMode),
                    SizedBox(height: 24),
                    _buildEditableField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      isEditing: _isEditing,
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16),
                    _buildEditableField(
                      controller: _surgeryTypeController,
                      label: 'Surgery Type',
                      icon: Icons.medical_services,
                      isEditing: _isEditing,
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16),
                    _buildDateField(isDarkMode),
                    SizedBox(height: 16),
                    _buildEditableField(
                      controller: _doctorNameController,
                      label: 'Doctor\'s Name',
                      icon: Icons.medical_services,
                      isEditing: _isEditing,
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 24),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Save Changes'),
                        ),
                      ),
                    SizedBox(height: 20),
                    _buildAppInfo(isDarkMode),
                    SizedBox(height: 20),
                    _buildThemeSelector(isDarkMode),
                    _buildDataExportOptions(isDarkMode), // Add this
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAuthRequiredScreen(bool isDarkMode) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: isDarkMode
            ? Colors.grey.shade900
            : Colors.blue.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Please sign in to view profile',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _initializeUser();
                _loadUserData();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDarkMode) {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundColor: isDarkMode
            ? Colors.blue.shade800
            : Colors.blue.shade100,
        child: Icon(
          Icons.person,
          size: 50,
          color: isDarkMode ? Colors.purple.shade200 : Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditing,
    required bool isDarkMode,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !isEditing,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      ),
      readOnly: !isEditing,
      validator: (value) {
        if (isEditing && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(bool isDarkMode) {
    return TextFormField(
      controller: _surgeryDateController,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: 'Surgery Date',
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          Icons.calendar_today,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !_isEditing,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      ),
      readOnly: true,
      onTap: _isEditing
          ? () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _surgeryDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _surgeryDate = date;
                  _surgeryDateController.text = _formatDate(date);
                });
              }
            }
          : null,
      validator: (value) {
        if (_isEditing && (value == null || value.isEmpty)) {
          return 'Please select surgery date';
        }
        return null;
      },
    );
  }

  Widget _buildAppInfo(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.purple.shade200
                    : Colors.purple.shade700,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.info,
                color: isDarkMode ? Colors.purple.shade200 : Colors.purple,
              ),
              title: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.medical_services,
                color: isDarkMode ? Colors.green.shade200 : Colors.green,
              ),
              title: Text(
                'Post Surgery Recovery App',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.support,
                color: isDarkMode ? Colors.orange.shade200 : Colors.orange,
              ),
              title: Text(
                'Support: support@recoveryapp.com',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.purple.shade200
                    : Colors.purple.shade700,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.color_lens,
                color: isDarkMode ? Colors.purple.shade200 : Colors.purple,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setTheme(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _surgeryDate != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_databaseService != null) {
          await _databaseService!.updateUserData(
            _nameController.text.trim(),
            _surgeryTypeController.text.trim(),
            _surgeryDate!,
            _doctorNameController.text.trim(),
          );
        }

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to your profile_screen.dart
  Widget _buildDataExportOptions(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Export',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.green.shade200
                    : Colors.green.shade700,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.download,
                color: isDarkMode ? Colors.green.shade200 : Colors.green,
              ),
              title: Text(
                'Export All Data',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'CSV format for doctors',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              onTap: _exportAllData,
            ),
            ListTile(
              leading: Icon(
                Icons.analytics,
                color: isDarkMode ? Colors.blue.shade200 : Colors.blue,
              ),
              title: Text(
                'Export Pain Data',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Pain logs only',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              onTap: _exportPainData,
            ),
            ListTile(
              leading: Icon(
                Icons.medication,
                color: isDarkMode ? Colors.orange.shade200 : Colors.orange,
              ),
              title: Text(
                'Export Medication History',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Medication records',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              onTap: _exportMedicationData,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                authService.signOut();
                Navigator.pop(context);
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

  @override
  void dispose() {
    _nameController.dispose();
    _surgeryTypeController.dispose();
    _surgeryDateController.dispose();
    _doctorNameController.dispose();
    super.dispose();
  }
}
