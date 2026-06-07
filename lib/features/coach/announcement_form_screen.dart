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
  bool _targetAll = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _bodyCtrl.text = widget.existing!['body'] ?? '';
      _targetAll = widget.existing!['targetClientIds'] == 'all';
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
      'targetClientIds': _targetAll ? 'all' : [],
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
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Send to all clients'),
              subtitle: const Text('Off = specific clients only'),
              value: _targetAll,
              activeColor: const Color(0xFF1565C0),
              onChanged: (v) => setState(() => _targetAll = v),
              contentPadding: EdgeInsets.zero,
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
