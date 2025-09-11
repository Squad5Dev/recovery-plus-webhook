import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';

class ExerciseScreen extends StatefulWidget {
  @override
  _RealExerciseScreenState createState() => _RealExerciseScreenState();
}

class _RealExerciseScreenState extends State<ExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();

  bool _showForm = false;
  bool _isLoading = false;
  User? _user;
  DatabaseService? _databaseService;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    _user = FirebaseAuth.instance.currentUser;
    print('🏋️ Exercise Screen - User: ${_user?.uid}');

    if (_user != null) {
      _databaseService = DatabaseService(uid: _user!.uid);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return _buildAuthRequiredScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Program'),
        backgroundColor: Colors.blue.shade700,
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
          if (_showForm) _buildAddExerciseForm(),
          Expanded(child: _buildExerciseList()),
        ],
      ),
    );
  }

  Widget _buildAuthRequiredScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Program'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Authentication Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Please sign in to access exercises',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeUser,
              child: Text('Retry Authentication'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExerciseForm() {
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
                'Add New Exercise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _exerciseController,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _setsController,
                decoration: InputDecoration(
                  labelText: 'Number of Sets',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of sets';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _repsController,
                decoration: InputDecoration(
                  labelText: 'Number of Reps',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat_one),
                ),
                keyboardType: TextInputType.number,

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of reps';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
                                _addExercise();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Add Exercise'),
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

  Widget _buildExerciseList() {
    if (_databaseService == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService!.exercisesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading exercises'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final exercises = snapshot.data?.docs ?? [];

        if (exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No exercises added yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first exercise',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final data = exercise.data() as Map<String, dynamic>;
            final isCompleted = data['completed'] ?? false;

            return _buildExerciseCard(exercise.id, data, isCompleted);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(
    String docId,
    Map<String, dynamic> data,
    bool isCompleted,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center,
            color: isCompleted ? Colors.green : Colors.blue.shade700,
          ),
        ),
        title: Text(
          data['exercise'] ?? 'Unknown Exercise',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sets: ${data['sets'] ?? ''} | Reps: ${data['reps'] ?? ''}'),
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
              value: isCompleted,
              onChanged: (value) {
                _updateExerciseStatus(docId, value ?? false);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteExercise(docId);
              },
            ),
          ],
        ),
        onTap: () {
          _showExerciseDetails(data);
        },
      ),
    );
  }

  void _showExerciseDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['exercise'] ?? 'Exercise Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sets: ${data['sets']}'),
                Text('Reps: ${data['reps']}'),
                SizedBox(height: 16),
                Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Perform this exercise slowly and carefully. Stop if you feel any pain.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExercise() async {
    if (_databaseService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService!.addExercise(
        _exerciseController.text.trim(),
        int.parse(_setsController.text),
        int.parse(_repsController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _exerciseController.clear();
      _setsController.clear();
      _repsController.clear();
      setState(() {
        _showForm = false;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add exercise: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateExerciseStatus(String docId, bool completed) async {
    if (_databaseService == null) return;

    try {
      await _databaseService!.updateExerciseStatus(docId, completed);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exercise marked as ${completed ? 'completed' : 'not completed'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update exercise: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExercise(String docId) async {
    if (_databaseService == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Exercise'),
          content: Text('Are you sure you want to delete this exercise?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _databaseService!.deleteExercise(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exercise deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete exercise: $error'),
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
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }
}
