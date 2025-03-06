import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/project.dart';
import '../../models/task.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with TickerProviderStateMixin {
  // Sabit departman listesi
  final List<String> departments = [
    'DEV',
    'ART',
    'Dijital Pazarlama',
    'Grafik Tasarım',
    'Kurumsal'
  ];

  // Her departman için görev listelerini saklayan haritalar
  Map<String, List<Task>> activeTasks = {};
  Map<String, List<Task>> completedTasks = {};
  Map<String, bool> isLoadingTasks = {};

  // Örnek Badger House renk skalası
  final Color badgerPrimary = const Color.fromARGB(255, 199, 199, 199);
  final Color badgerAccent = const Color.fromARGB(55, 84, 50, 146);
  final Color badgerLight = const Color.fromARGB(30, 84, 50, 146);

  @override
  void initState() {
    super.initState();
    for (var dept in departments) {
      activeTasks[dept] = [];
      completedTasks[dept] = [];
      isLoadingTasks[dept] = true;
      _loadTasksForDepartment(dept);
    }
  }

  Future<void> _loadTasksForDepartment(String dept) async {
    try {
      final data = await Supabase.instance.client
          .from('tasks')
          .select('*')
          .eq('project_id', widget.project.id)
          .eq('department', dept);
      List<Task> active = [];
      List<Task> completed = [];
      for (var item in data) {
        Task task = Task.fromMap(item);
        if (task.isCompleted) {
          completed.add(task);
        } else {
          active.add(task);
        }
      }
      setState(() {
        activeTasks[dept] = active;
        completedTasks[dept] = completed;
        isLoadingTasks[dept] = false;
      });
        } catch (e) {
      print("Error loading tasks for $dept: $e");
      setState(() {
        isLoadingTasks[dept] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: departments.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: badgerPrimary,
          title: Text('Proje: ${widget.project.title}'),
          bottom: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: badgerAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 16),
            tabs: departments
                .map((dept) => Container(
                  height: 30,
                      width: MediaQuery.of(context).size.width / departments.length,
                      alignment: Alignment.center,
                      child: Text(dept),
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: departments.map((dept) {
            return DepartmentPanel(
              projectId: widget.project.id,
              department: dept,
              activeTasks: activeTasks[dept] ?? [],
              completedTasks: completedTasks[dept] ?? [],
              isLoading: isLoadingTasks[dept] ?? true,
              refreshTasks: () => _loadTasksForDepartment(dept),
              badgerPrimary: badgerPrimary,
              badgerAccent: badgerAccent,
              badgerLight: badgerLight,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DepartmentPanel extends StatefulWidget {
  final int projectId;
  final String department;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final bool isLoading;
  final VoidCallback refreshTasks;
  final Color badgerPrimary;
  final Color badgerAccent;
  final Color badgerLight;

  const DepartmentPanel({
    super.key,
    required this.projectId,
    required this.department,
    required this.activeTasks,
    required this.completedTasks,
    required this.isLoading,
    required this.refreshTasks,
    required this.badgerPrimary,
    required this.badgerAccent,
    required this.badgerLight,
  });

  @override
  _DepartmentPanelState createState() => _DepartmentPanelState();
}

class _DepartmentPanelState extends State<DepartmentPanel> with TickerProviderStateMixin {
  late TabController _subTabController;

  // For adding/editing tasks
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  DateTime? deadline;
  String? priority;
  String? activeStatus;
  List<String> selectedUsers = [];
  List<String> availableUsers = [];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _fetchAvailableUsers();
  }

  Future<void> _fetchAvailableUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('email');
      setState(() {
        availableUsers = data.map((e) => (e)['email'].toString()).toList();
      });
        } catch (e) {
      print("Error fetching available users: $e");
    }
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  // FloatingActionButton olarak sağ alt köşede görev ekleme butonu
  void _showAddTaskDialog() {
    // Clear fields
    _taskTitleController.clear();
    _taskDescriptionController.clear();
    deadline = null;
    priority = null;
    activeStatus = null;
    selectedUsers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Yeni Görev Ekle - ${widget.department}'),
            content: SizedBox(
              width: 600,
              height: 900,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Görev Başlığı
                  TextField(
                    controller: _taskTitleController,
                    decoration: const InputDecoration(labelText: "Görev Başlığı *"),
                  ),
                  const SizedBox(height: 16),
                  // Deadline seçimi
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
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              deadline = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Öncelik Durumu
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Öncelik Durumu",
                      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    value: priority,
                    hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                    items: ['Acil', 'Orta', 'Sakin'].map((option) {
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
                  // Atanan Kişiler (Assign) - MultiSelect
                  MultiSelectDialogField<String>(
                    items: availableUsers
                        .map((user) => MultiSelectItem<String>(user, user))
                        .toList(),
                    title: const Text("Atanan Kişiler"),
                    buttonText: const Text("Kişi Seçiniz"),
                    initialValue: selectedUsers,
                    onConfirm: (results) {
                      setStateDialog(() {
                        selectedUsers = results.cast<String>();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Task'ın Aktif Durumu (Durum)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Task'ın Aktif Durumu",
                      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    value: activeStatus,
                    hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                    items: ['Yapılıyor', 'Beklemede'].map((option) {
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
                  // Açıklama
                  TextField(
                    controller: _taskDescriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = _taskTitleController.text.trim();
                  final description = _taskDescriptionController.text.trim();
                  if (title.isNotEmpty) {
                    try {
                      await Supabase.instance.client.from('tasks').insert({
                        'project_id': widget.projectId,
                        'department': widget.department,
                        'title': title,
                        'description': description,
                        'deadline': deadline?.toIso8601String(),
                        'priority': priority,
                        'active_status': activeStatus,
                        'assigned_to': selectedUsers.isNotEmpty ? selectedUsers.join(", ") : null,
                        'is_completed': false,
                      });
                      Navigator.pop(context);
                      widget.refreshTasks();
                    } catch (e) {
                      print("Error adding task: $e");
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

  // DataTable oluşturma fonksiyonu: Ekran genişliğine göre düzenlendi.
  Widget _buildDataTable(List<Task> tasks) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text("Tamamlandı")),
            DataColumn(label: Text("Başlık")),
            DataColumn(label: Text("Atanan")),
            DataColumn(label: Text("Deadline")),
            DataColumn(label: Text("Öncelik")),
            DataColumn(label: Text("Durum")),
            DataColumn(label: Text("Açıklama")),
            DataColumn(label: Text("Sil")),
          ],
          rows: tasks.map((task) {
            final textStyle = task.isCompleted
                ? const TextStyle(color: Colors.white)
                : const TextStyle(color: Colors.black);
            final assignedDisplay = task.assignedTo ?? "-";
            final shortDesc = task.description != null && task.description!.length > 15
                ? "${task.description!.substring(0, 15)}..."
                : task.description ?? "-";
            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) async {
                      try {
                        await Supabase.instance.client.from('tasks').update({
                          'is_completed': value,
                        }).eq('id', task.id);
                        widget.refreshTasks();
                      } catch (e) {
                        print("Error updating is_completed: $e");
                      }
                    },
                  ),
                ),
                DataCell(Text(task.title, style: textStyle)),
                DataCell(Text(assignedDisplay, style: textStyle)),
                DataCell(Text(
                  task.deadline != null ? DateFormat('dd-MM-yyyy').format(task.deadline!) : "-",
                  style: textStyle,
                )),
                DataCell(Text(task.priority ?? "-", style: textStyle)),
                DataCell(Text(task.activeStatus ?? "-", style: textStyle)),
                DataCell(Text(shortDesc, style: textStyle)),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete, color: task.isCompleted ? Colors.white : Colors.black),
                    onPressed: () async {
                      try {
                        await Supabase.instance.client.from('tasks').delete().eq('id', task.id);
                        widget.refreshTasks();
                      } catch (e) {
                        print("Error deleting task: $e");
                      }
                    },
                  ),
                ),
              ],
              onSelectChanged: (_) {
                _showEditTaskDialog(task);
              },
            );
          }).toList(),
        ),
      );
    });
  }

  // Görev düzenleme diyaloğu
  void _showEditTaskDialog(Task task) {
    // Pre-fill controllers with existing task data.
    _taskTitleController.text = task.title;
    _taskDescriptionController.text = task.description ?? "";
    deadline = task.deadline;
    priority = task.priority;
    activeStatus = task.activeStatus;
    selectedUsers = task.assignedTo != null ? task.assignedTo!.split(",").map((s) => s.trim()).toList() : [];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Görevi Düzenle - ${widget.department}'),
            content: SizedBox(
              width: 600,
              height: 900,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _taskTitleController,
                    decoration: const InputDecoration(labelText: "Görev Başlığı *"),
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
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              deadline = pickedDate;
                            });
                          }
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
                    items: ['Acil', 'Orta', 'Sakin'].map((option) {
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
                  MultiSelectDialogField<String>(
                    items: availableUsers
                        .map((user) => MultiSelectItem<String>(user, user))
                        .toList(),
                    title: const Text("Atanan Kişiler"),
                    buttonText: const Text("Kişi Seçiniz"),
                    initialValue: selectedUsers,
                    onConfirm: (results) {
                      setStateDialog(() {
                        selectedUsers = results.cast<String>();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Task'ın Aktif Durumu",
                      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    value: activeStatus,
                    hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                    items: ['Yapılıyor', 'Beklemede'].map((option) {
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
                  TextField(
                    controller: _taskDescriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedTitle = _taskTitleController.text.trim();
                  final updatedDescription = _taskDescriptionController.text.trim();
                  if (updatedTitle.isNotEmpty) {
                    try {
                      await Supabase.instance.client.from('tasks').update({
                        'title': updatedTitle,
                        'description': updatedDescription,
                        'deadline': deadline?.toIso8601String(),
                        'priority': priority,
                        'active_status': activeStatus,
                        'assigned_to': selectedUsers.isNotEmpty ? selectedUsers.join(", ") : null,
                      }).eq('id', task.id);
                      Navigator.pop(context);
                      widget.refreshTasks();
                    } catch (e) {
                      print("Error updating task: $e");
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
    return Stack(
      children: [
        Column(
          children: [
            // Alt TabBar: Aktif Görevler ve Tamamlanan Görevler
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBar(
                controller: _subTabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: widget.badgerAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 16),
                tabs: const [
                  Tab(text: 'Aktif Görevler'),
                  Tab(text: 'Tamamlanan Görevler'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _subTabController,
                children: [
                  widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.activeTasks.isEmpty
                          ? const Center(child: Text('Aktif görev bulunamadı.'))
                          : SingleChildScrollView(
                              child: _buildDataTable(widget.activeTasks),
                            ),
                  widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.completedTasks.isEmpty
                          ? const Center(child: Text('Tamamlanan görev bulunamadı.'))
                          : SingleChildScrollView(
                              child: _buildDataTable(widget.completedTasks),
                            ),
                ],
              ),
            ),
          ],
        ),
        // Sağ altta, floating görev ekleme butonu
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: widget.badgerAccent,
            onPressed: _showAddTaskDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
