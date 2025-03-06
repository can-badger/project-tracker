import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyTagsPage extends StatefulWidget {
  const MyTagsPage({super.key});

  @override
  _MyTagsPageState createState() => _MyTagsPageState();
}

class _MyTagsPageState extends State<MyTagsPage> {
  List<String> myTags = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyTags();
  }

  Future<void> _loadMyTags() async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail == null) return;
    setState(() => isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('tasks')
          .select('*')
          .eq('assigned_to', userEmail);
      setState(() {
        myTags = (data as List)
            .map((item) => item['title'].toString())
            .toList();
      });
    } catch (e) {
      print("Error loading My Tags: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tags'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myTags.isEmpty
              ? const Center(child: Text('Henüz atanan task bulunamadı.'))
              : ListView.builder(
                  itemCount: myTags.length,
                  itemBuilder: (context, index) {
                    final tag = myTags[index];
                    return ListTile(
                      leading: const Icon(Icons.label),
                      title: Text(tag),
                    );
                  },
                ),
    );
  }
}
