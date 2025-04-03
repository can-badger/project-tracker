import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// İki seviye yukarı çıkarak models ve services klasörlerine erişiyoruz:
import '../../models/project.dart';
import '../../models/task.dart';
// import '../../services/project_service.dart';

// Eğer bu sayfada MyTodosPage, MyTagsPage, vb. kullanılmıyorsa import etmeyin.
// Örneğin, eğer profile_page.dart kullanılıyorsa:
// import '../profile_page.dart';
// tasks klasöründeki sayfalar:
// import '../tasks/my_todos_page.dart';
// import '../tasks/my_tags_page.dart';
// import '../tasks/notifications_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final bool highlight; // Proje sayfasına highlight parametresi eklemek isterseniz

  const ProjectDetailPage({
    super.key,
    required this.project,
    this.highlight = false,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final List<String> departments = [
    'DEV',
    'ART',
    'Dijital Pazarlama',
    'Grafik Tasarım',
    'Kurumsal'
  ];

  int _currentDepartmentIndex = 0;

  Map<String, List<Task>> activeTasks = {};
  Map<String, List<Task>> completedTasks = {};
  Map<String, bool> isLoadingTasks = {};

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
      if (!mounted) return; // BuildContext uyarısı
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
      debugPrint("Error loading tasks for $dept: $e");
      if (!mounted) return;
      setState(() {
        isLoadingTasks[dept] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // highlight parametresini kullanmak isterseniz, bir border veya animasyon ekleyebilirsiniz.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: badgerPrimary,
        title: Text('Proje: ${widget.project.title}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: departments.asMap().entries.map((entry) {
              int idx = entry.key;
              String dept = entry.value;
              final int activeCount = activeTasks[dept]?.length ?? 0;
              final int completedCount = completedTasks[dept]?.length ?? 0;
              final int totalCount = activeCount + completedCount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDepartmentIndex = idx;
                  });
                },
                child: Container(
                  height: 30,
                  width: MediaQuery.of(context).size.width / departments.length,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _currentDepartmentIndex == idx ? badgerAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$dept($totalCount)",
                    style: TextStyle(
                      fontSize: _currentDepartmentIndex == idx ? 18 : 16,
                      fontWeight: _currentDepartmentIndex == idx ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: DepartmentPanel(
          key: ValueKey(_currentDepartmentIndex),
          projectId: widget.project.id,
          department: departments[_currentDepartmentIndex],
          activeTasks: activeTasks[departments[_currentDepartmentIndex]] ?? [],
          completedTasks: completedTasks[departments[_currentDepartmentIndex]] ?? [],
          isLoading: isLoadingTasks[departments[_currentDepartmentIndex]] ?? true,
          refreshTasks: () => _loadTasksForDepartment(departments[_currentDepartmentIndex]),
          badgerPrimary: badgerPrimary,
          badgerAccent: badgerAccent,
          badgerLight: badgerLight,
        ),
      ),
    );
  }
}

// DepartmentPanel sınıfı kodu (kısaltılmış). Aynı mantıkla import yolları, if (!mounted) vb. düzeltildi.


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
  State<DepartmentPanel> createState() => _DepartmentPanelState();
}

