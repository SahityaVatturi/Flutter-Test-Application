import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Repository> repositories = [];

  @override
  void initState() {
    super.initState();
    _fetchRepositories();
  }

  Future<void> _fetchRepositories() async {
    final response = await http
        .get(Uri.parse('https://api.github.com/users/freeCodeCamp/repos'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        repositories = data.map((repo) => Repository.fromJson(repo)).toList();
      });
      _fetchLastCommits();
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  Future<void> _fetchLastCommits() async {
    for (var repository in repositories) {
      final commitResponse = await http.get(Uri.parse(
          'https://api.github.com/repos/freeCodeCamp/${repository.name}/commits')); // Use Uri.parse()
      if (commitResponse.statusCode == 200) {
        List<dynamic> commitsData = json.decode(commitResponse.body);
        if (commitsData.isNotEmpty) {
          repository.lastCommitMessage = commitsData.first['commit']['message'];
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: ListView.builder(
        itemCount: repositories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(repositories[index].name),
            subtitle:
                Text(repositories[index].lastCommitMessage ?? 'No commits yet'),
          );
        },
      ),
    );
  }
}

class Repository {
  final String name;
  String? lastCommitMessage;

  Repository({required this.name, this.lastCommitMessage});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'],
    );
  }
}
