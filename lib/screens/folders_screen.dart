import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import 'notes_screen.dart';
import 'login_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _folderController = TextEditingController();

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (!mounted) return;
      
      // Navigate to login screen and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isLoading = false;

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder', style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: _folderController,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
            hintStyle: TextStyle(color: Colors.black54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_folderController.text.isNotEmpty) {
                await _firestoreService.createFolder(_folderController.text);
                _folderController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('My Folders', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: StreamBuilder<List<Folder>>(
        stream: _firestoreService.getFolders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Check for Firestore index error
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('cloud_firestore/failed-precondition') && errorMsg.contains('requires an index')) {
              return const Center(
                child: Text(
                  'A database index is being created. Please wait a moment and try again.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            // Other errors
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data ?? [];

          if (folders.isEmpty) {
            return const Center(
              child: Text('No folders yet. Create one to get started!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: const Icon(Icons.folder, color: Colors.indigo),
                  ),
                  title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.indigo),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Rename'),
                        onTap: () {
                          _folderController.text = folder.name;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Rename Folder'),
                              content: TextField(
                                controller: _folderController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter new folder name',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (_folderController.text.isNotEmpty) {
                                      await _firestoreService.updateFolder(
                                        folder.id,
                                        _folderController.text,
                                      );
                                      _folderController.clear();
                                      if (mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Rename'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () async {
                          await _firestoreService.deleteFolder(folder.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesScreen(folderId: folder.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _showCreateFolderDialog,
        child: const Icon(Icons.create_new_folder, color: Colors.indigo),
      ),
    );
  }
} 