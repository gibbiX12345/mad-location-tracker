import 'package:flutter/material.dart';
import 'package:mad_location_tracker/models/activity_model.dart';

class ActivityRenameDialog extends StatelessWidget {
  final ActivityModel activity;

  final void Function() onCancel;
  final void Function(String newName) onRename;

  const ActivityRenameDialog({
    super.key,
    required this.onCancel,
    required this.onRename,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final renameFieldController = TextEditingController();
    renameFieldController.text = activity.name;

    return AlertDialog(
      title: Text("Rename \"${activity.name}\"?"),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => onRename(renameFieldController.text),
          child: const Text("Save"),
        )
      ],
      content: SingleChildScrollView(
        child: TextFormField(
          autofocus: true,
          controller: renameFieldController,
        ),
      ),
    );
  }
}
