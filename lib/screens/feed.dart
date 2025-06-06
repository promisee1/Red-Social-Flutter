import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Publicaciones'),
        leading: IconButton(
          icon: Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar cierre de sesión'),
                  content: const Text(
                    '¿Estás seguro de que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/LoginPage');
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.person, color: Colors.white),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ),
          SizedBox(width: 8),
          Container(
            margin: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              tooltip: 'Crear Post',
              onPressed: () {
                Navigator.pushNamed(context, '/newpost');
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('posts')
                .orderBy('likesCount', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No hay publicaciones aún.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index];
              bool isLiked =
                  post['likes'] != null && post['likes'][userId] == true;
              int likesCount = post['likesCount'] ?? 0;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                shadowColor: Colors.purple.withOpacity(0.3),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(post['text'], style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      if (post['imageUrl'] != null &&
                          post['imageUrl'].toString().trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 200,
                              maxWidth: MediaQuery.of(context).size.width - 64,
                            ),
                            child: Image.network(
                              post['imageUrl'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey[500],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$likesCount', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () async {
                              final postRef = _firestore
                                  .collection('posts')
                                  .doc(post.id);
                              final snapshot = await postRef.get();
                              final currentLikes = Map<String, dynamic>.from(
                                snapshot['likes'] ?? {},
                              );
                              final isCurrentlyLiked =
                                  currentLikes[userId] == true;

                              if (isCurrentlyLiked) {
                                await postRef.update({
                                  'likes.$userId': FieldValue.delete(),
                                  'likesCount': FieldValue.increment(-1),
                                });
                              } else {
                                await postRef.update({
                                  'likes.$userId': true,
                                  'likesCount': FieldValue.increment(1),
                                });
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey<bool>(isLiked),
                                color: isLiked ? Colors.red : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