class _DepartmentPanelState extends State<DepartmentPanel> {
  int _currentSubTabIndex = 0;

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
    _fetchAvailableUsers();
  }

  Future<void> _fetchAvailableUsers() async {
    try {
      final data = await Supabase.instance.client.from('profiles').select('email');
      if (!mounted) return;
      setState(() {
        availableUsers = data.map((e) => (e)['email'].toString()).toList();
      });
    } catch (e) {
      debugPrint("Error fetching available users: $e");
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
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
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (!mounted) return; 
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
                    items: ['Acil', 'Orta', 'Sakin']
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        priority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // ... MultiSelectDialogField vb.
                  // ... activeStatus dropdown vb.
                  // ... Diğer alanlar
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
                      if (!mounted) return;
                      Navigator.pop(context);
                      widget.refreshTasks();
                    } catch (e) {
                      debugPrint("Error adding task: $e");
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
            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) async {
                      try {
                        await Supabase.instance.client
                            .from('tasks')
                            .update({'is_completed': value})
                            .eq('id', task.id);
                        if (!mounted) return;
                        widget.refreshTasks();
                      } catch (e) {
                        debugPrint("Error updating is_completed: $e");
                      }
                    },
                  ),
                ),
                DataCell(Text(task.title, style: textStyle)),
                DataCell(Text(task.assignedTo ?? "-", style: textStyle)),
                DataCell(Text(
                  task.deadline != null
                      ? DateFormat('dd-MM-yyyy').format(task.deadline!)
                      : "-",
                  style: textStyle,
                )),
                DataCell(Text(task.priority ?? "-", style: textStyle)),
                DataCell(Text(task.activeStatus ?? "-", style: textStyle)),
                DataCell(Text(
                  (task.description != null && task.description!.length > 15)
                      ? "${task.description!.substring(0, 15)}..."
                      : task.description ?? "-",
                  style: textStyle,
                )),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: task.isCompleted ? Colors.white : Colors.black),
                    onPressed: () async {
                      try {
                        await Supabase.instance.client
                            .from('tasks')
                            .delete()
                            .eq('id', task.id);
                        if (!mounted) return;
                        widget.refreshTasks();
                      } catch (e) {
                        debugPrint("Error deleting task: $e");
                      }
                    },
                  ),
                ),
              ],
              onSelectChanged: (_) => _showEditTaskDialog(task),
            );
          }).toList(),
        ),
      );
    });
  }

  void _showEditTaskDialog(Task task) {
    _taskTitleController.text = task.title;
    _taskDescriptionController.text = task.description ?? "";
    deadline = task.deadline;
    priority = task.priority;
    activeStatus = task.activeStatus;
    selectedUsers = task.assignedTo != null
        ? task.assignedTo!.split(",").map((s) => s.trim()).toList()
        : [];

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
                  // ...deadline, priority, assigned_to, vb.
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
                      if (!mounted) return;
                      Navigator.pop(context);
                      widget.refreshTasks();
                    } catch (e) {
                      debugPrint("Error updating task: $e");
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
            // Sub-tab bar: Aktif & Tamamlanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _currentSubTabIndex = 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentSubTabIndex == 0 ? widget.badgerAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Aktif Görevler',
                      style: TextStyle(
                        fontSize: _currentSubTabIndex == 0 ? 18 : 16,
                        fontWeight: _currentSubTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _currentSubTabIndex = 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentSubTabIndex == 1 ? widget.badgerAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tamamlanan Görevler',
                      style: TextStyle(
                        fontSize: _currentSubTabIndex == 1 ? 18 : 16,
                        fontWeight: _currentSubTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _currentSubTabIndex == 0
                      ? (widget.isLoading
                          ? const Center(key: ValueKey('loadingActive'), child: CircularProgressIndicator())
                          : widget.activeTasks.isEmpty
                              ? const Center(key: ValueKey('noActive'), child: Text('Aktif görev bulunamadı.'))
                              : SingleChildScrollView(
                                  key: const ValueKey('active'),
                                  child: _buildDataTable(widget.activeTasks),
                                ))
                      : (widget.isLoading
                          ? const Center(key: ValueKey('loadingCompleted'), child: CircularProgressIndicator())
                          : widget.completedTasks.isEmpty
                              ? const Center(key: ValueKey('noCompleted'), child: Text('Tamamlanan görev bulunamadı.'))
                              : SingleChildScrollView(
                                  key: const ValueKey('completed'),
                                  child: _buildDataTable(widget.completedTasks),
                                )),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'fab-${widget.department}',
            backgroundColor: widget.badgerAccent,
            onPressed: _showAddTaskDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
