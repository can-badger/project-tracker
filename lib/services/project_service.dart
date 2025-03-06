// lib/services/project_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';

class ProjectService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    try {
      // Supabase yeni sürümde sorgu doğrudan veriyi döndürüyor.
      final data = await client.from('projects').select('*');
      return (data as List)
          .map((item) => Project.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching projects: $e");
    }
  }

  Future<void> addProject(String title, {String? description}) async {
    try {
      await client.from('projects').insert({
        'title': title,
        'description': description,
      });
    } catch (e) {
      throw Exception("Error adding project: $e");
    }
  }

  Future<void> deleteProject(int projectId) async {
    try {
      await client.from('projects').delete().eq('id', projectId);
    } catch (e) {
      throw Exception("Error deleting project: $e");
    }
  }
}
