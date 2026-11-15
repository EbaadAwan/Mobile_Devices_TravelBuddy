import 'dart:async';
import 'package:flutter/material.dart';

String visitCountdown(DateTime visitAt, DateTime now) {
  final remaining = visitAt.difference(now);
  if (remaining <= Duration.zero) return 'Visit time reached';
  if (remaining <= const Duration(minutes: 5)) return 'Starting soon';
  final seconds = remaining.inSeconds;
  if (seconds < 3600) return 'In ${(seconds + 59) ~/ 60} minutes';
  if (seconds < 86400) {
    return 'In ${(seconds + 3599) ~/ 3600} hours';
  }
  return 'In ${(seconds + 86399) ~/ 86400} days';
}

/// Updates while a visit card is on screen; requires no additional package.
class VisitCountdown extends StatefulWidget {
  const VisitCountdown({super.key, required this.visitAt});
  final DateTime visitAt;

  @override
  State<VisitCountdown> createState() => _VisitCountdownState();
}

class _VisitCountdownState extends State<VisitCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      visitCountdown(widget.visitAt, DateTime.now()),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF007E91),
      ),
    );
  }
}
