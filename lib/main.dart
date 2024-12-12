import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD App',
      home: CRUDPage(),
    );
  }
}

class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class CRUDPage extends StatefulWidget {
  @override
  _CRUDPageState createState() => _CRUDPageState();
}

class _CRUDPageState extends State<CRUDPage> {
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        posts = data.map((json) => Post.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> createPost(String title, String body) async {
    final response = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 201) {
      final newPost = Post.fromJson(json.decode(response.body));
      setState(() {
        posts.insert(0, newPost);
      });
    } else {
      throw Exception('Failed to create post');
    }
  }

  Future<void> updatePost(int id, String title, String body) async {
    final response = await http.put(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'),
      body: jsonEncode({'title': title, 'body': body}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        final postIndex = posts.indexWhere((post) => post.id == id);
        posts[postIndex] = Post.fromJson(json.decode(response.body));
      });
    } else {
      throw Exception('Failed to update post');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'));
    if (response.statusCode == 200) {
      setState(() {
        posts.removeWhere((post) => post.id == id);
      });
    } else {
      throw Exception('Failed to delete post');
    }
  }

  void showFormDialog({Post? post}) {
    final titleController = TextEditingController(text: post?.title);
    final bodyController = TextEditingController(text: post?.body);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(post == null ? 'Create Post' : 'Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: 'Body'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text;
                final body = bodyController.text;
                if (post == null) {
                  createPost(title, body);
                } else {
                  updatePost(post.id, title, body);
                }
                Navigator.pop(context);
              },
              child: Text(post == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter CRUD App')),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return ListTile(
            title: Text(post.title),
            subtitle: Text(post.body),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => showFormDialog(post: post),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deletePost(post.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showFormDialog(),
      ),
    );
  }
}