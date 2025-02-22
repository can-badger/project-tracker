// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import 'project_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> projects = [];
  bool loading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }
  
  Future<void> _fetchProjects() async {
  // Eğer tüm projeler gösterilecekse, kullanıcı filtresi kaldırılıyor.
  try {
    final data = await Supabase.instance.client
        .from('projects')
        .select('*');  // .eq('user_id', userId) kısmı kaldırıldı.
    projects = (data as List)
        .map((item) => Project.fromMap(item as Map<String, dynamic>))
        .toList();
  } catch (error) {
    print("Error fetching projects: $error");
  }
  setState(() {
    loading = false;
  });
}

  
  Future<void> _addProject(String title, String description) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final userId = session.user.id;
    try {
      await Supabase.instance.client
          .from('projects')
          .insert({
            'title': title,
            'description': description,
            'user_id': userId,
          });
      _fetchProjects();
    } catch (error) {
      print("Error adding project: $error");
    }
  }
  
  Future<void> _deleteProject(int projectId) async {
    try {
      await Supabase.instance.client
          .from('projects')
          .delete()
          .eq('id', projectId);
      _fetchProjects();
    } catch (error) {
      print("Error deleting project: $error");
    }
  }
  
  Future<void> _updateProject(int projectId, {required String title, String? description}) async {
    try {
      await Supabase.instance.client
          .from('projects')
          .update({
            'title': title,
            'description': description,
          })
          .eq('id', projectId);
      _fetchProjects();
    } catch (error) {
      print("Error updating project: $error");
    }
  }
  
  void _showAddProjectDialog() {
    String title = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Proje Oluştur"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Proje Başlığı"),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Açıklama"),
                  onChanged: (value) => description = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  _addProject(title, description);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Proje Başlığı zorunludur.")),
                  );
                }
              },
              child: const Text("Oluştur"),
            ),
          ],
        );
      },
    );
  }
  
  void _showEditProjectDialog(Project project) {
    String newTitle = project.title;
    String newDescription = project.description ?? "";
    final titleController = TextEditingController(text: newTitle);
    final descriptionController = TextEditingController(text: newDescription);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Projeyi Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Proje Başlığı"),
                  onChanged: (value) => newTitle = value,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Açıklama"),
                  onChanged: (value) => newDescription = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTitle.isNotEmpty) {
                  _updateProject(project.id, title: newTitle, description: newDescription);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Proje Başlığı zorunludur.")),
                  );
                }
              },
              child: const Text("Güncelle"),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Projelerim"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(child: Text("Henüz proje oluşturulmadı."))
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          project.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(project.description ?? ""),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailPage(project: project),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditProjectDialog(project),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProject(project.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
