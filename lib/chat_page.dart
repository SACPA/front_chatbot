import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late ApiService api;
  bool _isLoading = false;
  String _loadingText = "";

  @override
  void initState() {
    super.initState();
    // Cambia la URL según tu entorno:
    api = ApiService(baseUrl: 'http://10.0.2.2:8000'); // Android Emulator
    // api = ApiService(baseUrl: 'http://localhost:8000'); // iOS/Web
    // api = ApiService(baseUrl: 'http://192.168.X.X:8000'); // Dispositivo físico
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isLoading = true;
      _loadingText = "";
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isLoading) {
        timer.cancel();
      } else {
        setState(() {
          if (_loadingText.length >= 3) {
            _loadingText = "";
          } else {
            _loadingText += ".";
          }
        });
      }
    });

    try {
      final reply = await api.sendMessage(text);
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMessages = List<Map<String, String>>.from(_messages);
    if (_isLoading) {
      allMessages.add({'role': 'assistant', 'content': 'Escribiendo$_loadingText'});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot RAG'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allMessages.length,
              itemBuilder: (context, index) {
                final msg = allMessages[index];
                final isUser = msg['role'] == 'user';
                final isLoadingBubble =
                    msg['content']!.startsWith('Cargando');

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent
                          : isLoadingBubble
                              ? Colors.grey.shade200
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.black87,
                        fontStyle: isLoadingBubble ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Escribe un mensaje...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
