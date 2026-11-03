import 'package:flutter/material.dart';

import '../../services/travel_notification_service.dart';
import 'trip_plan.dart';
import 'trip_store.dart';

const _cyan = Color(0xFF08C6DF);

/// Reusable from both an attraction's 'Add to trip' button and the planner.
class TripEditorDialog extends StatefulWidget {
  const TripEditorDialog({
    super.key,
    this.existing,
    this.initialDestination = '',
    this.initialLocation = '',
  });

  final TripPlan? existing;
  final String initialDestination;
  final String initialLocation;

  static Future<bool> open(
    BuildContext context, {
    TripPlan? existing,
    String destinationName = '',
    String destinationLocation = '',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showDialog<TripPlan>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TripEditorDialog(
        existing: existing,
        initialDestination: destinationName,
        initialLocation: destinationLocation,
      ),
    );
    if (updated == null) return false;

    try {
      await TripStore.instance.upsert(updated);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not save the trip. Please try again.'),
      ));
      return false;
    }

    var reminderScheduled = false;
    try {
      reminderScheduled =
          await TravelNotificationService.instance.scheduleTrip(updated);
    } catch (_) {
      // A notification failure must not undo a successfully saved visit.
    }
    messenger.showSnackBar(SnackBar(
      content: Text(reminderScheduled
          ? 'Trip saved. Android reminder scheduled.'
          : 'Trip saved. No reminder scheduled (check permissions or time).'),
    ));
    return true;
  }

  @override
  State<TripEditorDialog> createState() => _TripEditorDialogState();
}

class _TripEditorDialogState extends State<TripEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _destination;
  late final TextEditingController _notes;
  late DateTime _date;
  late TimeOfDay _time;
  String? _dateError;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final name = existing?.destinationName ?? widget.initialDestination;
    _title = TextEditingController(
      text: existing?.title ?? (name.isEmpty ? '' : 'Visit $name'),
    );
    _destination = TextEditingController(text: name);
    _notes = TextEditingController(text: existing?.notes ?? '');
    final initial = existing?.visitAt ?? DateTime.now().add(const Duration(days: 3));
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay.fromDateTime(initial);
  }

  @override
  void dispose() {
    _title.dispose();
    _destination.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
      lastDate: DateTime(now.year + 3, now.month, now.day),
      helpText: 'Choose your visit date',
    );
    if (!mounted || chosen == null) return;
    setState(() {
      _date = chosen;
      _dateError = null;
      _changed = true;
    });
  }

  Future<void> _pickTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Choose your visit time',
    );
    if (!mounted || chosen == null) return;
    setState(() {
      _time = chosen;
      _dateError = null;
      _changed = true;
    });
  }

  Future<void> _cancel() async {
    if (_changed ||
        _title.text != (widget.existing?.title ??
            (widget.initialDestination.isEmpty
                ? ''
                : 'Visit ${widget.initialDestination}')) ||
        _destination.text !=
            (widget.existing?.destinationName ?? widget.initialDestination) ||
        _notes.text != (widget.existing?.notes ?? '')) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved trip changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (!mounted || discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final visit = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (!visit.isAfter(DateTime.now())) {
      setState(() => _dateError = 'Choose a date and time in the future.');
      return;
    }
    setState(() => _dateError = null);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm visit'),
        content: Text(
          'Schedule ${_destination.text.trim()} for '
          '${MaterialLocalizations.of(context).formatMediumDate(visit)} '
          'at ${MaterialLocalizations.of(context).formatTimeOfDay(_time)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save visit'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final trip = TripPlan(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      destinationName: _destination.text.trim(),
      destinationLocation:
          widget.existing?.destinationLocation ?? widget.initialLocation,
      visitAt: visit,
      notes: _notes.text.trim(),
    );
    Navigator.pop(context, trip);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      title: Text(widget.existing == null ? 'Plan a visit' : 'Edit visit'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Trip title',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter a trip title.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _destination,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter a destination.'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 17),
                        label: Text(MaterialLocalizations.of(context)
                            .formatMediumDate(_date)),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_outlined, size: 17),
                    label: Text(MaterialLocalizations.of(context)
                        .formatTimeOfDay(_time)),
                  ),
                ),
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_dateError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Text('Reminders require Android notification permission.',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: _cyan),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
