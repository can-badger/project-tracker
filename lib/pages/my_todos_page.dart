import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo.dart';

class MyTodosPage extends StatefulWidget {
  const MyTodosPage({super.key});

  @override
  _MyTodosPageState createState() => _MyTodosPageState();
}

class _MyTodosPageState extends State<MyTodosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<Todo>>? _todosFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? newEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _todosFuture = _loadTodos();
  }

  Future<List<Todo>> _loadTodos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('todos')
        .select('*')
        .eq('user_id', userId);
    // Map the fetched data to Todo objects.
    return (data as List).map((item) => Todo.fromMap(item)).toList();
  }

  // Dialog: Yeni Todo ekleme
  void _showAddNewTodoDialog() {
    _titleController.clear();
    _descriptionController.clear();
    newEndDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Yeni Todo Ekle"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Görev Başlığı *"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          newEndDate != null
                              ? "End Date: ${DateFormat('dd-MM-yyyy').format(newEndDate!)}"
                              : "End Date: Seçilmedi",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              newEndDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  final description = _descriptionController.text.trim();
                  if (title.isNotEmpty) {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null) {
                      await Supabase.instance.client.from('todos').insert({
                        'user_id': userId,
                        'title': title,
                        'description': description,
                        'end_date': newEndDate?.toIso8601String(),
                        'is_completed': false,
                      });
                      Navigator.pop(context);
                      setState(() {
                        _todosFuture = _loadTodos();
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Görev Başlığı zorunludur.")),
                    );
                  }
                },
                child: const Text("Ekle"),
              ),
            ],
          );
        });
      },
    );
  }

  // DataTable oluşturma: Sütunlar: Tamamlandı, Başlık, End Date, Açıklama
  Widget _buildDataTable(List<Todo> todos) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text("Tamamlandı")),
            DataColumn(label: Text("Başlık")),
            DataColumn(label: Text("End Date")),
            DataColumn(label: Text("Açıklama")),
          ],
          rows: todos.map((todo) {
            final textStyle = todo.isCompleted
                ? const TextStyle(color: Colors.grey)
                : const TextStyle(color: Colors.black);
            final endDateStr = todo.endDate != null
                ? DateFormat('dd-MM-yyyy').format(todo.endDate!)
                : "-";
            final desc = (todo.description != null && todo.description!.length > 15)
                ? "${todo.description!.substring(0, 15)}..."
                : (todo.description ?? "-");
            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: todo.isCompleted,
                    onChanged: (value) async {
                      try {
                        await Supabase.instance.client.from('todos').update({
                          'is_completed': value,
                        }).eq('id', todo.id);
                        setState(() {
                          _todosFuture = _loadTodos();
                        });
                      } catch (e) {
                        print("Error updating is_completed: $e");
                      }
                    },
                  ),
                ),
                DataCell(Text(todo.title, style: textStyle)),
                DataCell(Text(endDateStr, style: textStyle)),
                DataCell(Text(desc, style: textStyle)),
              ],
              onSelectChanged: (_) {
                _showEditTodoDialog(todo);
              },
            );
          }).toList(),
        ),
      );
    });
  }

  // Görev düzenleme diyaloğu
  void _showEditTodoDialog(Todo todo) {
    final TextEditingController editTitleController = TextEditingController(text: todo.title);
    final TextEditingController editDescriptionController = TextEditingController(text: todo.description);
    DateTime? editEndDate = todo.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Görevi Düzenle"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editTitleController,
                    decoration: const InputDecoration(labelText: "Görev Başlığı *"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editDescriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editEndDate != null
                              ? "End Date: ${DateFormat('dd-MM-yyyy').format(editEndDate!)}"
                              : "End Date: Seçilmedi",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              editEndDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedTitle = editTitleController.text.trim();
                  final updatedDescription = editDescriptionController.text.trim();
                  if (updatedTitle.isNotEmpty) {
                    try {
                      await Supabase.instance.client.from('todos').update({
                        'title': updatedTitle,
                        'description': updatedDescription,
                        'end_date': editEndDate?.toIso8601String(),
                      }).eq('id', todo.id);
                      Navigator.pop(context);
                      setState(() {
                        _todosFuture = _loadTodos();
                      });
                    } catch (e) {
                      print("Error updating todo: $e");
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Görev Başlığı zorunludur.")),
                    );
                  }
                },
                child: const Text("Güncelle"),
              ),
            ],
          );
        });
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My ToDo's"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Aktif Görevler"),
            Tab(text: "Tamamlanan Görevler"),
          ],
        ),
      ),
      body: FutureBuilder<List<Todo>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz görev eklenmedi."));
          } else {
            final todosData = snapshot.data!;
            final activeTodos = todosData.where((t) => !t.isCompleted).toList();
            final completedTodos = todosData.where((t) => t.isCompleted).toList();
            return TabBarView(
              controller: _tabController,
              children: [
                activeTodos.isEmpty
                    ? const Center(child: Text("Aktif görev bulunamadı."))
                    : SingleChildScrollView(child: _buildDataTable(activeTodos)),
                completedTodos.isEmpty
                    ? const Center(child: Text("Tamamlanan görev bulunamadı."))
                    : SingleChildScrollView(child: _buildDataTable(completedTodos)),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _showAddNewTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
