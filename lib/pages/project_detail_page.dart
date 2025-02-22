// lib/pages/project_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatı için gerekli
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/project.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  const ProjectDetailPage({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<Task> tasks = [];
  bool loading = true;

  // Gerçek kullanıcı verilerini çekmek için _fetchAvailableUsers() kullanılabilir.
  // Şimdilik örnek veriler:
  List<String> availableUsers = ['user1@example.com', 'user2@example.com', 'user3@example.com'];

  // "Sadece Bana Atanmış" filtresi
  bool filterAssignedOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchAvailableUsers();
  }

  Future<void> _fetchTasks() async {
    try {
      final data = await Supabase.instance.client
          .from('tasks')
          .select('*')
          .eq('project_id', widget.project.id);
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

  Future<void> _fetchAvailableUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('email');
      availableUsers = (data as List)
          .map((e) => (e as Map<String, dynamic>)['email'] as String)
          .toList();
    } catch (error) {
      print("Error fetching available users: $error");
    }
    setState(() {});
  }

  Future<void> _addTask({
    required String title,
    String? assignedTo,
    DateTime? deadline,
    String? priority,
    String? activeStatus,
    String? description,
  }) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .insert({
            'project_id': widget.project.id,
            'title': title,
            'assigned_to': assignedTo,
            'deadline': deadline?.toIso8601String(),
            'priority': priority,
            'active_status': activeStatus,
            'description': description,
            'is_completed': false,
          });
      _fetchTasks();
    } catch (error) {
      print("Error adding task: $error");
    }
  }

  Future<void> _updateTask(
    int taskId, {
    required String title,
    String? assignedTo,
    DateTime? deadline,
    String? priority,
    String? activeStatus,
    String? description,
    required bool isCompleted,
  }) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .update({
            'title': title,
            'assigned_to': assignedTo,
            'deadline': deadline?.toIso8601String(),
            'priority': priority,
            'active_status': activeStatus,
            'description': description,
            'is_completed': isCompleted,
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

  /// Açıklamayı maksimum 15 karakterle sınırlandıran yardımcı fonksiyon
  String _shortenDescription(String? description) {
    if (description == null || description.trim().isEmpty) return "-";
    return description.length > 15 ? description.substring(0, 15) + "..." : description;
  }

  /// "Kişi" sütununda, e-posta adresindeki "@" öncesini döndüren yardımcı fonksiyon
  String _displayAssignedTo(String? assignedTo) {
    if (assignedTo == null || assignedTo.trim().isEmpty) return "-";
    final addresses = assignedTo.split(",").map((e) => e.trim());
    final names = addresses.map((addr) {
      final splitted = addr.split("@");
      return splitted.first;
    }).join(", ");
    return names;
  }

  /// Görev Ekleme Diyaloğu
  void _showAddTaskDialog() {
    String title = "";
    List<String> selectedUsers = [];
    DateTime? deadline;
    String? priority;
    String? activeStatus;
    String description = "";

    final List<String> priorityOptions = ['Acil', 'Orta', 'Sakin'];
    final List<String> activeStatusOptions = ['Yapılıyor', 'Beklemede'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: SizedBox(
                width: 600,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(labelText: "Görev Başlığı *"),
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 16),
                      MultiSelectDialogField<String>(
                        items: availableUsers
                            .map((user) => MultiSelectItem<String>(user, user))
                            .toList(),
                        title: const Text("Kişiler"),
                        buttonText: const Text("Kişi Seçiniz"),
                        initialValue: selectedUsers,
                        onConfirm: (results) {
                          selectedUsers = results.cast<String>();
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deadline != null
                                  ? "Deadline: ${DateFormat('dd-MM-yyyy').format(deadline!)}"
                                  : "Deadline: Seçilmedi",
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
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                              );
                              setStateDialog(() {
                                deadline = pickedDate;
                              });
                                                        },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Öncelik Durumu",
                          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        value: priority,
                        hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                        items: priorityOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Taskın Aktif Durumu",
                          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        value: activeStatus,
                        hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                        items: activeStatusOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            activeStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Açıklama",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) => description = value,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
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
                      String? assignedTo = selectedUsers.isNotEmpty ? selectedUsers.join(", ") : null;
                      _addTask(
                        title: title,
                        assignedTo: assignedTo,
                        deadline: deadline,
                        priority: priority,
                        activeStatus: activeStatus,
                        description: description.isNotEmpty ? description : null,
                      );
                      Navigator.pop(context);
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
          },
        );
      },
    );
  }

  /// Görev Düzenleme Diyaloğu
  void _showEditTaskDialog(Task task) {
    String title = task.title;
    List<String> selectedUsers = task.assignedTo != null && task.assignedTo!.isNotEmpty
        ? task.assignedTo!.split(",").map((e) => e.trim()).toList()
        : [];
    DateTime? deadline = task.deadline;
    String? priority = task.priority;
    String? activeStatus = task.activeStatus;
    String description = task.description ?? "";
    bool isCompleted = task.isCompleted;

    final List<String> priorityOptions = ['Acil', 'Orta', 'Sakin'];
    final List<String> activeStatusOptions = ['Yapılıyor', 'Beklemede'];

    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(text: description);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: SizedBox(
                width: 600,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Görev Başlığı *"),
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 16),
                      MultiSelectDialogField<String>(
                        items: availableUsers
                            .map((user) => MultiSelectItem<String>(user, user))
                            .toList(),
                        title: const Text("Kişiler"),
                        buttonText: const Text("Kişi Seçiniz"),
                        initialValue: selectedUsers,
                        onConfirm: (results) {
                          selectedUsers = results.cast<String>();
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deadline != null
                                  ? "Deadline: ${DateFormat('dd-MM-yyyy').format(deadline!)}"
                                  : "Deadline: Seçilmedi",
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
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                              );
                              setStateDialog(() {
                                deadline = pickedDate;
                              });
                                                        },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Öncelik Durumu",
                          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        value: priority,
                        hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                        items: priorityOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Taskın Aktif Durumu",
                          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        value: activeStatus,
                        hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                        items: activeStatusOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            activeStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: "Açıklama",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) => description = value,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isCompleted,
                            onChanged: (value) {
                              setStateDialog(() {
                                isCompleted = value ?? false;
                              });
                            },
                          ),
                          const Text("Tamamlandı"),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
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
                      String? assignedTo = selectedUsers.isNotEmpty ? selectedUsers.join(", ") : null;
                      _updateTask(
                        task.id,
                        title: title,
                        assignedTo: assignedTo,
                        deadline: deadline,
                        priority: priority,
                        activeStatus: activeStatus,
                        description: description.isNotEmpty ? description : null,
                        isCompleted: isCompleted,
                      );
                      Navigator.pop(context);
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail =
        Supabase.instance.client.auth.currentSession?.user.email?.toLowerCase() ?? "";

    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    final filteredActiveTasks = filterAssignedOnly
        ? activeTasks
            .where((t) => t.assignedTo?.toLowerCase().contains(currentUserEmail) == true)
            .toList()
        : activeTasks;
    final filteredCompletedTasks = filterAssignedOnly
        ? completedTasks
            .where((t) => t.assignedTo?.toLowerCase().contains(currentUserEmail) == true)
            .toList()
        : completedTasks;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Proje: ${widget.project.title}"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Aktif Görevler (${filteredActiveTasks.length})"),
              const Tab(text: "Tamamlanan Görevler"),
            ],
          ),
        ),
        body: Column(
          children: [
            // "Sadece Bana Atanmış" checkbox'ı, sol tarafa hizalı ve sadece içeriğin genişliğini kaplar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: filterAssignedOnly,
                          onChanged: (value) {
                            setState(() {
                              filterAssignedOnly = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text("Sadece Bana Atanmış"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Aktif Görevler sekmesi
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredActiveTasks.isEmpty
                          ? const Center(child: Text("Henüz aktif görev eklenmedi."))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
                                  columns: const [
                                    DataColumn(label: Text("Tamamlandı")),
                                    DataColumn(label: Text("Görev Başlığı")),
                                    DataColumn(label: Text("Kişi")),
                                    DataColumn(label: Text("Bitiş Tarihi")),
                                    DataColumn(label: Text("Öncelik")),
                                    DataColumn(label: Text("Durum")),
                                    DataColumn(label: Text("Açıklama")),
                                    DataColumn(label: Text("Sil")),
                                  ],
                                  rows: filteredActiveTasks.map((task) {
                                    final textStyle = const TextStyle(color: Colors.black);
                                    final assignedToDisplay = _displayAssignedTo(task.assignedTo);
                                    final shortDescription = _shortenDescription(task.description);
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            value: task.isCompleted,
                                            onChanged: (value) {
                                              _updateTask(
                                                task.id,
                                                title: task.title,
                                                assignedTo: task.assignedTo,
                                                deadline: task.deadline,
                                                priority: task.priority,
                                                activeStatus: task.activeStatus,
                                                description: task.description,
                                                isCompleted: value ?? false,
                                              );
                                            },
                                          ),
                                        ),
                                        DataCell(Text(task.title, style: textStyle)),
                                        DataCell(Text(assignedToDisplay, style: textStyle)),
                                        DataCell(Text(
                                          task.deadline != null
                                              ? DateFormat('dd-MM-yyyy').format(task.deadline!)
                                              : "-",
                                          style: textStyle,
                                        )),
                                        DataCell(Text(task.priority ?? "-", style: textStyle)),
                                        DataCell(Text(task.activeStatus ?? "-", style: textStyle)),
                                        DataCell(Text(shortDescription, style: textStyle)),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteTask(task.id),
                                          ),
                                        ),
                                      ],
                                      onSelectChanged: (_) => _showEditTaskDialog(task),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                  // Tamamlanan Görevler sekmesi
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredCompletedTasks.isEmpty
                          ? const Center(child: Text("Henüz tamamlanan görev eklenmedi."))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
                                  dataRowColor: MaterialStateProperty.all(Colors.grey[850]),
                                  columns: const [
                                    DataColumn(label: Text("Tamamlandı", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Görev Başlığı", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Kişi", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Bitiş Tarihi", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Öncelik", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Durum", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Açıklama", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Sil", style: TextStyle(color: Colors.white))),
                                  ],
                                  rows: filteredCompletedTasks.map((task) {
                                    final textStyle = const TextStyle(color: Colors.white);
                                    final assignedToDisplay = _displayAssignedTo(task.assignedTo);
                                    final shortDescription = _shortenDescription(task.description);
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            value: task.isCompleted,
                                            onChanged: (value) {
                                              _updateTask(
                                                task.id,
                                                title: task.title,
                                                assignedTo: task.assignedTo,
                                                deadline: task.deadline,
                                                priority: task.priority,
                                                activeStatus: task.activeStatus,
                                                description: task.description,
                                                isCompleted: value ?? false,
                                              );
                                            },
                                          ),
                                        ),
                                        DataCell(Text(task.title, style: textStyle)),
                                        DataCell(Text(assignedToDisplay, style: textStyle)),
                                        DataCell(Text(
                                          task.deadline != null
                                              ? DateFormat('dd-MM-yyyy').format(task.deadline!)
                                              : "-",
                                          style: textStyle,
                                        )),
                                        DataCell(Text(task.priority ?? "-", style: textStyle)),
                                        DataCell(Text(task.activeStatus ?? "-", style: textStyle)),
                                        DataCell(Text(shortDescription, style: textStyle)),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.white),
                                            onPressed: () => _deleteTask(task.id),
                                          ),
                                        ),
                                      ],
                                      onSelectChanged: (_) => _showEditTaskDialog(task),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
