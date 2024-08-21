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
  String _selectedOption = 'Sales';
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
        Uri.parse('http://167.172.90.222:3201/chat'),
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

  Future<void> _clearThread() async {
    final response = await http.post(
      Uri.parse('http://167.172.90.222:3201/clear-thread'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'use_case': _selectedOption}),
    );

    String alertMessage = 'Failed to clear the thread';
    if (response.statusCode == 200) {
      setState(() {
        _messages.clear();
        alertMessage = 'Thread cleared successfully!';
      });
    } else {
      alertMessage = 'Error: ${response.statusCode}';
    }

    _showAlert(alertMessage);
  }

  void _showAlert(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents closing the alert by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Closes the alert dialog
              },
            ),
          ],
        );
      },
    );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        title: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            return isMobile
                ? SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Chk Chk Boom',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Credit: khanhphanphotography',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 1,
                      ),
                      Text(
                        'Chk Chk Boom',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Credit: khanhphanphotography',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.jpeg', // Your image asset
                  fit: BoxFit.cover,
                ),
              ),
              // Foreground content
              Center(
                child: SizedBox(
                  width: isMobile
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width * 0.75,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 75,
                      ),
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
                        child: Column(
                          children: <Widget>[
                            isMobile
                                ? Column(
                                    children: <Widget>[
                                      TextField(
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Type a message',
                                        ),
                                        onSubmitted: (value) {
                                          _sendMessage();
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: DropdownButton<String>(
                                              value: _selectedOption,
                                              items: <String>[
                                                'Sales',
                                                'Marketing',
                                                'General'
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
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _sendMessage,
                                            child: const Text('Send'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
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
                                          'Sales',
                                          'Marketing',
                                          'General'
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
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _clearThread,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red, // Background color
                              ),
                              child: const Text('Clear Thread', style: TextStyle(color: Colors.white),),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
