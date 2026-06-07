import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActionItemFormScreen extends StatefulWidget {
  final String goalId;
  final String clientId;
  final String? itemId;
  final Map<String, dynamic>? existing;

  const ActionItemFormScreen({
    super.key,
    required this.goalId,
    required this.clientId,
    this.itemId,
    this.existing,
  });

  @override
  State<ActionItemFormScreen> createState() => _ActionItemFormScreenState();
}

class _ActionItemFormScreenState extends State<ActionItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  DateTime? _dueDate;
  String _status = 'pending';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _status = widget.existing!['status'] ?? 'pending';
      if (widget.existing!['dueDate'] != null) {
        _dueDate = (widget.existing!['dueDate'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final coachId = FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'goalId': widget.goalId,
      'clientId': widget.clientId,
      'coachId': coachId,
      'title': _titleCtrl.text.trim(),
      'status': _status,
      'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
      'completedAt': null,
    };

    try {
      if (widget.itemId == null) {
        await FirebaseFirestore.instance.collection('actionItems').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('actionItems')
            .doc(widget.itemId)
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
    final isEdit = widget.itemId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Action Item' : 'New Action Item'),
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
              decoration: const InputDecoration(labelText: 'Action item title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Due date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFF1565C0),
              ),
              title: Text(
                _dueDate == null
                    ? 'Set due date'
                    : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'delayed', child: Text('Delayed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isEdit ? 'Update' : 'Create',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
