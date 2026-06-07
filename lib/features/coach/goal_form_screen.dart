import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GoalFormScreen extends StatefulWidget {
  final String clientId;
  final String? goalId;
  final Map<String, dynamic>? existing;

  const GoalFormScreen({
    super.key,
    required this.clientId,
    this.goalId,
    this.existing,
  });

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'active';
  int _progress = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _descCtrl.text = widget.existing!['description'] ?? '';
      _status = widget.existing!['status'] ?? 'active';
      _progress = (widget.existing!['progress'] as num?)?.toInt() ?? 0;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final coachId = FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'clientId': widget.clientId,
      'coachId': coachId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'status': _status,
      'progress': _progress,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.goalId == null) {
        await FirebaseFirestore.instance.collection('goals').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('goals')
            .doc(widget.goalId)
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
    final isEdit = widget.goalId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Goal' : 'New Goal'),
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
              decoration: const InputDecoration(labelText: 'Goal title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'paused', child: Text('Paused')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$_progress%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            Slider(
              value: _progress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: const Color(0xFF1565C0),
              onChanged: (v) => setState(() => _progress = v.toInt()),
            ),
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF1565C0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
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
                  isEdit ? 'Update Goal' : 'Create Goal',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
