import 'package:flutter/material.dart';
import 'package:recoveryplus/services/auth_service.dart';
import 'package:recoveryplus/screens/home_screen.dart';
import 'package:provider/provider.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  // ignore: unused_field
  bool _isResending = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We sent a 6-digit code to ${widget.phoneNumber}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            SizedBox(height: 30),

            // Custom OTP input
            Text(
              'Enter 6-digit code:',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).nextFocus();
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                );
              }),
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
                      onPressed: _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Verify OTP'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    final smsCode = _getOTPCode();

    if (smsCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[OTPScreen] Attempting to sign in with OTP: $smsCode');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithOTP(smsCode);
      debugPrint('[OTPScreen] Sign in with OTP call completed.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (error) {
      debugPrint('[OTPScreen] ❌ OTP verification failed: ${error.toString()}');
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
