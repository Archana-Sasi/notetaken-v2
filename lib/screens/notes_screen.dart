import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/firestore_service.dart';
import 'package:share_plus/share_plus.dart';

class NotesScreen extends StatefulWidget {
  final String folderId;

  const NotesScreen({super.key, required this.folderId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Note', style: TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Enter note title',
                  hintStyle: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Enter note content',
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                await _firestoreService.createNote(
                  widget.folderId,
                  _titleController.text,
                  _contentController.text,
                );
                _titleController.clear();
                _contentController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(Note note) {
    _titleController.text = note.title;
    _contentController.text = note.content;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter note title',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter note content',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                await _firestoreService.updateNote(
                  note.id,
                  _titleController.text,
                  _contentController.text,
                );
                _titleController.clear();
                _contentController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
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
        title: const Text('Notes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _firestoreService.getNotesInFolder(widget.folderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('cloud_firestore/failed-precondition') && errorMsg.contains('requires an index')) {
              return const Center(
                child: Text(
                  'A database index is being created. Please wait a moment and try again.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var notes = snapshot.data ?? [];
          if (_searchQuery.isNotEmpty) {
            notes = notes.where((note) =>
              note.title.toLowerCase().contains(_searchQuery) ||
              note.content.toLowerCase().contains(_searchQuery)
            ).toList();
          }

          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes yet. Create one to get started!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: const Icon(Icons.note, color: Colors.indigo),
                  ),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.indigo),
                        onPressed: () {
                          Share.share('Title: ${note.title}\n\n${note.content}');
                        },
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.indigo),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Edit'),
                            onTap: () => _showEditNoteDialog(note),
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () async {
                              await _firestoreService.deleteNote(note.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showEditNoteDialog(note),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _showCreateNoteDialog,
        child: const Icon(Icons.note_add, color: Colors.indigo),
      ),
    );
  }
} 