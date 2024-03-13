import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('GitHub Repositories'),
        ),
        body: GitHubRepoList(),
      ),
    );
  }
}

class GitHubRepoList extends StatefulWidget {
  @override
  _GitHubRepoListState createState() => _GitHubRepoListState();
}

class _GitHubRepoListState extends State<GitHubRepoList> {
  final String user = 'freeCodeCamp';
  final String apiUrl = 'https://api.github.com/users/freeCodeCamp/repos';
  late Future<List<Map<String, dynamic>>> repos;

  @override
  void initState() {
    super.initState();
    repos = fetchRepositories();
  }

  Future<List<Map<String, dynamic>>> fetchRepositories() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> reposData = json.decode(response.body);

      // Fetch last commit information for each repository
      final List<Map<String, dynamic>> repositories = [];
      for (var repo in reposData) {
        final lastCommit = await fetchLastCommit(repo['name']);
        repositories.add({
          'repo': repo,
          'lastCommit': lastCommit,
        });
      }

      return repositories;
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  Future<Map<String, dynamic>> fetchLastCommit(String repoName) async {
    final commitUrl = 'https://api.github.com/repos/$user/$repoName/commits';
    final response = await http.get(Uri.parse(commitUrl));

    if (response.statusCode == 200) {
      final List<dynamic> commits = json.decode(response.body);

      if (commits.isNotEmpty) {
        // Return the last commit information if available
        return commits[0];
      } else {
        // Return an empty map if there are no commits
        return {};
      }
    } else {
      print('Failed to load last commit for $repoName');
      // Return an empty map or handle the error accordingly
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<Map<String, dynamic>> repositories =
              snapshot.data as List<Map<String, dynamic>>;

          return ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repoData = repositories[index];
              final repo = repoData['repo'];
              final lastCommit = repoData['lastCommit'];

              return ListTile(
                title: Text(repo['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo['description'] ?? 'No description available'),
                    if (lastCommit.isNotEmpty)
                      Text('Last Commit: ${lastCommit['commit']['message']}'),
                  ],
                ),
                // You can customize the list tile further based on your needs
              );
            },
          );
        }
      },
    );
  }
}
