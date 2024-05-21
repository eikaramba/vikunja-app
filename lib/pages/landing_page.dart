import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vikunja_app/global.dart';
import 'package:vikunja_app/models/project.dart';
import 'package:vikunja_app/service/services.dart';
import 'package:collection/collection.dart';
import 'dart:developer';
import 'package:vikunja_app/utils/priority.dart';

import '../components/AddDialog.dart';
import '../components/TaskTile.dart';
import '../components/pagestatus.dart';
import '../models/task.dart';

class HomeScreenWidget extends StatefulWidget {
  HomeScreenWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

class LandingPage extends HomeScreenWidget {
  LandingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with AfterLayoutMixin<LandingPage> {
  int? defaultList;
  bool onlyDueDate = true;
  bool showUpcoming = false;
  bool showDone = false;
  List<Task> _tasks = [];
  Map<int, Project> projects = {};
  Map<String, List<Task>> _tasksByPriority = {};
  PageStatus landingPageStatus = PageStatus.built;
  static const platform = const MethodChannel('vikunja');

  Future<void> _updateDefaultList() async {
    return VikunjaGlobal.of(context).newUserService?.getCurrentUser().then(
          (value) => setState(() {
            defaultList = value?.settings?.default_project_id;
          }),
        );
  }

  @override
  void initState() {
    Future.delayed(
        Duration.zero,
        () => _updateDefaultList().then((value) {
              try {
                platform.invokeMethod("isQuickTile", "").then((value) =>
                    {if (value is bool && value) _addItemDialog(context)});
              } catch (e) {
                log(e.toString());
              }
              VikunjaGlobal.of(context)
                  .settingsManager
                  .getLandingPageOnlyDueDateTasks()
                  .then((value) => onlyDueDate = value);
              VikunjaGlobal.of(context)
                  .settingsManager
                  .getShowUpcomingTasks()
                  .then((value) => showUpcoming = value);
              VikunjaGlobal.of(context)
                  .settingsManager
                  .getShowDoneTasks()
                  .then((value) => showDone = value);
            }));
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    try {
      // This is needed when app is already open and quicktile is clicked
      platform.setMethodCallHandler((call) {
        switch (call.method) {
          case "open_add_task":
            _addItemDialog(context);
            break;
        }
        return Future.value();
      });
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (landingPageStatus) {
      case PageStatus.built:
        _loadList(context);
        body = new Stack(children: [
          ListView(),
          Center(
            child: CircularProgressIndicator(),
          )
        ]);
        break;
      case PageStatus.loading:
        body = new Stack(children: [
          ListView(),
          Center(
            child: CircularProgressIndicator(),
          )
        ]);
        break;
      case PageStatus.error:
        body = new Stack(children: [
          ListView(),
          Center(child: Text("There was an error loading this view"))
        ]);
        break;
      case PageStatus.empty:
        body = new Stack(
            children: [ListView(), Center(child: Text("This view is empty"))]);
        break;
      case PageStatus.success:
        body = ListView.builder(
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.symmetric(vertical: 0.0),
          itemCount: _tasksByPriority.keys.length,
          itemBuilder: (context, index) {
            String priority = _tasksByPriority.keys.elementAt(index);
            return Column(
              children: [
                Divider(), // This will create a divider between each group
                Text(
                    'Priority: ${priorityToString(int.parse(priority))}'), // This will display the priority
                ..._tasksByPriority[priority]!
                    .map((task) => _buildTile(task, context))
                    .toList(), // This will display the tasks for this priority
              ],
            );
          },
        );
        break;
    }
    return new Scaffold(
      body: RefreshIndicator(onRefresh: () => _loadList(context), child: body),
      floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                onPressed: () {
                  _addItemDialog(context);
                },
                child: const Icon(Icons.add),
              )),
      appBar: AppBar(
        title: Text("Vikunja"),
        actions: [
          PopupMenuButton(itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        bool newval = !onlyDueDate;
                        VikunjaGlobal.of(context)
                            .settingsManager
                            .setLandingPageOnlyDueDateTasks(newval)
                            .then((value) {
                          setState(() {
                            onlyDueDate = newval;
                            _loadList(context);
                          });
                        });
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Only show tasks with due date"),
                            Checkbox(
                              value: onlyDueDate,
                              onChanged: (bool? value) {},
                            )
                          ]))),
              PopupMenuItem(
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        bool newval = !showUpcoming;
                        VikunjaGlobal.of(context)
                            .settingsManager
                            .setShowUpcomingTasks(newval)
                            .then((value) {
                          setState(() {
                            showUpcoming = newval;
                            _loadList(context);
                          });
                        });
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Show future tasks"),
                            Checkbox(
                              value: showUpcoming,
                              onChanged: (bool? value) {},
                            )
                          ]))),
              PopupMenuItem(
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        bool newval = !showDone;
                        VikunjaGlobal.of(context)
                            .settingsManager
                            .setShowDoneTasks(newval)
                            .then((value) {
                          setState(() {
                            showDone = newval;
                            _loadList(context);
                          });
                        });
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Show done tasks"),
                            Checkbox(
                              value: showDone,
                              onChanged: (bool? value) {},
                            )
                          ])))
            ];
          }),
        ],
      ),
    );
  }

  _addItemDialog(BuildContext context) {
    if (defaultList == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a default list in the settings'),
      ));
    } else {
      showDialog(
          context: context,
          builder: (_) => AddDialog(
              onAddTask: (title, dueDate) => _addTask(title, dueDate, context),
              decoration: new InputDecoration(
                  labelText: 'Task Name', hintText: 'eg. Milk')));
    }
  }

  Future<void> _addTask(
      String title, DateTime? dueDate, BuildContext context) async {
    final globalState = VikunjaGlobal.of(context);
    if (globalState.currentUser == null) {
      return;
    }

    await globalState.taskService.add(
      defaultList!,
      Task(
          title: title,
          startDate: dueDate,
          createdBy: globalState.currentUser!,
          projectId: defaultList!,
          priority: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('The task was added successfully!'),
    ));
    _loadList(context).then((value) => setState(() {}));
  }

  TaskTile _buildTile(Task task, BuildContext context) {
    // key: UniqueKey() seems like a weird workaround to fix the loading issue
    // is there a better way?
    return TaskTile(
      key: UniqueKey(),
      task: task,
      project: task.projectId != defaultList ? projects[task.projectId] : null,
      onEdit: () => _loadList(context),
      onMarkedAsFavorite: (newValue) => _loadList(context),
      showInfo: true,
      showPriority: false,
    );
  }

  Future<void> _loadList(BuildContext context) async {
    _tasks = [];
    landingPageStatus = PageStatus.loading;

    // FIXME: loads and reschedules tasks each time list is updated
    VikunjaGlobalState global = VikunjaGlobal.of(context);
    global.notifications.scheduleDueNotifications(global.taskService);
    bool showOnlyDueDateTasks =
        await global.settingsManager.getLandingPageOnlyDueDateTasks();
    bool showUpcoming = await global.settingsManager.getShowUpcomingTasks();
    bool showDone = await global.settingsManager.getShowDoneTasks();
    Map<String, dynamic>? frontend_settings =
        global.currentUser?.settings?.frontend_settings;
    int? filterId = 0;

    //load projects
    if (projects.isEmpty) {
      var response = await global.projectService.getAll();
      if (response != null) {
        projects = Map.fromIterable(response,
            key: (e) => e.id, value: (e) => e as Project);
      }
    }

    if (frontend_settings != null) {
      if (frontend_settings["filter_id_used_on_overview"] != null)
        filterId = frontend_settings["filter_id_used_on_overview"];
    }
    Map<String, dynamic> params = {
      "sort_by": ["due_date", "start_date", "id"],
      "order_by": ["desc", "asc", "desc"],
      "filter": "done = $showDone",
      "filter_include_nulls": "false",
      "per_page": "500"
    };

    if (!showUpcoming) {
      params["filter"] =
          "start_date>='now-1y'||start_date<='now'&&done=$showDone";
      params["filter_include_nulls"] = "true";
    }
    if (filterId != null && filterId != 0) {
      var response = await global.taskService.getAllByProject(filterId, params);
      return _handleTaskList(response?.body, showOnlyDueDateTasks);
    } else {
      var response = await global.taskService.getAll(params);
      return _handleTaskList(response, showOnlyDueDateTasks);
    }
  }

  void _handleTaskList(List<Task>? taskList, bool showOnlyDueDateTasks) {
    if (showOnlyDueDateTasks)
      taskList?.removeWhere((element) =>
          element.dueDate == null || element.dueDate!.year == 0001);

    if (taskList != null && taskList.isEmpty) {
      setState(() {
        landingPageStatus = PageStatus.empty;
      });
      return;
    }
    //taskList.forEach((task) {task.list = lists.firstWhere((element) => element.id == task.list_id);});

    setState(() {
      if (taskList != null) {
        _tasks = taskList;
        _tasksByPriority =
            groupBy(_tasks, (Task task) => task.priority.toString());
        final sortedKeys = _tasksByPriority.keys.toList(growable: false)
          ..sort((k1, k2) => k2.compareTo(k1));
        _tasksByPriority = Map.fromIterable(sortedKeys,
            key: (k) => k, value: (k) => _tasksByPriority[k]!);
        // sort tasks within each priority group by is_favorite
        _tasksByPriority.forEach((key, value) {
          value.sort((a, b) => a.is_favorite == b.is_favorite
              ? 0
              : a.is_favorite
                  ? -1
                  : 1);
        });

        landingPageStatus = PageStatus.success;
      } else {
        landingPageStatus = PageStatus.error;
      }
    });
    setState(() {});
  }
}
