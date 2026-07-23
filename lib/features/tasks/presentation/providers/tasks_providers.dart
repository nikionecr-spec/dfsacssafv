import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/providers.dart';
import '../../data/tasks_repository.dart';
import '../../domain/task.dart';

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(ref.watch(databaseProvider)),
);

/// Whether completed tasks are shown in the main list.
final showCompletedTasksProvider = StateProvider<bool>((ref) => false);

final tasksListProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final bool includeDone = ref.watch(showCompletedTasksProvider);
  return ref.watch(tasksRepositoryProvider).getTasks(includeDone: includeDone);
});

/// Open tasks due today or overdue — used by the dashboard and daily plan.
final todayPlanProvider = FutureProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(tasksRepositoryProvider).getTodayPlan(),
);

final tasksForDayProvider =
    FutureProvider.autoDispose.family<List<Task>, DateTime>(
  (ref, DateTime day) => ref.watch(tasksRepositoryProvider).getTasksForDay(day),
);

class TasksController {
  TasksController(this.ref);
  final Ref ref;

  TasksRepository get _repo => ref.read(tasksRepositoryProvider);
  NotificationService get _notifications => ref.read(notificationServiceProvider);

  Future<void> save(Task task) async {
    await _repo.upsertTask(task);
    await _syncReminder(task);
    _invalidate();
  }

  Future<void> setStatus(Task task, TaskStatus status) async {
    await _repo.setStatus(task.id, status);
    if (status == TaskStatus.done) {
      await _notifications.cancel(NotificationService.idFrom(task.id));
    }
    _invalidate();
  }

  Future<void> toggleDone(Task task) =>
      setStatus(task, task.isDone ? TaskStatus.todo : TaskStatus.done);

  Future<void> toggleItem(ChecklistItem item, bool done) async {
    await _repo.toggleItem(item.id, done);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTask(id);
    await _notifications.cancel(NotificationService.idFrom(id));
    _invalidate();
  }

  /// Keeps the scheduled reminder in sync with the task's deadline.
  Future<void> _syncReminder(Task task) async {
    final int id = NotificationService.idFrom(task.id);
    await _notifications.cancel(id);
    final DateTime? deadline = task.deadline;
    if (deadline != null && !task.isDone && deadline.isAfter(DateTime.now())) {
      await _notifications.scheduleReminder(
        id: id,
        title: 'Task due: ${task.title}',
        body: task.notes?.isNotEmpty == true ? task.notes! : 'Tap to open Aura',
        when: deadline,
        payload: 'task:${task.id}',
      );
    }
  }

  void _invalidate() {
    ref.invalidate(tasksListProvider);
    ref.invalidate(todayPlanProvider);
  }
}

final tasksControllerProvider =
    Provider<TasksController>((ref) => TasksController(ref));
