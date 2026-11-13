import 'package:flutter/material.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/data/models/task_model.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/view/widgets/task_item.dart';

class TaskList extends StatelessWidget {
  const new({
    required this.tasks,
    required this.enabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<TaskModel> tasks;
  final bool enabled;
  final ValueChanged<TaskModel> onToggle;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Create your first task to get started.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];

        return TaskItem(
          key: ValueKey(task.id),
          task: task,
          enabled: enabled,
          onToggle: onToggle,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
