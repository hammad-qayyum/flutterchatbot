import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String _selectedOption = 'demand forecast';
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add({'message': _controller.text, 'type': 'user'});
        _isLoading = true;
      });

      final query = _controller.text;
      final useCase = _selectedOption;

      _controller.clear(); // Clear the text field

      // Scroll to the bottom after sending a message
      _scrollToBottom();

      final response = await http.post(
        Uri.parse('http://98.80.78.119:3202/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'use_case': useCase}),
      );

      String botResponse = 'Failed to get a response';
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        botResponse = jsonResponse['response'] ?? 'No response text found';
      } else {
        botResponse = 'Error: ${response.statusCode}';
      }

      setState(() {
        _messages.add({'message': botResponse, 'type': 'bot'});
        _isLoading = false;
        // Scroll to the end of the chat
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Bot is typing...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    final message = _messages[index];
                    return Align(
                      alignment: message['type'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: message['type'] == 'user'
                              ? Colors.blueGrey
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['message']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                        ),
                        onSubmitted: (value) {
                          _sendMessage();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedOption,
                      items: <String>[
                        'demand forecast',
                        'sales analysis',
                        'marketing campaign analysis'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedOption = newValue!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sendMessage,
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
