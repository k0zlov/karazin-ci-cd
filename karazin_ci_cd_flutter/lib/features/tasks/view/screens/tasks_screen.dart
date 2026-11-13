import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karazin_ci_cd_flutter/core/network/api_routes.dart';
import 'package:karazin_ci_cd_flutter/core/network/network.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/data/models/task_draft.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/data/models/task_model.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/view/widgets/task_editor_dialog.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/view/widgets/task_list.dart';

class TasksScreen extends StatefulWidget {
  const new({required this.network, super.key});

  final Network network;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskModel> _tasks = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTasks());
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.network.get<List<dynamic>>(ApiRoutes.tasks);

      final tasks = response.map((item) {
        return TaskModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load tasks: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performAction(Future<void> Function() action, String successMessage) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await action();
      await _loadTasks();

      if (!mounted) return;

      _showMessage(successMessage);
    } catch (error, stackTrace) {
      debugPrint('Task operation failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Operation failed', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _createTask() async {
    final draft = await showDialog<TaskDraft>(context: context, builder: (_) => const TaskEditorDialog());

    if (draft == null || !mounted) return;

    await _performAction(() async {
      await widget.network.post<Map<String, dynamic>>(
        ApiRoutes.tasks,
        data: {'title': draft.title, 'description': draft.description, 'completed': false},
      );
    }, 'Task created');
  }

  Future<void> _editTask(TaskModel task) async {
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => TaskEditorDialog(task: task),
    );

    if (draft == null || !mounted) return;

    await _performAction(() async {
      await widget.network.put<Map<String, dynamic>>(
        ApiRoutes.task(task.id),
        data: {'title': draft.title, 'description': draft.description},
      );
    }, 'Task updated');
  }

  Future<void> _toggleTask(TaskModel task) async {
    await _performAction(() async {
      await widget.network.put<Map<String, dynamic>>(ApiRoutes.task(task.id), data: {'completed': !task.completed});
    }, 'Task updated');
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _performAction(() => widget.network.delete(ApiRoutes.task(task.id)), 'Task deleted');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: isError ? Theme.of(context).colorScheme.error : null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _tasks.where((task) => task.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isSaving ? null : _loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your tasks', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount of ${_tasks.length} completed',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _createTask,
                      icon: const Icon(Icons.add),
                      label: const Text('New task'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isSaving) const LinearProgressIndicator(minHeight: 2),
                if (_isSaving) const SizedBox(height: 12),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadTasks, child: const Text('Try again')),
          ],
        ),
      );
    }

    return TaskList(
      tasks: _tasks,
      enabled: !_isSaving,
      onToggle: _toggleTask,
      onEdit: _editTask,
      onDelete: _deleteTask,
    );
  }
}
