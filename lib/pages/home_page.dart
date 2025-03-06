import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import 'project_detail/project_detail_page.dart';
import 'my_todos_page.dart';
import 'my_tags_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> projects = [];
  bool isLoadingProjects = true;

  // Veriler, burada HomePage'de de çekiliyor ama MyTodosPage/MyTagsPage'de ayrı kullanılıyor.
  List<String> myTodos = [];
  List<String> myTags = [];
  bool isLoadingTodos = true;
  bool isLoadingTags = true;

  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _todoTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadMyTodos();
    _loadMyTags();
  }

  Future<void> _loadProjects() async {
    setState(() => isLoadingProjects = true);
    try {
      projects = await ProjectService().fetchProjects();
    } catch (error) {
      print("Error fetching projects: $error");
    }
    setState(() => isLoadingProjects = false);
  }

  Future<void> _loadMyTodos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => isLoadingTodos = true);
    try {
      final data = await Supabase.instance.client
          .from('todos')
          .select('*')
          .eq('user_id', userId);
      setState(() {
        myTodos = (data as List)
            .map((item) => item['title'].toString())
            .toList();
      });
    } catch (e) {
      print("Error loading My ToDo's: $e");
    }
    setState(() => isLoadingTodos = false);
  }

  Future<void> _loadMyTags() async {
  final userEmail = Supabase.instance.client.auth.currentUser?.email;
  if (userEmail == null) return;
  setState(() => isLoadingTags = true);
  try {
    final data = await Supabase.instance.client
        .from('tasks')
        .select('*')
        .ilike('assigned_to', '%$userEmail%'); // eq yerine ilike kullanıyoruz.
    setState(() {
      myTags = (data as List)
          .map((item) => item['title'].toString())
          .toList();
    });
  } catch (e) {
    print("Error loading My Tags: $e");
  }
  setState(() => isLoadingTags = false);
}


  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Proje Ekle'),
          content: TextField(
            controller: _projectTitleController,
            decoration: const InputDecoration(
              labelText: 'Proje Başlığı',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _projectTitleController.clear();
                Navigator.pop(context);
              },
              child: const Text('Kapat'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = _projectTitleController.text.trim();
                if (title.isNotEmpty) {
                  await ProjectService().addProject(title);
                  _projectTitleController.clear();
                  Navigator.pop(context);
                  _loadProjects();
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // _showAddTodoDialog artık user_email yerine user_id kullanıyor
  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Todo Ekle'),
          content: TextField(
            controller: _todoTitleController,
            decoration: const InputDecoration(
              labelText: 'Todo Başlığı',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _todoTitleController.clear();
                Navigator.pop(context);
              },
              child: const Text('Kapat'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = _todoTitleController.text.trim();
                if (title.isNotEmpty) {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    await Supabase.instance.client
                        .from('todos')
                        .insert({'user_id': userId, 'title': title});
                    _todoTitleController.clear();
                    Navigator.pop(context);
                    _loadMyTodos();
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject(int projectId) async {
    await ProjectService().deleteProject(projectId);
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: true,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SOL SÜTUN: Proje Listesi
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  // Çerçeveli "Projelerim" başlığı ve proje ekleme butonu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Marka Dosyaları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _showAddProjectDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: isLoadingProjects
                        ? const Center(child: CircularProgressIndicator())
                        : projects.isEmpty
                            ? const Center(child: Text('Henüz proje eklenmedi.'))
                            : ListView.builder(
                                itemCount: projects.length,
                                itemBuilder: (context, index) {
                                  final project = projects[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        project.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteProject(project.id),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProjectDetailPage(project: project),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // SAĞ SÜTUN: İki bölüm - Üst: My ToDo's, Alt: My Tags
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey.shade50,
              child: Column(
                children: [
                  // Üst bölüm: My ToDo's başlığı (çerçeveli, tıklanabilir)
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.blue.shade50,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyTodosPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'My ToDo\'s',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _showAddTodoDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: isLoadingTodos
                                ? const Center(child: CircularProgressIndicator())
                                : myTodos.isEmpty
                                    ? const Center(child: Text('Henüz kişisel todo eklenmedi.'))
                                    : ListView.builder(
                                        itemCount: myTodos.length,
                                        itemBuilder: (context, index) {
                                          final todo = myTodos[index];
                                          return ListTile(
                                            leading: const Icon(Icons.check_box_outline_blank),
                                            title: Text(todo),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Alt bölüm: My Tags başlığı (çerçeveli, tıklanabilir)
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.green.shade50,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyTagsPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'My Tags',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: isLoadingTags
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
