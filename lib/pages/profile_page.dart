import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Hata yakalamak için

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  // Profil alanları
  String? _fullName;
  String? _email;
  String? _avatarUrl;

  // Güncelleme için TextEditingController'lar
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _avatarUrlController = TextEditingController();

  // Şifre değiştirme için controller'lar
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// Supabase'ten profil verilerini çekiyoruz.
  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final userId = user.id;
    _email = user.email;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final profileData = data;
      setState(() {
        _fullName = profileData['full_name'] as String? ?? 'Adınız';
        _avatarUrl = profileData['avatar_url'] as String?;
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      debugPrint('Supabase sorgu hatası: ${error.message}');
      setState(() => _isLoading = false);
    } catch (error) {
      debugPrint('Beklenmedik hata: $error');
      setState(() => _isLoading = false);
    }
  }

  /// İsmi güncelleme
  Future<void> _updateFullName(String newName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'full_name': newName})
          .eq('id', user.id)
          .single();
      setState(() {
        _fullName = newName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İsim başarıyla güncellendi')));
    } catch (error) {
      debugPrint('İsim güncelleme hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İsim güncellenirken hata oluştu')));
    }
  }

  /// Email güncelleme
  Future<void> _updateEmail(String newEmail) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      setState(() {
        _email = newEmail;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email başarıyla güncellendi')));
    } catch (error) {
      debugPrint('Email güncelleme hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email güncellenirken hata oluştu')));
    }
  }

  /// Profil resmi (avatar) güncelleme
  Future<void> _updateAvatarUrl(String newUrl) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': newUrl})
          .eq('id', user.id)
          .single();
      setState(() {
        _avatarUrl = newUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi başarıyla güncellendi')));
    } catch (error) {
      debugPrint('Profil resmi güncelleme hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi güncellenirken hata oluştu')));
    }
  }

  /// Şifre güncelleme
  Future<void> _updatePassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi')));
    } catch (error) {
      debugPrint('Şifre güncelleme hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre güncellenirken hata oluştu')));
    }
  }

  /// İsim değiştirme diyalogunu göster
  void _showChangeFullNameDialog() {
    _fullNameController.text = _fullName ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İsmi Değiştir'),
          content: TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Yeni İsim'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _fullNameController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = _fullNameController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(context);
                  _updateFullName(newName);
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  /// Email değiştirme diyalogunu göster
  void _showChangeEmailDialog() {
    _emailController.text = _email ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email Değiştir'),
          content: TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Yeni Email'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _emailController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newEmail = _emailController.text.trim();
                if (newEmail.isNotEmpty) {
                  Navigator.pop(context);
                  _updateEmail(newEmail);
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  /// Profil resmi değiştirme diyalogunu göster
  void _showChangeAvatarDialog() {
    _avatarUrlController.text = _avatarUrl ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profil Resmini Değiştir'),
          content: TextField(
            controller: _avatarUrlController,
            decoration: const InputDecoration(labelText: 'Yeni Resim URL'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _avatarUrlController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = _avatarUrlController.text.trim();
                if (newUrl.isNotEmpty) {
                  Navigator.pop(context);
                  _updateAvatarUrl(newUrl);
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  /// Şifre değiştirme diyalogunu göster
  void _showChangePasswordDialog() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Şifre Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPassword = _newPasswordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();
                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifreler eşleşmiyor')),
                  );
                  return;
                }
                Navigator.pop(context);
                _updatePassword(newPassword);
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profil Resmi (tıklanabilir, güncellenebilir)
              GestureDetector(
                onTap: _showChangeAvatarDialog,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Full Name (tıklanabilir, güncellenebilir)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _fullName ?? 'Kullanıcı Adı Yok',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _showChangeFullNameDialog,
                    icon: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Email (tıklanabilir, güncellenebilir)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _email ?? 'E-posta bulunamadı',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    onPressed: _showChangeEmailDialog,
                    icon: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Şifre değiştirme butonu
              ElevatedButton(
                onPressed: _showChangePasswordDialog,
                child: const Text('Şifre Değiştir'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
