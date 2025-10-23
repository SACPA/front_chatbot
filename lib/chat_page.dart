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
  Timer? _loadingTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // URL del entorno:
    api = ApiService(baseUrl: 'http://10.0.2.2:8000'); // Android Emulator
    // api = ApiService(baseUrl: 'http://localhost:8000'); // iOS/Web
    // api = ApiService(baseUrl: 'http://192.168.X.X:8000'); // Físico
    // Mensaje de bienvenida inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Bienvenido, desea ver el menú?'
        });
      });
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un mensaje antes de enviar')),
      );
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear(); // limpiar el TextField al enviar
      _isLoading = true;
      _loadingText = "";
    });


    _scrollToBottom();


    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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

          _scrollToBottom();
      }
    });


    final isHealthy = await api.health();
    if (!isHealthy) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': 'Opps, no puedo pensar en estos momentos :/'
        });
      });
      _loadingTimer?.cancel();
      _loadingTimer = null;
      _scrollToBottom();
      return;
    }

    try {
      final reply = await api.sendMessage(text);
      if (reply.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La respuesta del servidor está vacía')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': reply});
      });

      _scrollToBottom();
    } catch (e) {

      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content': 'Opps! Al parecer no estás conectado a internet 😅'
        });
      });

      _scrollToBottom();
    } finally {
      _loadingTimer?.cancel();
      _loadingTimer = null;
    }
  }

  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } catch (_) {

      }
    });
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
              controller: _scrollController,
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
                  onPressed: _isLoading ? null : _sendMessage,
                  tooltip: _isLoading ? 'Esperando respuesta...' : 'Enviar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
