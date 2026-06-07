import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionFormScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String? sessionId;
  final Map<String, dynamic>? existing;

  const SessionFormScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.sessionId,
    this.existing,
  });

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 60;
  String _status = 'upcoming';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final dt = (widget.existing!['scheduledAt'] as Timestamp).toDate();
      _date = dt;
      _time = TimeOfDay.fromDateTime(dt);
      _duration = widget.existing!['durationMinutes'] as int? ?? 60;
      _status = widget.existing!['status'] as String? ?? 'upcoming';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }
    setState(() => _loading = true);

    final coachId = FirebaseAuth.instance.currentUser!.uid;
    final scheduledAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    final data = {
      'clientId': widget.clientId,
      'coachId': coachId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': _duration,
      'status': _status,
      'coachNotes': widget.existing?['coachNotes'] ?? '',
      'clientReflection': widget.existing?['clientReflection'] ?? '',
    };

    try {
      if (widget.sessionId == null) {
        await FirebaseFirestore.instance.collection('sessions').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
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
    final isEdit = widget.sessionId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Session' : 'Schedule Session'),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Client name
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF1565C0)),
                const SizedBox(width: 10),
                Text(
                  widget.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
            title: Text(
              _date == null
                  ? 'Select date'
                  : '${_date!.day}/${_date!.month}/${_date!.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const Divider(),

          // Time picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: Color(0xFF1565C0)),
            title: Text(_time == null ? 'Select time' : _time!.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                '$_duration min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          Slider(
            value: _duration.toDouble(),
            min: 15,
            max: 120,
            divisions: 7,
            activeColor: const Color(0xFF1565C0),
            onChanged: (v) => setState(() => _duration = v.toInt()),
          ),
          const SizedBox(height: 16),

          // Status
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
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
              isEdit ? 'Update Session' : 'Schedule Session',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
