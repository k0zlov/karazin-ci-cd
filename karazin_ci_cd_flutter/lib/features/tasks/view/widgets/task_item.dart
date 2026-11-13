import 'package:flutter/material.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/data/models/task_model.dart';

class TaskItem extends StatelessWidget {
  const new({
    required this.task,
    required this.enabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final TaskModel task;
  final bool enabled;
  final ValueChanged<TaskModel> onToggle;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = task.description;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(value: task.completed, onChanged: enabled ? (_) => onToggle(task) : null),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: enabled ? () => onEdit(task) : null,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: enabled ? () => onDelete(task) : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
