import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';

class PainTrackerWidget extends StatefulWidget {
  @override
  _PainTrackerWidgetState createState() => _PainTrackerWidgetState();
}

class _PainTrackerWidgetState extends State<PainTrackerWidget> {
  double _currentPainLevel = 0;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pain Level Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 16),

            // Custom pain level selector
            Text(
              'Select your pain level:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),

            // Number bubbles 0-10
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 11,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPainLevel = index.toDouble();
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: index <= _currentPainLevel
                            ? _getColorForPainLevel(index)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index <= _currentPainLevel
                              ? Colors.blue.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: TextStyle(
                            color: index <= _currentPainLevel
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16),
            Text(
              'Pain Level: ${_currentPainLevel.toInt()}/10',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Notes (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your pain or any concerns...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            _isSubmitting
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentPainLevel > 0 ? _submitPainData : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Record Pain Level'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPainLevel(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  // In lib/widgets/pain_tracker.dart
  Future<void> _submitPainData() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in to save data');
      }

      // 2. Create database service instance
      final databaseService = DatabaseService(uid: user.uid);

      // 3. Call the data storage method
      await databaseService.addPainLevel(
        _currentPainLevel.toInt(),
        _notesController.text,
      );

      // 4. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pain level saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // 5. Reset form
      setState(() {
        _currentPainLevel = 0;
        _notesController.clear();
      });
    } catch (error) {
      // 6. Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
