import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder.dart';
import '../models/note.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Folder operations
  Future<String> createFolder(String name) async {
    final docRef = _firestore.collection('folders').doc();
    final folder = Folder(
      id: docRef.id,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await docRef.set(folder.toMap());
    return docRef.id;
  }

  Future<void> updateFolder(String id, String name) async {
    await _firestore.collection('folders').doc(id).update({
      'name': name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteFolder(String id) async {
    // Delete all notes in the folder first
    final notesSnapshot = await _firestore
        .collection('notes')
        .where('folderId', isEqualTo: id)
        .get();
    
    for (var doc in notesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Then delete the folder
    await _firestore.collection('folders').doc(id).delete();
  }

  Stream<List<Folder>> getFolders() {
    return _firestore
        .collection('folders')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Folder.fromMap(doc.data())).toList();
    });
  }

  // Note operations
  Future<String> createNote(String folderId, String title, String content, {String? imageUrl}) async {
    final docRef = _firestore.collection('notes').doc();
    final note = Note(
      id: docRef.id,
      folderId: folderId,
      title: title,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await docRef.set(note.toMap());
    return docRef.id;
  }

  Future<void> updateNote(String id, String title, String content, {String? imageUrl}) async {
    final updateData = {
      'title': title,
      'content': content,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }
    await _firestore.collection('notes').doc(id).update(updateData);
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
  }

  Stream<List<Note>> getNotesInFolder(String folderId) {
    return _firestore
        .collection('notes')
        .where('folderId', isEqualTo: folderId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromMap(doc.data())).toList();
    });
  }
} 