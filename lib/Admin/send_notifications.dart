import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notifications_service.dart';

class SendNotificationsPage extends StatefulWidget {
  const SendNotificationsPage({super.key});

  @override
  State<SendNotificationsPage> createState() => _SendNotificationsPageState();
}

class _SendNotificationsPageState extends State<SendNotificationsPage> {
  final _authService = AuthService();
  final _notificationsService = NotificationsService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _target = 'all';
  String? _selectedUserId;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send(List<User> users) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    final recipients = _target == 'all'
        ? users.where((user) => user.role.trim().toLowerCase() != 'admin')
        : users.where((user) => user.uid == _selectedUserId);

    final recipientIds = recipients.map((user) => user.uid).toList();
    if (recipientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a recipient')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _notificationsService.createNotificationsForUsers(
        userIds: recipientIds,
        title: title,
        message: message,
        type: 'admin',
      );

      if (!mounted) return;
      _titleController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send notification')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Send Notification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<User>>(
        stream: _authService.usersStream(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? const <User>[];
          final recipients = users
              .where((user) => user.role.trim().toLowerCase() != 'admin')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('Everyone'),
                          icon: Icon(Icons.groups_rounded),
                        ),
                        ButtonSegment(
                          value: 'single',
                          label: Text('One User'),
                          icon: Icon(Icons.person_rounded),
                        ),
                      ],
                      selected: {_target},
                      onSelectionChanged: (value) {
                        setState(() => _target = value.first);
                      },
                    ),
                    if (_target == 'single') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUserId,
                        decoration: InputDecoration(
                          hintText: 'Choose user',
                          filled: true,
                          fillColor: const Color(0xFFF6F7F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: recipients
                            .map(
                              (user) => DropdownMenuItem(
                                value: user.uid,
                                child: Text(
                                  '${user.fullName} (${user.role})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedUserId = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Notification title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSending || snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : () => _send(users),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Send Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3DE0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
