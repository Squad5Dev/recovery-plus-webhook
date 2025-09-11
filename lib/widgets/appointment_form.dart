// widgets/appointment_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/models/appointment.dart';

class AppointmentForm extends StatefulWidget {
  final Appointment? appointment;
  final Function(Appointment) onSave;

  AppointmentForm({this.appointment, required this.onSave});

  @override
  _AppointmentFormState createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _userAgeController = TextEditingController();
  final _userContactController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _hospitalContactController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCountryCode = '+91';
  String _selectedHospitalCountryCode = '+91';
  String? _selectedGender;

  // Focus nodes to control keyboard behavior
  final _userContactFocus = FocusNode();
  final _hospitalContactFocus = FocusNode();
  final _userAgeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _userNameController.text = widget.appointment!.userName ?? '';
      _userAgeController.text = widget.appointment!.userAge?.toString() ?? '';
      _userContactController.text = widget.appointment!.userContact ?? '';
      _selectedGender = widget.appointment!.userGender;
      _medicalHistoryController.text = widget.appointment!.medicalHistory ?? '';
      _titleController.text = widget.appointment!.title;
      _doctorController.text = widget.appointment!.doctorName;
      _locationController.text = widget.appointment!.location;
      _hospitalContactController.text = widget.appointment!.hospitalContact;
      _notesController.text = widget.appointment!.notes;
      _selectedDate = widget.appointment!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment!.dateTime);

      _extractCountryCodesFromExistingContacts();
    }

    // Prevent automatic keyboard opening
    _userContactFocus.addListener(() {});
    _hospitalContactFocus.addListener(() {});
    _userAgeFocus.addListener(() {});
  }

  void _extractCountryCodesFromExistingContacts() {
    if (widget.appointment?.hospitalContact?.isNotEmpty == true) {
      final contact = widget.appointment!.hospitalContact;
      if (contact.startsWith('+1'))
        _selectedHospitalCountryCode = '+1';
      else if (contact.startsWith('+44'))
        _selectedHospitalCountryCode = '+44';
      else if (contact.startsWith('+91'))
        _selectedHospitalCountryCode = '+91';
      else if (contact.startsWith('+61'))
        _selectedHospitalCountryCode = '+61';
    }

    if (widget.appointment?.userContact?.isNotEmpty == true) {
      final contact = widget.appointment!.userContact!;
      if (contact.startsWith('+1'))
        _selectedCountryCode = '+1';
      else if (contact.startsWith('+44'))
        _selectedCountryCode = '+44';
      else if (contact.startsWith('+91'))
        _selectedCountryCode = '+91';
      else if (contact.startsWith('+61'))
        _selectedCountryCode = '+61';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.appointment == null
                        ? 'Add Appointment'
                        : 'Edit Appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),

                // PERSONAL DETAILS SECTION
                Text(
                  'Your Personal Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 16),

                // Your Name
                Text(
                  'Full Name*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),

                // Age and Gender in Row
                Row(
                  children: [
                    // Age
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Age*',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          TextFormField(
                            controller: _userAgeController,
                            focusNode: _userAgeFocus,
                            decoration: InputDecoration(
                              hintText: 'Enter age',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 1 || age > 120) {
                                return 'Enter valid age';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),

                    // Gender
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            hint: Text(
                              'Select',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Male',
                                child: Text(
                                  'Male',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Female',
                                child: Text(
                                  'Female',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text(
                                  'Other',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Your Contact Number
                Text(
                  'Contact Number*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    // Country Code Dropdown
                    Container(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _selectedHospitalCountryCode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: '+91', child: Text('+91')),
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+44', child: Text('+44')),
                          DropdownMenuItem(value: '+61', child: Text('+61')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedHospitalCountryCode = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),

                    // Phone Number Field
                    Expanded(
                      child: TextFormField(
                        controller: _userContactController,
                        focusNode: _userContactFocus,
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number';
                          }
                          final digitsOnly = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          if (digitsOnly.length < 7) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Medical History
                Text(
                  'Medical History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                TextFormField(
                  controller: _medicalHistoryController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Diabetes, Hypertension, Allergies',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 20),

                // APPOINTMENT DETAILS SECTION
                Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 16),

                // Appointment Title
                Text(
                  'Appointment Type*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText:
                        'e.g., General Checkup, Dental Cleaning, Consultation',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter appointment type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Doctor's Name
                Text(
                  'Doctor\'s Name*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _doctorController,
                  decoration: InputDecoration(
                    hintText: 'Enter doctor\'s full name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(Icons.medical_services, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter doctor\'s name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Location
                Text(
                  'Hospital/Clinic Name & Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Name and full address of the hospital/clinic',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(Icons.location_on, size: 20),
                  ),
                ),
                SizedBox(height: 16),

                // Hospital Contact
                Text(
                  'Hospital Contact Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Country Code Dropdown
                    Container(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _selectedHospitalCountryCode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: '+91', child: Text('+91')),
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+44', child: Text('+44')),
                          DropdownMenuItem(value: '+61', child: Text('+61')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedHospitalCountryCode = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),

                    // Phone Number Field
                    Expanded(
                      child: TextFormField(
                        controller: _hospitalContactController,
                        focusNode: _hospitalContactFocus,
                        decoration: InputDecoration(
                          hintText: 'Hospital phone number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(Icons.phone, size: 20),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date*',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: Icon(Icons.calendar_month, size: 18),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time*',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: Icon(Icons.access_time, size: 18),
                            label: Text(_selectedTime.format(context)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Additional Notes
                Text(
                  'Additional Notes for Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText:
                        'Any special instructions or notes for this appointment',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(Icons.note, size: 20),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveAppointment,
                      child: Text('Save Appointment'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Combine country codes with phone numbers
      String fullHospitalContact = _hospitalContactController.text.isNotEmpty
          ? '$_selectedHospitalCountryCode${_hospitalContactController.text}'
          : '';

      String fullUserContact = _userContactController.text.isNotEmpty
          ? '$_selectedCountryCode${_userContactController.text}'
          : '';

      // Parse age
      int? userAge = int.tryParse(_userAgeController.text);

      final appointment = Appointment(
        id:
            widget.appointment?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: _userNameController.text,
        userAge: userAge,
        userGender: _selectedGender,
        userContact: fullUserContact,
        medicalHistory: _medicalHistoryController.text,
        title: _titleController.text,
        doctorName: _doctorController.text,
        location: _locationController.text,
        hospitalContact: fullHospitalContact,
        notes: _notesController.text,
        dateTime: dateTime,
        isCompleted: widget.appointment?.isCompleted ?? false,
      );

      widget.onSave(appointment);
    }
  }

  @override
  void dispose() {
    _userContactFocus.dispose();
    _hospitalContactFocus.dispose();
    _userAgeFocus.dispose();
    _userNameController.dispose();
    _userAgeController.dispose();
    _userContactController.dispose();
    _medicalHistoryController.dispose();
    _titleController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _hospitalContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
