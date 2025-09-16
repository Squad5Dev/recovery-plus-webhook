import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recoveryplus/services/database_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hello! How can I assist you today?',
    },
  ];

  final String _backendUrl = '${dotenv.env['BACKEND_URL']}/gemini-webhook';
  DatabaseService? _databaseService;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseService();
  }

  void _initializeDatabaseService() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _databaseService = DatabaseService(uid: user.uid);
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final message = _controller.text;
    final formattedMessage = "Be precise and focus only on the question: $message";

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': message,
      });
    });

    _controller.clear();

    try {
      final request = http.Request('POST', Uri.parse(_backendUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'sessionId': '12345',
        'message': formattedMessage,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': '',
          });
        });
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          setState(() {
            _messages.last['text'] = _messages.last['text']! + chunk;
          });
        }
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Sorry, something went wrong.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error: Could not connect to the chatbot backend. Please make sure it is running.',
        });
      });
    }
  }

  Future<void> _pickImageAndProcessPrescription() async {
    print("ChatScreen: _pickImageAndProcessPrescription started.");
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print("ChatScreen: Image picking cancelled.");
      return;
    }

    print("ChatScreen: Image picked successfully: ${image.path}");
    setState(() {
      _messages.add({
        'sender': 'bot',
        'text': 'Processing prescription image...', 
      });
    });

    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final InputImage inputImage = InputImage.fromFilePath(image.path);
      print("ChatScreen: Starting text recognition...");
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;
      print("ChatScreen: Text recognized: $extractedText");

      if (extractedText.isEmpty) {
        print("ChatScreen: No text found in the image.");
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'No text found in the image. Please try again with a clearer image.',
          });
        });
        return;
      }

      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Text extracted. Sending to Gemini for structuring...', 
        });
      });

      final String backendUrl = dotenv.env['BACKEND_URL']!;
      print("ChatScreen: Calling Python backend at $backendUrl/process_prescription...");
      final response = await http.post(
        Uri.parse('$backendUrl/process_prescription'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prescription_text": extractedText}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> structuredData = jsonDecode(response.body);
        print("ChatScreen: Backend call successful. Structured Data: $structuredData");

        final List<dynamic> medicationsData = structuredData['medications'] ?? [];
        final List<dynamic> exercisesData = structuredData['exercises'] ?? [];

        for (var medData in medicationsData) {
          if (_databaseService != null) {
            await _databaseService!.addMedication(
              medData['name'] ?? '',
              medData['dosage'] ?? '',
              medData['frequency'] ?? '',
            );
            print("ChatScreen: Medication added to Firebase: ${medData['name']}");
          }
        }

        for (var exData in exercisesData) {
          if (_databaseService != null) {
            await _databaseService!.addExercise(
              exData['name'] ?? '',
              exData['duration'] ?? '',
              exData['frequency'] ?? '',
            );
            print("ChatScreen: Exercise added to Firebase: ${exData['name']}");
          }
        }

        String confirmationMessage = "I've extracted the following from your prescription:\n\n";
        if (medicationsData.isNotEmpty) {
          confirmationMessage += "Medications:\n";
          for (var med in medicationsData) {
            confirmationMessage += "- ${med['name']} (${med['dosage']}) - ${med['frequency']}\n";
          }
        }
        if (exercisesData.isNotEmpty) {
          confirmationMessage += "\nExercises:\n";
          for (var ex in exercisesData) {
            confirmationMessage += "- ${ex['name']} (${ex['duration']}) - ${ex['frequency']}\n";
          }
        }
        confirmationMessage += "\nIs this correct?";

        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': confirmationMessage,
          });
        });
        print("ChatScreen: Prescription processed successfully. Confirmation message sent.");

      } else {
        print("ChatScreen: Backend Error: Status Code ${response.statusCode}, Body: ${response.body}");
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Error processing prescription: ${response.statusCode} - ${response.body}',
          });
        });
      }

    } catch (e, stackTrace) {
      print("ChatScreen: Error processing prescription: $e\n$stackTrace");
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error processing prescription: $e',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: _pickImageAndProcessPrescription,
            tooltip: 'Scan Prescription',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF0F0FF), // Light lavender background
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            alignment: Alignment.centerLeft,
            child: Text(
              'RecoveryPal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    color: isUser ? colorScheme.primary : colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        message['text']!,
                        style: TextStyle(color: isUser ? colorScheme.onPrimary : colorScheme.onSurface),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.onSurface.withAlpha(51)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Type your message...', 
                      hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(128)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colorScheme.onSurface.withAlpha(51)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjusted vertical padding
                      // isDense: true, // Removed isDense
                      fillColor: colorScheme.surface,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjusted vertical padding
                  ),
                  onPressed: _sendMessage,
                  child: Icon(Icons.send, color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
