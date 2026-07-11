import 'package:flutter/material.dart';

import 'package:stash/services/notifications_service.dart';
import 'package:stash/services/reminder_prefs.dart';

Future<void> showReminderDialog(BuildContext context) async {
  final enabled = await ReminderPrefs.getEnabled();
  final hour = await ReminderPrefs.getHour();
  final minute = await ReminderPrefs.getMinute();
  final title = await ReminderPrefs.getTitle();
  final body = await ReminderPrefs.getBody();
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => _ReminderDialog(
      initialEnabled: enabled,
      initialHour: hour,
      initialMinute: minute,
      initialTitle: title,
      initialBody: body,
    ),
  );
}

class _ReminderDialog extends StatefulWidget {
  final bool initialEnabled;
  final int initialHour;
  final int initialMinute;
  final String initialTitle;
  final String initialBody;

  const _ReminderDialog({
    required this.initialEnabled,
    required this.initialHour,
    required this.initialMinute,
    required this.initialTitle,
    required this.initialBody,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late bool _enabled;
  late int _hour;
  late int _minute;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _titleController = TextEditingController(text: widget.initialTitle);
    _bodyController = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final h = _hour == 0 ? 12 : (_hour > 12 ? _hour - 12 : _hour);
    final m = _minute.toString().padLeft(2, '0');
    final suffix = _hour < 12 ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final granted = await NotificationsService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is needed for reminders')),
        );
        return;
      }
    }
    setState(() => _enabled = value);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message cannot be empty')),
      );
      return;
    }

    if (_enabled) {
      await NotificationsService.scheduleDailyReminder(
        hour: _hour,
        minute: _minute,
        title: title,
        body: body,
      );
    } else {
      await NotificationsService.cancelReminder();
    }
    await ReminderPrefs.save(
      enabled: _enabled,
      hour: _hour,
      minute: _minute,
      title: title,
      body: body,
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_enabled ? 'Daily reminder set for $_timeLabel' : 'Reminders off')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: cs.primary),
          const SizedBox(width: 10),
          const Text('Daily reminder'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable reminder'),
              value: _enabled,
              onChanged: _toggle,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _enabled ? _pickTime : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _enabled
                      ? cs.primaryContainer.withValues(alpha: 0.5)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _enabled ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _enabled ? cs.primary : cs.outline, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeLabel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _enabled ? cs.onSurface : cs.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: _enabled ? cs.primary : cs.outline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              enabled: _enabled,
              decoration: const InputDecoration(
                labelText: 'Notification title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              enabled: _enabled,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notification message',
                prefixIcon: Icon(Icons.message_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A daily nudge to add to your savings goals. Works fully offline.',
              style: TextStyle(fontSize: 11, color: cs.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
