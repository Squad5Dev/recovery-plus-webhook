import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plus'),
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
