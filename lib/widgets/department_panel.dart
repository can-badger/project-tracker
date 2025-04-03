import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DepartmentPanel extends StatefulWidget {
  final int projectId;
  final String department;
  final List<String> activeTasks;
  final List<String> completedTasks;
  final bool isLoading;
  final VoidCallback refreshTasks; // Parent'tan yeniden yükleme fonksiyonu

  const DepartmentPanel({
    super.key,
    required this.projectId,
    required this.department,
    required this.activeTasks,
    required this.completedTasks,
    required this.isLoading,
    required this.refreshTasks,
  });

  @override
  _DepartmentPanelState createState() => _DepartmentPanelState();
}

class _DepartmentPanelState extends State<DepartmentPanel> with TickerProviderStateMixin {
  late TabController _subTabController;
  final TextEditingController _taskTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _taskTitleController.dispose();
    super.dispose();
  }

  // Yeni görev eklemek için dialog
  void _showAddTaskDialog() {
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController = TextEditingController();
  DateTime? deadline;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Yeni Görev Ekle - ${widget.department}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskTitleController,
                decoration: const InputDecoration(
                  labelText: 'Görev Başlığı',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: taskDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      deadline = pickedDate;
                    });
                  }
                },
                child: Text(
                  deadline == null
                      ? 'Deadline Seç'
                      : 'Deadline: ${deadline!.toLocal().toString().split(' ')[0]}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              taskTitleController.clear();
              taskDescriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = taskTitleController.text.trim();
              final description = taskDescriptionController.text.trim();
              if (title.isNotEmpty) {
                try {
                  await Supabase.instance.client.from('tasks').insert({
                    'project_id': widget.projectId,
                    'department': widget.department,
                    'title': title,
                    'description': description,
                    'is_completed': false,
                    'deadline': deadline?.toIso8601String(),
                  });
                  taskTitleController.clear();
                  taskDescriptionController.clear();
                  Navigator.pop(context);
                  widget.refreshTasks();
                } catch (e) {
                  print("Error adding task: $e");
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


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Alt TabBar (Aktif Görevler ve Tamamlanan Görevler) ile ekleme butonu ekleyelim
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _subTabController,
                  tabs: const [
                    Tab(text: 'Aktif Görevler'),
                    Tab(text: 'Tamamlanan Görevler'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddTaskDialog,
                tooltip: 'Görev Ekle',
              ),
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
                      : ListView.builder(
                          itemCount: widget.activeTasks.length,
                          itemBuilder: (context, index) {
                            final taskTitle = widget.activeTasks[index];
                            return ListTile(
                              title: Text(taskTitle),
                            );
                          },
                        ),
              widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.completedTasks.isEmpty
                      ? const Center(child: Text('Tamamlanan görev bulunamadı.'))
                      : ListView.builder(
                          itemCount: widget.completedTasks.length,
                          itemBuilder: (context, index) {
                            final taskTitle = widget.completedTasks[index];
                            return ListTile(
                              title: Text(taskTitle),
                            );
                          },
                        ),
            ],
          ),
        ),
      ],
    );
  }
}
