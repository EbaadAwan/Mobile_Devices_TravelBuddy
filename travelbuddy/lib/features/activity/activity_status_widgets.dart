import 'package:flutter/material.dart';

import 'activity_status_service.dart';

const _accent = Color(0xFF08C6DF);

Color _statusColor(CrowdLevel level) => switch (level) {
      CrowdLevel.quiet => const Color(0xFF188C57),
      CrowdLevel.moderate => const Color(0xFFBC7B00),
      CrowdLevel.busy => const Color(0xFFC43D3D),
      CrowdLevel.unavailable => Colors.blueGrey,
    };

/// Designed for narrow destination cards and planned-visit rows.
class ActivityStatusBadge extends StatelessWidget {
  const ActivityStatusBadge({
    super.key,
    required this.attractionName,
    this.compact = false,
  });

  final String attractionName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActivityStatusService.instance,
      builder: (context, _) {
        final status = ActivityStatusService.instance.statusFor(attractionName);
        final suffix = status.source == ActivitySource.demo
            ? ' · DEMO'
            : status.source == ActivitySource.external
                ? ' · LIVE'
                : ' · No data';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: _statusColor(status.level), size: 9),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${status.label}$suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Visible in attraction details; controls simulate crowd changes for the
/// checkpoint. A simulated value is never labelled as an actual live reading.
class ActivityStatusPanel extends StatelessWidget {
  const ActivityStatusPanel({super.key, required this.attractionName});
  final String attractionName;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActivityStatusService.instance,
      builder: (context, _) {
        final service = ActivityStatusService.instance;
        final status = service.statusFor(attractionName);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attraction activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ActivityStatusBadge(attractionName: attractionName),
              const SizedBox(height: 6),
              Text(
                status.source == ActivitySource.external
                    ? 'Status supplied by a connected data source.'
                    : status.source == ActivitySource.demo
                        ? 'Demonstration only — not real-time crowd information.'
                        : 'Live crowd data is not connected for this attraction.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              const Text('Try a demo status:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: [
                  for (final level in [
                    CrowdLevel.quiet,
                    CrowdLevel.moderate,
                    CrowdLevel.busy,
                  ])
                    ChoiceChip(
                      label: Text(level.name[0].toUpperCase() +
                          level.name.substring(1)),
                      selected: status.source == ActivitySource.demo &&
                          status.level == level,
                      selectedColor: _accent.withValues(alpha: 0.18),
                      onSelected: (_) => service.setDemoStatus(attractionName, level),
                    ),
                  ActionChip(
                    label: const Text('Reset'),
                    onPressed: () => service.setUnavailable(attractionName),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
