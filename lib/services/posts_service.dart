import 'package:supabase_flutter/supabase_flutter.dart';

class PostModel {
  final String id;
  final String userId;
  final String authorEmail;
  final String authorName;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.authorEmail,
    required this.authorName,
    required this.content,
    required this.likesCount,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final email = (json['author_email'] as String?) ?? 'User';
    final name = email.contains('@') ? email.split('@')[0] : email;

    return PostModel(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      authorEmail: email,
      authorName: name,
      content: (json['content'] as String?) ?? '',
      likesCount: (json['likes_count'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class PostsService {
  PostsService._();
  static final PostsService instance = PostsService._();

  final _client = Supabase.instance.client;

  /// Fetch all posts sorted by newest first.
  Future<List<PostModel>> fetchPosts() async {
    try {
      final response = await _client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Create a new post in Supabase database.
  Future<bool> createPost(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('posts').insert({
        'user_id': user.id,
        'author_email': user.email ?? 'User',
        'content': content,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
