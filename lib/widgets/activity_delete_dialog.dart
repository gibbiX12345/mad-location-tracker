import 'package:flutter/material.dart';
import 'package:mad_location_tracker/models/activity_model.dart';

class ActivityDeleteDialog extends StatelessWidget {
  final ActivityModel activity;

  final void Function() onCancel;
  final void Function() onDelete;

  const ActivityDeleteDialog({
    super.key,
    required this.activity,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Delete \"${activity.name}\"?"),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: onDelete,
          child: const Text("Delete forever"),
        )
      ],
      content: const SingleChildScrollView(
        child: Text(
            "Do you really want to delete this activity? This can't be undone."),
      ),
    );
  }
}
