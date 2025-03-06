// lib/pages/tasks_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final userId = session.user.id;
    try {
      final data = await Supabase.instance.client
          .from('tasks')
          .select('*')
          .eq('user_id', userId);
      // data is expected to be a List<dynamic>
      tasks = (data as List)
          .map((item) => Task.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print("Error fetching tasks: $error");
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _addTask(String title, String description) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final userId = session.user.id;
    try {
      await Supabase.instance.client
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'user_id': userId,
            'status': 'pending'
          });
      _fetchTasks();
    } catch (error) {
      print("Error adding task: $error");
    }
  }

  Future<void> _updateTask(int taskId, String title, String description, String status) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .update({
            'title': title,
            'description': description,
            'status': status,
          })
          .eq('id', taskId);
      _fetchTasks();
    } catch (error) {
      print("Error updating task: $error");
    }
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .delete()
          .eq('id', taskId);
      _fetchTasks();
    } catch (error) {
      print("Error deleting task: $error");
    }
  }

  void _showAddTaskDialog() {
    String title = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Görev Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Başlık"),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Açıklama"),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask(title, description);
                Navigator.pop(context);
              },
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(Task task) {
    String title = task.title;
    String description = task.description ?? "";
    String? status = task.activeStatus;
    // Kullanıcıya önceden doldurulmuş alanları göstermek için
    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(text: description);
    final statusController = TextEditingController(text: status);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Görev Düzenle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Başlık"),
                onChanged: (value) => title = value,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Açıklama"),
                onChanged: (value) => description = value,
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: "Durum"),
                onChanged: (value) => status = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateTask(task.id, title, description, status!);
                Navigator.pop(context);
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
        title: const Text("Görevlerim"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text("Henüz görev eklenmedi."))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.description ?? ""),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTaskDialog(task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTask(task.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
