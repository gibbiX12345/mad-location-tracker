import 'package:flutter/material.dart';
import 'package:mad_location_tracker/models/activity_model.dart';

class ActivityList extends StatelessWidget {
  final List<ActivityModel> activities;
  final EdgeInsetsGeometry? padding;
  final void Function(ActivityModel) onOpen;
  final void Function(ActivityModel) onRename;
  final void Function(ActivityModel) onDelete;

  const ActivityList({
    super.key,
    required this.activities,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: activities.map(_buildActivityEntry).toList(),
      ),
    );
  }

  Widget _buildActivityEntry(ActivityModel activity) {
    return ListTile(
      key: Key(activity.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onRename(activity),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () => onDelete(activity),
            icon: const Icon(Icons.delete_forever),
            color: Colors.red,
          ),
        ],
      ),
      title: Text(
        _formatTitle(activity),
        style: activity.isActive
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: Text(_formatSubtitle(activity)),
      onTap: () => onOpen(activity),
    ) as Widget;
  }

  String _formatTitle(ActivityModel activity) =>
      activity.name + (activity.isActive ? " (active)" : "");

  String _formatSubtitle(ActivityModel activity) => activity.startTime.toString();
}
