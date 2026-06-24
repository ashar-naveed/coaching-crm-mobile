import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnnouncementFormScreen extends StatefulWidget {
  final String? announcementId;
  final Map<String, dynamic>? existing;

  const AnnouncementFormScreen({super.key, this.announcementId, this.existing});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _bodyCtrl.text = widget.existing!['body'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final coachId = FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'coachId': coachId,
      'title': _titleCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'targetClientIds': 'all',
      'readBy': widget.existing?['readBy'] ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.announcementId == null) {
        await FirebaseFirestore.instance.collection('announcements').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(widget.announcementId)
            .update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.announcementId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Announcement' : 'New Announcement'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 5,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sends to all clients',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEdit ? 'Update' : 'Post Announcement',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
