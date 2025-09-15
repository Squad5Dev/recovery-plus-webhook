import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);
  @override
  ExerciseScreenState createState() => ExerciseScreenState();
}

class ExerciseScreenState extends State<ExerciseScreen> {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_user == null) {
      return _buildAuthRequiredScreen(colorScheme, textTheme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plus'),
        foregroundColor: colorScheme.onPrimary, // Ensure text/icons are visible
        elevation: 0,
        actions: [],
      ),
      body: Column(
        children: [
          if (_showForm) _buildAddExerciseForm(colorScheme, textTheme),
          Expanded(child: _buildExerciseList(colorScheme, textTheme)),
        ],
      ),
      floatingActionButton: _user != null
          ? FloatingActionButton(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              onPressed: () {
                setState(() {
                  _showForm = !_showForm;
                });
              },
              tooltip: _showForm ? 'Close form' : 'Add exercise',
              child: Icon(_showForm ? Icons.close : Icons.add),
            )
          : null,
    );
  }

  Widget _buildAuthRequiredScreen(ColorScheme colorScheme, TextTheme textTheme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plus'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: colorScheme.onSurface),
            SizedBox(height: 20),
            Text(
              'Authentication Required',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            SizedBox(height: 10),
            Text(
              'Please sign in to access exercises',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
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

  Widget _buildAddExerciseForm(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 3,
      color: colorScheme.surface, // Use theme surface color
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Exercise',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _exerciseController,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
                  labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _setsController,
                decoration: InputDecoration(
                  labelText: 'Number of Sets',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
                  labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
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
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _repsController,
                decoration: InputDecoration(
                  labelText: 'Number of Reps',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat_one, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
                  labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
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
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
              SizedBox(height: 16),

              _isLoading
                  ? CircularProgressIndicator(color: colorScheme.primary)
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
                              backgroundColor: colorScheme.surface, // Use theme surface color
                              foregroundColor: colorScheme.onSurface,
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
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
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

  Widget _buildExerciseList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_databaseService == null) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService!.exercisesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading exercises', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        final exercises = snapshot.data?.docs ?? [];

        if (exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: colorScheme.onSurface.withAlpha((0.5 * 255).toInt())),
                SizedBox(height: 16),
                Text(
                  'No exercises added yet',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first exercise',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
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

            return _buildExerciseCard(exercise.id, data, isCompleted, colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(
    String docId,
    Map<String, dynamic> data,
    bool isCompleted,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: colorScheme.surface,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted ? colorScheme.secondary : colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center,
            color: isCompleted ? colorScheme.onSecondary : colorScheme.primary,
          ),
        ),
        title: Text(
          data['exercise'] ?? 'Unknown Exercise',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sets: ${data['sets'] ?? ''} | Reps: ${data['reps'] ?? ''}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
              ),
            ),
            if (data['createdAt'] != null)
              Text(
                'Added: ${_formatDate(data['createdAt']?.toDate())}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                ),
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
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error),
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
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            data['exercise'] ?? 'Exercise Details',
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sets: ${data['sets']}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                Text('Reps: ${data['reps']}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                SizedBox(height: 16),
                Text(
                  'Instructions:',
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(
                  'Perform this exercise slowly and carefully. Stop if you feel any pain.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
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
          content: Text('Exercise added successfully!', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
          backgroundColor: Theme.of(context).colorScheme.secondary,
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
          content: Text('Failed to add exercise: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update exercise: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteExercise(String docId) async {
    if (_databaseService == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Delete Exercise', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
          content: Text('Are you sure you want to delete this exercise?', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _databaseService!.deleteExercise(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exercise deleted successfully', style: TextStyle(color: colorScheme.onSecondary)),
                      backgroundColor: colorScheme.secondary,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete exercise: $error', style: TextStyle(color: colorScheme.onError)),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Delete', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
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