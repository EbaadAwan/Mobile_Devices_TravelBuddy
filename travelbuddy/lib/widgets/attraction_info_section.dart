// Shown on the attraction details sheet. Calls AttractionDetailsService (HTTP) and displays: 
// open/closed status, a weekly opening-hours table, address, phone, website and a 
// Wikipedia description when available. While loading it shows a spinner; if the request fails 
// it shows a retry button and the hours that came with the attraction data.

import 'package:flutter/material.dart';

import '../services/attraction_details_service.dart';

class AttractionInfoSection extends StatefulWidget {
  const AttractionInfoSection({
    super.key,
    required this.attractionName,
    this.location = '',
    this.fallbackHours,
  });

  final String attractionName;

  /// City/area to make the search more accurate, e.g. "Oshawa, Ontario".
  final String location;

  /// Hours already known from the attraction data, used if the API has none.
  final String? fallbackHours;

  @override
  State<AttractionInfoSection> createState() => _AttractionInfoSectionState();
}

class _AttractionInfoSectionState extends State<AttractionInfoSection> {
  late Future<AttractionDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AttractionDetails> _load({bool forceRefresh = false}) {
    return AttractionDetailsService.fetchDetails(
      name: widget.attractionName,
      location: widget.location,
      forceRefresh: forceRefresh,
    );
  }

  void _retry() => setState(() => _future = _load(forceRefresh: true));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AttractionDetails>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingRow();
        }
        if (snapshot.hasError) {
          return _ErrorCard(onRetry: _retry, fallbackHours: widget.fallbackHours);
        }
        return _DetailsView(details: snapshot.data!, fallbackHours: widget.fallbackHours);
      },
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Loading hours and details...', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry, this.fallbackHours});

  final VoidCallback onRetry;
  final String? fallbackHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fallbackHours != null) ...[
          _InfoRow(icon: Icons.schedule, text: 'Listed hours: $fallbackHours'),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Couldn't load live details. Check your connection.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.details, this.fallbackHours});

  final AttractionDetails details;
  final String? fallbackHours;

  @override
  Widget build(BuildContext context) {
    final hours = details.openingHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Opening hours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (hours != null) _OpenNowChip(isOpen: hours.isOpenAt(DateTime.now())),
          ],
        ),
        const SizedBox(height: 8),
        if (hours != null)
          _HoursTable(days: hours.week())
        else if (details.openingHoursRaw != null)
          _InfoRow(icon: Icons.schedule, text: details.openingHoursRaw!)
        else
          _InfoRow(
            icon: Icons.schedule,
            text: fallbackHours != null
                ? 'Listed hours: $fallbackHours (not confirmed online)'
                : 'Opening hours not available.',
          ),
        if (details.address != null ||
            details.phone != null ||
            details.website != null) ...[
          const SizedBox(height: 16),
          const Text('Contact & location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (details.address != null) _InfoRow(icon: Icons.place_outlined, text: details.address!),
          if (details.phone != null) _InfoRow(icon: Icons.phone_outlined, text: details.phone!),
          if (details.website != null) _InfoRow(icon: Icons.language, text: details.website!),
        ],
        if (details.description != null) ...[
          const SizedBox(height: 16),
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(details.description!, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 4),
          const Text('Source: Wikipedia', style: TextStyle(fontSize: 11, color: Colors.black45)),
        ],
        if (details.hasAnyData) ...[
          const SizedBox(height: 10),
          const Text(
            'Map data © OpenStreetMap contributors',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ],
    );
  }
}

class _OpenNowChip extends StatelessWidget {
  const _OpenNowChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF14A85F) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed now',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _HoursTable extends StatelessWidget {
  const _HoursTable({required this.days});

  final List<DayHours> days;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Table(
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final day in days)
              TableRow(
                decoration: day.isToday
                    ? BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
                    child: Text(
                      day.isToday ? '${day.dayName} (today)' : day.dayName,
                      style: TextStyle(
                        fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: Text(
                      day.label,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
                        color: day.isClosed ? Colors.redAccent : null,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}
