// lib/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://xobtpdqyhzpxsqhmpqij.supabase.co', // Supabase projenizin URL'sini buraya ekleyin
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhvYnRwZHF5aHpweHNxaG1wcWlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5MjI3NzAsImV4cCI6MjA1NTQ5ODc3MH0.UDSbEC5rDyhqLum8IfQG4lcJhcG4fiTUJKdgsv5UDno', // Anonim API anahtarınızı buraya ekleyin
  );
}
