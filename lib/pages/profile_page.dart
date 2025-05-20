import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:no_couch_needed/widgets/therapy_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String username;
  final String name;
  final String surname;
  final int age;
  final String profilePictureUrl;

  Profile({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    required this.age,
    required this.profilePictureUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    username: map['username'] as String? ?? '',
    name: map['name'] as String? ?? '',
    surname: map['surname'] as String? ?? '',
    age:
        map['age'] is int
            ? map['age'] as int
            : int.tryParse(map['age']?.toString() ?? '0') ?? 0,
    profilePictureUrl: map['profile_picture_url'] as String? ?? '',
  );
}

/// Provider for fetching profile
final profileProvider2 = FutureProvider<Profile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final res =
      await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
  if (res == null) return null;
  return Profile.fromMap(res);
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();

  File? _imageFile;
  String? _avatarUrl;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    String avatarUrl = _avatarUrl ?? '';
    if (_imageFile != null) {
      // Upload to Supabase Storage
      final storagePath =
          '${user.id}/avatar.${_imageFile!.path.split('.').last}';
      await Supabase.instance.client.storage
          .from('avatar')
          .upload(
            storagePath,
            _imageFile!,
            fileOptions: FileOptions(upsert: true),
          );
      avatarUrl = storagePath;
    }

    final profileData = {
      'id': user.id,
      'username': _usernameController.text.trim(),
      'name': _nameController.text.trim(),
      'surname': _surnameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'profile_picture_url': avatarUrl,
    };

    await Supabase.instance.client
        .from('profiles')
        .upsert(profileData)
        .select();

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile saved!")));
      ref.refresh(profileProvider2);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider2);

    return Scaffold(
      drawer: TherapyDrawer(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
        },
      ),
      backgroundColor: const Color(0xFFE3F6F5),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text(
          'Your Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF22223B),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading: $err')),
        data: (profile) {
          if (profile != null && _avatarUrl == null) {
            _usernameController.text = profile.username;
            _nameController.text = profile.name;
            _surnameController.text = profile.surname;
            _ageController.text =
                profile.age == 0 ? '' : profile.age.toString();
            _avatarUrl = profile.profilePictureUrl;
          }
          return Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 3,
                color: Colors.white.withOpacity(0.93),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: const Color(0xFF57CC99),
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (_avatarUrl != null &&
                                                  _avatarUrl!.isNotEmpty
                                              ? NetworkImage(
                                                Supabase.instance.client.storage
                                                    .from('avatar')
                                                    .getPublicUrl(_avatarUrl!),
                                              )
                                              : null)
                                          as ImageProvider?,
                              child:
                                  _imageFile == null &&
                                          (_avatarUrl == null ||
                                              _avatarUrl!.isEmpty)
                                      ? const Icon(
                                        Icons.add_a_photo,
                                        color: Color(0xFF22223B),
                                        size: 40,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 22),
                          buildField(
                            _usernameController,
                            "Username",
                            Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return "Enter a username";
                              if (v.trim().length < 3)
                                return "Username too short!";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildField(
                            _nameController,
                            "First name",
                            Icons.abc,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return "Enter your first name";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildField(
                            _surnameController,
                            "Surname",
                            Icons.abc_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return "Enter your surname";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildField(
                            _ageController,
                            "Age",
                            Icons.date_range,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return "Enter your age";
                              final intAge = int.tryParse(v.trim());
                              if (intAge == null || intAge < 13)
                                return "You must be 13+";
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF38A3A5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _saving ? null : _saveProfile,
                              child:
                                  _saving
                                      ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child: CircularProgressIndicator(),
                                      )
                                      : const Text(
                                        "Save",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your profile will help us provide a personalized AI therapy experience.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
    );
  }
}
