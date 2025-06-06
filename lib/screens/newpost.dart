import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<bool> _urlEsValida(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createPost() async {
    final text = _textController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (text.isEmpty) {
      _mostrarSnackBar("El texto de la publicación no puede estar vacío");
      return;
    }

    String? urlValida;

    if (imageUrl.isNotEmpty && await _urlEsValida(imageUrl)) {
      urlValida = imageUrl;
    } else if (imageUrl.isNotEmpty) {
      _mostrarSnackBar(
        "La URL de la imagen no es válida, se publicará sin imagen",
      );
    }

    try {
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>?;

      final authorName = data?['nombre'] ?? 'Anónimo';

      await _firestore.collection('posts').add({
        'text': text,
        'author': authorName,
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'imageUrl': urlValida,
        'likes': {},
      });

      _mostrarSnackBar("Publicación creada exitosamente");
      Navigator.pop(context);
    } catch (e) {
      _mostrarSnackBar("Error al crear la publicación: $e");
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Publicación"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Texto de la publicación", style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "Escribe algo...",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Text("URL de imagen (opcional)", style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                hintText: "https://example.com/imagen.jpg",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Publicar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
