import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
import '../services/project_service.dart';
import 'project_detail_page.dart';
import 'my_todos_page.dart';
import 'my_tags_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Future değişkenleri (Projeler ve Tags için FutureBuilder kullanıyoruz)
  Future<List<Project>>? _projectsFuture;
  Future<List<dynamic>>? _tagsFuture;
  
  // Projelerin local kopyası
  List<Project> projects = [];
  
  // My ToDo’s için yerel liste ve AnimatedList key
  List<dynamic> _todos = [];
  bool isLoadingTodos = true;
  GlobalKey<AnimatedListState> _todosListKey = GlobalKey<AnimatedListState>();

  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _todoTitleController = TextEditingController();

  // Eksik olan controller'ları tanımlıyoruz:
  final TextEditingController _todoEditTitleController = TextEditingController();
  final TextEditingController _todoDescriptionController = TextEditingController();
  final TextEditingController _todoEndDateController = TextEditingController();

  int? _highlightedTagIndex;

  @override
  void initState() {
    super.initState();
    _refreshProjects();
    _loadTodos();
    _refreshTags();
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _todoTitleController.dispose();
    _todoEditTitleController.dispose();
    _todoDescriptionController.dispose();
    _todoEndDateController.dispose();
    super.dispose();
  }

  Future<void> _refreshProjects() async {
    try {
      final fetchedProjects = await ProjectService().fetchProjects();
      if (!mounted) return;
      setState(() {
        projects = fetchedProjects.reversed.toList();
        _projectsFuture = Future.value(projects);
      });
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    }
  }

  Future<void> _loadTodos() async {
    setState(() {
      isLoadingTodos = true;
    });
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _todos = [];
        isLoadingTodos = false;
      });
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('todos')
          .select('*')
          .eq('user_id', userId)
          .or('is_completed.is.null,is_completed.eq.false')
          .order('created_at', ascending: false);
      final newTodos = (data as List).reversed.toList();
      if (!mounted) return;
      setState(() {
        _todos = newTodos;
        isLoadingTodos = false;
        // Yeniden inşa için yeni bir key atıyoruz:
        _todosListKey = GlobalKey<AnimatedListState>();
      });
    } catch (e) {
      debugPrint("Error loading todos: $e");
      setState(() {
        isLoadingTodos = false;
      });
    }
  }

  Future<void> _refreshTags() async {
    setState(() {
      _tagsFuture = getTagsFuture();
    });
  }

  Future<List<dynamic>> getTagsFuture() async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail == null) return [];
    final data = await Supabase.instance.client
        .from('tasks')
        .select('*')
        .ilike('assigned_to', '%$userEmail%')
        .or('is_completed.is.null,is_completed.eq.false')
        .order('created_at', ascending: false);
    return (data as List).reversed.toList();
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proje Ekle'),
          content: TextField(
            controller: _projectTitleController,
            decoration: const InputDecoration(labelText: 'Proje Başlığı'),
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
                  try {
                    await ProjectService().addProject(title);
                    if (!mounted) return;
                    _projectTitleController.clear();
                    Navigator.pop(context);
                    _refreshProjects();
                  } catch (e) {
                    debugPrint("Error adding project: $e");
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

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Todo Ekle'),
          content: TextField(
            controller: _todoTitleController,
            decoration: const InputDecoration(labelText: 'Todo Başlığı'),
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
                    try {
                      await Supabase.instance.client
                          .from('todos')
                          .insert({'user_id': userId, 'title': title});
                      if (!mounted) return;
                      _todoTitleController.clear();
                      Navigator.pop(context);
                      _loadTodos();
                    } catch (e) {
                      debugPrint("Error adding todo: $e");
                    }
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
    try {
      await ProjectService().deleteProject(projectId);
      if (!mounted) return;
      _refreshProjects();
    } catch (e) {
      debugPrint("Error deleting project: $e");
    }
  }

  Future<void> _toggleTodoCompletion(int todoId, bool newValue) async {
    try {
      await Supabase.instance.client
          .from('todos')
          .update({'is_completed': newValue})
          .eq('id', todoId);
      if (!mounted) return;
      _loadTodos();
    } catch (e) {
      debugPrint("Error updating todo completion: $e");
    }
  }

  void _showEditTodoDialog(Map<String, dynamic> todo) {
    _todoEditTitleController.text = todo['title'] ?? '';
    _todoDescriptionController.text = todo['description'] ?? '';
    _todoEndDateController.text = todo['end_date'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Görevi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoEditTitleController,
                decoration: const InputDecoration(labelText: 'Görev İsmi'),
              ),
              TextField(
                controller: _todoDescriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
              TextField(
                controller: _todoEndDateController,
                decoration: const InputDecoration(labelText: 'Bitiş Tarihi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _todoEditTitleController.clear();
                _todoDescriptionController.clear();
                _todoEndDateController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = _todoEditTitleController.text.trim();
                final description = _todoDescriptionController.text.trim();
                final endDate = _todoEndDateController.text.trim();
                if (!mounted) return;
                try {
                  await Supabase.instance.client
                      .from('todos')
                      .update({
                        'title': newTitle,
                        'description': description,
                        'end_date': endDate,
                      })
                      .eq('id', todo['id']);
                  Navigator.pop(context);
                  _loadTodos();
                } catch (e) {
                  debugPrint("Error updating todo: $e");
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  // AnimatedList for My ToDo's
  Widget _buildAnimatedTodos() {
    return AnimatedList(
      key: _todosListKey,
      initialItemCount: _todos.length,
      itemBuilder: (context, index, animation) {
        final todo = _todos[index] as Map<String, dynamic>;
        return SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            leading: Checkbox(
              value: todo['is_completed'] ?? false,
              onChanged: (bool? newValue) {
                if (newValue == null) return;
                _toggleTodoCompletion(todo['id'], newValue);
              },
            ),
            title: Text(todo['title'] ?? ''),
            subtitle: Text(
              (todo['end_date'] != null && todo['end_date'].toString().isNotEmpty)
                  ? todo['end_date'].toString()
                  : "-",
            ),
            onTap: () {
              _showEditTodoDialog(todo);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // My ToDo's widget: Eğer hala yükleniyorsa CircularProgressIndicator, değilse AnimatedList
    Widget todosWidget;
    if (isLoadingTodos) {
      todosWidget = const Center(child: CircularProgressIndicator());
    } else {
      todosWidget = _buildAnimatedTodos();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sol sütun: Proje Listesi
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: FutureBuilder<List<Project>>(
                      future: _projectsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Henüz proje eklenmedi.'));
                        } else {
                          final projectsData = snapshot.data!;
                          return ListView.builder(
                            itemCount: projectsData.length,
                            itemBuilder: (context, index) {
                              final project = projectsData[index];
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
                                        builder: (context) => ProjectDetailPage(
                                          project: project,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sağ sütun: My ToDo's ve My Tags
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey.shade50,
              child: Column(
                children: [
                  // My ToDo's (AnimatedList)
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
                                ).then((_) {
                                  _loadTodos();
                                });
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
                          Expanded(child: todosWidget),
                        ],
                      ),
                    ),
                  ),
                  // My Tags (FutureBuilder)
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
                                ).then((_) {
                                  _refreshTags();
                                });
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
                            child: FutureBuilder<List<dynamic>>(
                              future: _tagsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Text('Henüz atanan task bulunamadı.'));
                                } else {
                                  final tagsData = snapshot.data!;
                                  return ListView.builder(
                                    itemCount: tagsData.length,
                                    itemBuilder: (context, index) {
                                      final tag = tagsData[index] as Map<String, dynamic>;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _highlightedTagIndex = index;
                                          });
                                          Future.delayed(const Duration(milliseconds: 300), () {
                                            setState(() {
                                              _highlightedTagIndex = null;
                                            });
                                            Project? project;
                                            try {
                                              project = projects.firstWhere((p) => p.id == tag['project_id']);
                                            } catch (e) {
                                              project = null;
                                            }
                                            if (project != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProjectDetailPage(
                                                    project: project!,
                                                    highlight: true,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Proje bulunamadı')),
                                              );
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          color: _highlightedTagIndex == index
                                              ? Colors.yellow.withAlpha(128)
                                              : Colors.transparent,
                                          child: ListTile(
                                            leading: const Icon(Icons.label),
                                            title: Text(tag['title'] ?? ''),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
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
