import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mad_location_tracker/models/activity_model.dart';

class ActivityContext extends StatefulWidget {
  final ActivityModel activity;

  final void Function() onFinish;

  const ActivityContext({
    super.key,
    required this.onFinish,
    required this.activity,
  });

  @override
  State<ActivityContext> createState() => _ActivityContextState();
}

class _ActivityContextState extends State<ActivityContext>
    with WidgetsBindingObserver {
  
  late Timer timer;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _formatActivityTitle(widget.activity),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  Text(
                    '${widget.activity.duration().inMinutes}',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'min',
                    style: TextStyle(fontSize: 20, height: 0),
                  ),
                ],
              ),
              const SizedBox(width: 24.0),
              Column(
                children: [
                  Text(
                    '${widget.activity.duration().inSeconds % 60}',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'sec',
                    style: TextStyle(fontSize: 20, height: 0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Start: ${widget.activity.readableStartTime()}',
                style: const TextStyle(fontSize: 14, height: 0),
              ),
              const SizedBox(width: 100.0),
              Text(
                'End: ${widget.activity.readableEndTime()}',
                style: const TextStyle(fontSize: 14, height: 0),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Visibility(
            visible: widget.activity.isActive,
            child: ElevatedButton(
              onPressed: () {
                widget.onFinish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Stop Recording',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityTitle(ActivityModel activity) =>
      activity.name + (activity.isActive ? " (active)" : "");
}
