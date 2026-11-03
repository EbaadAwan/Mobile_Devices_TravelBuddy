import 'package:flutter/material.dart';

import '../../services/travel_notification_service.dart';
import '../activity/activity_status_widgets.dart';
import 'trip_editor_dialog.dart';
import 'trip_plan.dart';
import 'trip_store.dart';

const _cyan = Color(0xFF08C6DF);

/// Fits inside the existing TravelBuddyShell tab; does not add another AppBar
/// or BottomNavigationBar, so the team's layout stays unchanged.
class TripPlannerFeature extends StatefulWidget {
  const TripPlannerFeature({super.key, required this.onAddDestination});
  final VoidCallback onAddDestination;

  @override
  State<TripPlannerFeature> createState() => _TripPlannerFeatureState();
}

class _TripPlannerFeatureState extends State<TripPlannerFeature> {
  final _store = TripStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Keep the text controller alive for the full lifetime of the dialog route.
  // showDialog completes when pop is requested, before the exit animation ends.
  Future<void> _editTripName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditValueDialog(
        title: 'Edit trip name',
        label: 'Trip name',
        initialValue: _store.tripName,
        maxLength: 60,
      ),
    );
    if (!mounted || name == null) return;
    try {
      await _store.renameTrip(name);
    } catch (_) {
      _message('Enter a valid trip name.');
    }
  }

  Future<void> _editBudget() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditValueDialog(
        title: 'Set trip budget',
        label: 'Budget',
        initialValue: _store.budget.toStringAsFixed(0),
        numeric: true,
      ),
    );
    if (!mounted || text == null) return;
    try {
      final value = double.parse(text);
      await _store.setBudget(value);
    } catch (_) {
      _message('Enter a valid budget of zero or more.');
    }
  }

  Future<void> _delete(TripPlan trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove planned visit?'),
        content: Text('Remove ${trip.destinationName} from your trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _store.remove(trip.id);
      try {
        await TravelNotificationService.instance.cancelTrip(trip);
      } catch (_) {
        _message('Trip removed, but its reminder may still be pending.');
        return;
      }
      _message('Visit removed. Reminder cancelled.');
    } catch (_) {
      _message('Unable to remove this visit.');
    }
  }

  Future<void> _testNotification() async {
    try {
      final sent =
          await TravelNotificationService.instance.showTestNotification();
      _message(sent
          ? 'Test notification sent. Check the Android notification shade.'
          : 'Notifications are unavailable or permission was denied.');
    } catch (_) {
      _message('Could not send the test notification.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        if (!_store.loaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_store.loadError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_store.loadError!),
                TextButton(
                  onPressed: _store.retryLoad,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final all = _store.trips;
        final upcoming = _store.upcoming;
        final past = all.where((trip) => !trip.visitAt.isAfter(DateTime.now()))
            .toList()..sort((a, b) => b.visitAt.compareTo(a.visitAt));
        final estimatedCost = upcoming.length * 35.0;
        final progress = _store.budget <= 0
            ? 0.0
            : (estimatedCost / _store.budget).clamp(0.0, 1.0).toDouble();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
          children: [
            InkWell(
              onTap: _editTripName,
              child: Row(
                children: [
                  Expanded(
                    child: Text('‘${_store.tripName}’',
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.edit_outlined, color: Colors.black54, size: 19),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text('${upcoming.length} upcoming visit${upcoming.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _editBudget,
              child: Row(
                children: [
                  const Text('Budget:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('\$${estimatedCost.toStringAsFixed(0)} / '
                      '\$${_store.budget.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.edit_outlined,
                      size: 17, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Illustrative \$35 per visit — not live prices',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18E99A)),
              ),
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Text('Planned Destinations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => TripEditorDialog.open(context),
                  icon: const Icon(Icons.add_circle_outline, color: _cyan),
                  tooltip: 'Plan a new visit',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26, horizontal: 14),
                child: Column(
                  children: [
                    Icon(Icons.map_outlined, size: 44, color: Colors.black26),
                    SizedBox(height: 8),
                    Text('No upcoming visits yet',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Plan a visit to choose its date and time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              )
            else
              for (final trip in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VisitCard(
                    trip: trip,
                    onEdit: () => TripEditorDialog.open(context, existing: trip),
                    onDelete: () => _delete(trip),
                  ),
                ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: widget.onAddDestination,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Destination'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _cyan),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => TripEditorDialog.open(context),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Create a Visit'),
              style: FilledButton.styleFrom(backgroundColor: _cyan),
            ),
            if (past.isNotEmpty) ...[
              const SizedBox(height: 18),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Past visits (${past.length})'),
                children: [
                  for (final trip in past)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VisitCard(
                        trip: trip,
                        onEdit: () => TripEditorDialog.open(context, existing: trip),
                        onDelete: () => _delete(trip),
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 30),
            const Text('Android notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Saved visits can trigger local reminders. '
              'This is not Firebase cloud push messaging. '
              'Android may delay inexact scheduled reminders.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Send test notification'),
            ),
          ],
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
  });
  final TripPlan trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(trip.visitAt);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(trip.visitAt),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Colors.orange, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(trip.destinationName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit visit',
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete visit',
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
              ],
            ),
            Text(trip.title, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: _cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('$date · $time',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (trip.notes.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(trip.notes,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            const SizedBox(height: 7),
            ActivityStatusBadge(attractionName: trip.destinationName, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Owns its controller until the dialog's exit animation has fully finished.
/// Keeping controller disposal in State.dispose avoids editing a disposed field.
class _EditValueDialog extends StatefulWidget {
  const _EditValueDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    this.maxLength,
    this.numeric = false,
  });

  final String title;
  final String label;
  final String initialValue;
  final int? maxLength;
  final bool numeric;

  @override
  State<_EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<_EditValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        keyboardType: widget.numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: widget.numeric ? '\$ ' : null,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
