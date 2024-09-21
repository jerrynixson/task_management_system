import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager/models/task_model.dart'; // Import the Task model

class TaskListScreen extends StatefulWidget {
  final String token;

  TaskListScreen({required this.token});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/tasks/'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> taskJson = json.decode(response.body);
      setState(() {
        _tasks = taskJson.map((json) => Task.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrUpdateTask({Task? task}) async {
    final url = task == null
        ? 'http://localhost:8000/api/tasks/'  // URL for creating a task
        : 'http://localhost:8000/api/tasks/${task.id}/';  // URL for updating a task

    final method = task == null ? 'POST' : 'PUT';  // Choose method based on task presence
    final payload = json.encode({
      'title': task?.title ?? 'New Task from Script',
      'description': task?.description ?? 'This task was created using a Python script.',
      'status': task?.status ?? 'pending',
      'deadline': task?.deadline ?? '2024-09-30T23:59:59Z',
      'assigned_user': task?.assignedUser ?? 2,
    });

    final response = await http.Request(method, Uri.parse(url))
      ..headers['Authorization'] = 'Bearer ${widget.token}'
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    final streamedResponse = await response.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == (task == null ? 201 : 200)) {
      _fetchTasks();
    } else {
      // Handle error
      print("Failed to add/update task: ${streamedResponse.statusCode}, $responseBody");
    }
  }

  Future<void> _deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8000/api/tasks/$taskId/'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 204) {
      _fetchTasks();
    } else {
      // Handle error
    }
  }

  void _showTaskDialog({Task? task}) {
    final _formKey = GlobalKey<FormState>();
    String title = task?.title ?? '';
    String description = task?.description ?? '';
    String status = task?.status ?? 'pending';
    String deadline = task?.deadline ?? '';
    int assignedUser = task?.assignedUser ?? 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task == null ? "Add New Task" : "Edit Task"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    initialValue: title,
                    decoration: InputDecoration(labelText: "Title"),
                    onChanged: (value) {
                      title = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: InputDecoration(labelText: "Description"),
                    onChanged: (value) {
                      description = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(labelText: "Status"),
                    items: <String>['pending', 'completed', 'in-progress']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      status = value ?? 'pending';
                    },
                  ),
                  TextFormField(
                    initialValue: deadline,
                    decoration: InputDecoration(labelText: "Deadline"),
                    onChanged: (value) {
                      deadline = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a deadline';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: assignedUser.toString(),
                    decoration: InputDecoration(labelText: "Assigned User ID"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      assignedUser = int.tryParse(value) ?? 1;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a user ID';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(task == null ? "Add Task" : "Update Task"),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Task newTask = Task(
                    id: task?.id ?? 0,  // Use task ID if updating
                    title: title,
                    description: description,
                    status: status,
                    deadline: deadline,
                    assignedUser: assignedUser,
                  );
                  _addOrUpdateTask(task: newTask);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task List"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showTaskDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showTaskDialog(task: task),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
