import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:vikunja_app/components/TaskBottomSheet.dart';
import 'package:vikunja_app/models/task.dart';
import 'package:vikunja_app/utils/misc.dart';
import 'package:vikunja_app/pages/project/task_edit.dart';
import 'package:vikunja_app/utils/priority.dart';

import '../models/project.dart';
import '../stores/project_store.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function onEdit;
  final bool showInfo;
  final bool showPriority;
  final bool loading;
  final Project? project;
  final ValueSetter<bool>? onMarkedAsDone;
  final ValueSetter<bool>? onMarkedAsFavorite;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onEdit,
    this.loading = false,
    this.showInfo = false,
    this.project,
    this.showPriority = true,
    this.onMarkedAsFavorite,
    this.onMarkedAsDone,
  }) : super(key: key);
/*
  @override
  TaskTileState createState() {
    return new TaskTileState(this.task, this.loading);
  }

 */
  @override
  TaskTileState createState() => TaskTileState(this.task);
}

Widget? _buildTaskSubtitle(
    Task? task, bool showInfo, bool showPriority, BuildContext context) {
  Duration? durationUntilDue = task?.dueDate?.difference(DateTime.now());

  if (task == null) return null;

  List<TextSpan> texts = [];

  if (showInfo && task.hasDueDate) {
    texts.add(TextSpan(
        text: "Due " + durationToHumanReadable(durationUntilDue!),
        style: durationUntilDue.isNegative
            ? TextStyle(color: Colors.red)
            : Theme.of(context).textTheme.bodyMedium));
  }
  if (showPriority && task.priority != null && task.priority != 0) {
    texts.add(TextSpan(
        text: " !" + priorityToString(task.priority),
        style: TextStyle(color: Colors.orange)));
  }

  //if(texts.isEmpty && task.description.isNotEmpty) {
  //  return HtmlWidget(task.description);
  // }

  if (texts.isNotEmpty) {
    return RichText(text: TextSpan(children: texts));
  }
  return null;
}

class TaskTileState extends State<TaskTile> with AutomaticKeepAliveClientMixin {
  Task _currentTask;

  TaskTileState(this._currentTask);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final taskState = Provider.of<ProjectProvider>(context);
    if (_currentTask.loading) {
      return ListTile(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
              height: Checkbox.width,
              width: Checkbox.width,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
              )),
        ),
        title: Text(_currentTask.title),
        subtitle: _currentTask.description.isEmpty
            ? null
            : HtmlWidget(_currentTask.description),
        trailing: IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {},
        ),
      );
    }
    return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
        onTap: () {
          showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return TaskBottomSheet(
                    task: widget.task,
                    onEdit: widget.onEdit,
                    taskState: taskState);
              });
        },
        title: widget.showInfo
            ? RichText(
                text: TextSpan(
                text: null,
                children: <TextSpan>[
                  // TODO: get list name of task
                  if (widget.project != null)
                    TextSpan(
                        text: widget.project!.title + " ",
                        style: TextStyle(color: Colors.grey)),
                  TextSpan(text: widget.task.title),
                ],
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ))
            : Text(_currentTask.title),
        subtitle: _buildTaskSubtitle(
            widget.task, widget.showInfo, widget.showPriority, context),
        leading: Checkbox(
          value: _currentTask.done,
          onChanged: (bool? newValue) {
            _changeDone(newValue);
          },
        ),
        trailing: Wrap(
          spacing: -16,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push<Task>(
                  context,
                  MaterialPageRoute(
                    builder: (buildContext) => TaskEditPage(
                      task: _currentTask,
                      taskState: taskState,
                    ),
                  ),
                )
                    .then((task) => setState(() {
                          if (task != null) _currentTask = task;
                        }))
                    .whenComplete(() => widget.onEdit());
              },
            ),
            IconButton(
              icon: _currentTask.is_favorite
                  ? Icon(Icons.star)
                  : Icon(Icons.star_border),
              color: _currentTask.is_favorite ? Colors.orange : null,
              onPressed: () {
                _toggleFavorite(!_currentTask.is_favorite);
              },
            ),
          ],
        ));
  }

  void _changeDone(bool? value) async {
    value = value ?? false;
    setState(() {
      this._currentTask.loading = true;
    });
    Task newTask = _currentTask.copyWith(done: value);
    _updateTask(newTask);
    setState(() {
      this._currentTask = newTask;
      this._currentTask.loading = false;
    });
    widget.onEdit();
  }

  void _toggleFavorite(bool? value) async {
    value = value ?? false;
    setState(() {
      this._currentTask.loading = true;
    });
    Task newTask = _currentTask.copyWith(is_favorite: value);
    _updateTask(newTask);
    setState(() {
      this._currentTask = newTask;
      this._currentTask.loading = false;
    });
    if (widget.onMarkedAsFavorite != null) widget.onMarkedAsFavorite!(value);
  }

  Future<Task?> _updateTask(Task updatedTask) {
    return Provider.of<ProjectProvider>(context, listen: false).updateTask(
      context: context,
      task: updatedTask,
    );
  }

  @override
  bool get wantKeepAlive => _currentTask != widget.task;
}

typedef Future<void> TaskChanged(Task task, bool newValue);
