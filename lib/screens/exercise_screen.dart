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
  final _exerciseNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _frequencyController = TextEditingController();

  bool _showForm = false;
  bool _isLoading = false;
  User? _user;
  DatabaseService? _databaseService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    print("ExerciseScreen: Initializing services...");
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _databaseService = DatabaseService(uid: _user!.uid);
      print("ExerciseScreen: DatabaseService initialized for user: ${_user!.uid}");
    } else {
      print("ExerciseScreen: User not authenticated.");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plus'),
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: _user == null
          ? _buildAuthRequiredScreen(colorScheme, textTheme)
          : Column(
              children: [
                if (_showForm) _buildAddExerciseForm(colorScheme, textTheme),
                Expanded(child: _buildExerciseList(colorScheme, textTheme)),
              ],
            ),
      floatingActionButton: _user != null
          ? FloatingActionButton(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              onPressed: _toggleFormVisibility,
              tooltip: _showForm ? 'Close form' : 'Add exercise',
              child: Icon(_showForm ? Icons.close : Icons.add),
            )
          : null,
    );
  }

  Widget _buildAuthRequiredScreen(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.secondary),
          SizedBox(height: 20),
          Text(
            'Authentication Required',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          SizedBox(height: 10),
          Text(
            'Please sign in to manage exercises',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseForm(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              _buildExerciseNameField(colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildDurationField(colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildFrequencyField(colorScheme, textTheme),
              const SizedBox(height: 16),
              _buildFormButtons(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseNameField(ColorScheme colorScheme, TextTheme textTheme) {
    return TextFormField(
      controller: _exerciseNameController,
      decoration: InputDecoration(
        labelText: 'Exercise Name',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surface.withAlpha((0.95 * 255).toInt()),
        prefixIcon: Icon(Icons.fitness_center, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline.withAlpha((0.4 * 255).toInt())),
        ),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter exercise name' : null,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    );
  }

  Widget _buildDurationField(ColorScheme colorScheme, TextTheme textTheme) {
    return TextFormField(
      controller: _durationController,
      decoration: InputDecoration(
        labelText: 'Duration (e.g., 30 mins, 3 sets)',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surface.withAlpha((0.95 * 255).toInt()),
        prefixIcon: Icon(Icons.timer, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline.withAlpha((0.4 * 255).toInt())),
        ),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter duration' : null,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    );
  }

  Widget _buildFrequencyField(ColorScheme colorScheme, TextTheme textTheme) {
    return TextFormField(
      controller: _frequencyController,
      decoration: InputDecoration(
        labelText: 'Frequency (e.g., Daily, 3 times a week)',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surface.withAlpha((0.95 * 255).toInt()),
        prefixIcon: Icon(Icons.repeat, color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline.withAlpha((0.4 * 255).toInt())),
        ),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter frequency' : null,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    );
  }

  Widget _buildFormButtons(ColorScheme colorScheme, TextTheme textTheme) {
    return _isLoading
        ? CircularProgressIndicator(color: colorScheme.primary)
        : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelForm,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withAlpha((0.5 * 255).toInt())),
                  ),
                  child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text('Add Exercise', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
                ),
              ),
            ],
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
          return _buildEmptyState(colorScheme, textTheme);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final data = exercise.data() as Map<String, dynamic>;
            return _buildExerciseCard(exercise.id, data, colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: colorScheme.onSurface.withAlpha((0.5 * 255).toInt())),
          const SizedBox(height: 16),
          Text(
            'No exercises added yet',
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first exercise',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    String docId,
    Map<String, dynamic> data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: colorScheme.surface,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surface.withAlpha((0.95 * 255).toInt()),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          data['name'] ?? 'Unknown',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: ${data['duration'] ?? ''}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha((0.8 * 255).toInt())),
            ),
            Text(
              'Frequency: ${data['frequency'] ?? ''}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha((0.8 * 255).toInt())),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: colorScheme.error),
          onPressed: () => _deleteExercise(docId),
          tooltip: 'Delete exercise',
        ),
      ),
    );
  }

  void _toggleFormVisibility() {
    setState(() => _showForm = !_showForm);
  }

  void _cancelForm() {
    setState(() => _showForm = false);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _addExercise();
    }
  }

  Future<void> _addExercise() async {
    if (_user == null || _databaseService == null) {
      print("ExerciseScreen: User not authenticated or _databaseService is null. Cannot add exercise.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      print("ExerciseScreen: Attempting to add exercise: ${_exerciseNameController.text.trim()}");
      await _databaseService!.addExercise(
        _exerciseNameController.text.trim(),
        _durationController.text.trim(),
        _frequencyController.text.trim(),
      );
      _showSuccess('Exercise added successfully!');
      _resetForm();
      print("ExerciseScreen: Exercise added and form reset.");
    } catch (error, stackTrace) {
      print("ExerciseScreen: Failed to add exercise: $error\n$stackTrace");
      _showError('Failed to add exercise: $error');
    } finally {
      setState(() => _isLoading = false);
      print("ExerciseScreen: _addExercise finished. isLoading set to false.");
    }
  }

  Future<void> _deleteExercise(String docId) async {
    if (_user == null || _databaseService == null) {
      print("ExerciseScreen: User not authenticated or _databaseService is null. Cannot delete exercise.");
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Delete Exercise', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to delete this exercise?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text('Cancel', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                print("ExerciseScreen: Attempting to delete exercise with docId: $docId");
                await _databaseService!.deleteExercise(docId);
                _showSuccess('Exercise deleted successfully');
                print("ExerciseScreen: Exercise deleted successfully.");
              } catch (error, stackTrace) {
                print("ExerciseScreen: Failed to delete exercise: $error\n$stackTrace");
                _showError('Failed to delete exercise: $error');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colorScheme.onSecondary)),
        backgroundColor: colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colorScheme.onError)),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetForm() {
    _exerciseNameController.clear();
    _durationController.clear();
    _frequencyController.clear();
    setState(() => _showForm = false);
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _durationController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }
}
