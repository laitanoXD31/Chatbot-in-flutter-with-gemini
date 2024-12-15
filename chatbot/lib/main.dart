import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vithalia Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];

  final apiKey = 'YOUR-API-KEY';

  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
      ),
      systemInstruction: Content.text(
        "Eres un profesional de la salud virtual. Responde de manera clara, "
        "amigable y basada en principios de salud, pero recuerda informar cada 8 mensajes "
        "al usuario que debe consultar a un médico para problemas específicos o serios."
        "Eres libre de usar emojis para expresarte de mejor manera con el usuario"
        "y te llamas Vithalia , el porque de tu nombre es que Representa vida y vitalidad, perfectos para un asistente de salud.",
      ),//contexto del bot
    );

    // Mensaje inicial del bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              "¡Hola! Soy Vithalia, tu asistente virtual. 😊 ¿En qué puedo ayudarte? (Recuerda que para temas de salud es mejor consultar a un profesional médico).",
          isUser: false,
        ));
      });
    });
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _sendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _textController.clear();
    });
    _scrollDown();

    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      setState(() {
        _messages.add(ChatMessage(
            text: "Parece que no tengo conexion a internet 😞 \n Accede a una red e intenta de nuevo, con gusto te ayudare ",
            isUser: false));
      });
      _scrollDown();
      return;
    }

    // Mostrar mensaje "Cargando..."
    setState(() {
      _messages.add(ChatMessage(text: "Pensando🤔...", isUser: false));
    });
    _scrollDown();

    try {
      final conversationHistory =
          _messages.map((message) => message.text).join('\n');
      final response =
          await model.generateContent([Content.text(conversationHistory)]);
      final botMessage = response.text;

      // Actualizar con la respuesta del bot
      setState(() {
        // Eliminar el mensaje "Cargando..."
        _messages.removeWhere((message) => message.text == "Pensando🤔...");
        
        if (botMessage != null) {
          _messages.add(ChatMessage(text: botMessage, isUser: false));
        } else {
          _messages.add(ChatMessage(
              text: "Error: Vaya...Parece que no tengo una respuesta.",
              isUser: false));
        }
      });
      _scrollDown();
    } catch (e) {
      setState(() {
        // Eliminar el mensaje "Cargando..." en caso de error
        _messages.removeWhere((message) => message.text == "Pensando🤔...");
        
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      });
      _scrollDown();
    }
  }

  void _startNewConversation() {
    setState(() {
      _messages.clear();
    });
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vithalia Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index].buildWidget();
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              reverse: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Widget buildWidget() {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? Colors.lightBlue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? Colors.black : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
