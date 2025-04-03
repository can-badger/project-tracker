import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyTagsPage extends StatefulWidget {
  const MyTagsPage({super.key});

  @override
  _MyTagsPageState createState() => _MyTagsPageState();
}

class _MyTagsPageState extends State<MyTagsPage> {
  Future<List<String>>? _tagsFuture;

  @override
  void initState() {
    super.initState();
    _tagsFuture = _loadMyTags();
  }

  Future<List<String>> _loadMyTags() async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail == null) return [];
    final data = await Supabase.instance.client
        .from('tasks')
        .select('*')
        .eq('assigned_to', userEmail);
    final tags = (data as List)
        .map((item) => item['title'].toString())
        .toList();
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tags'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        future: _tagsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz atanan task bulunamadı.'));
          } else {
            final tags = snapshot.data!;
            return ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  leading: const Icon(Icons.label),
                  title: Text(tag),
                );
              },
            );
          }
        },
      ),
    );
  }
}
