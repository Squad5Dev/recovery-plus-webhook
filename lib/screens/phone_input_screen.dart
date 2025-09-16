import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:recoveryplus/screens/otp_screen.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:provider/provider.dart';

class PhoneInputScreen extends StatefulWidget {
  @override
  _PhoneInputScreenState createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+1';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Verification', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'Enter your phone number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We\'ll send you a verification code',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                CountryCodePicker(
                  onChanged: (CountryCode countryCode) {
                    setState(() {
                      _countryCode = countryCode.dialCode!;
                    });
                  },
                  initialSelection: 'US',
                  favorite: ['+1', 'US'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
            ],
            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Send OTP'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    final fullPhoneNumber = _countryCode + phoneNumber;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[PhoneInputScreen] Attempting to verify phone number: $fullPhoneNumber');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.verifyPhoneNumber(fullPhoneNumber);
      debugPrint('[PhoneInputScreen] Phone number verification call completed.');

      // Navigate to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(phoneNumber: fullPhoneNumber),
        ),
      );
    } catch (error) {
      debugPrint('[PhoneInputScreen] ❌ Failed to send OTP: $error');
      setState(() {
        _errorMessage = 'Failed to send OTP: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
