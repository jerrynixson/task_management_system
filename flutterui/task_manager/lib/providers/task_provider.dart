import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  // Replace this with your Django backend API URL
  final String baseUrl = 'http://localhost:8000/api/';
  final String accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzI2OTA1OTc4LCJpYXQiOjE3MjY5MDUwNzgsImp0aSI6IjU3MTViYTA1MjJkNjRmZDZiMTNjYWNkZTQ3YjY3MzVhIiwidXNlcl9pZCI6Mn0.Y2m-tfwGi24PfKdufaFdtizzV9kGjq1LDjxrpC0XVN8';  // Replace with your actual JWT access token
  
  List<Task> get tasks => _tasks;

  Map<String, String> get headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  // 1. Create a New Task
  Future<void> createTask(String title, String description, String deadline, int assignedUser) async {
    final url = Uri.parse('${baseUrl}tasks/');
    final payload = json.encode({
      'title': title,
      'description': description,
      'status': 'pending',
      'deadline': deadline,
      'assigned_user': assignedUser,
    });

    final response = await http.post(url, headers: headers, body: payload);

    if (response.statusCode == 201) {
      print("Task created successfully");
      fetchTasks();  // Fetch tasks again to update the list
    } else {
      print("Failed to create task: ${response.statusCode} ${response.body}");
    }
  }

  // 2. Get All Tasks or Filtered Tasks
  Future<void> fetchTasks([String? filterStatus]) async {
    String url = filterStatus != null
        ? '${baseUrl}tasks/?status=$filterStatus'
        : '${baseUrl}tasks/';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      _tasks = data.map((task) => Task.fromJson(task)).toList();
      notifyListeners();
    } else {
      print("Failed to retrieve tasks: ${response.statusCode} ${response.body}");
    }
  }

  // 3. Update a Task (Full or Partial Update)
  Future<void> updateTask(int taskId, {String? newStatus, String? title, String? description, String? deadline, int? assignedUser}) async {
    final url = Uri.parse('${baseUrl}tasks/$taskId/');
    Map<String, dynamic> payload = {};

    if (newStatus != null) {
      // Partial update: status only
      payload['status'] = newStatus;
    } else {
      // Full update
      payload = {
        'title': title,
        'description': description,
        'status': 'pending',
        'deadline': deadline,
        'assigned_user': assignedUser,
      };
    }

    final response = await http.patch(url, headers: headers, body: json.encode(payload));

    if (response.statusCode == 200) {
      print("Task updated successfully");
      fetchTasks();  // Refresh task list after update
    } else {
      print("Failed to update task: ${response.statusCode} ${response.body}");
    }
  }

  // 4. Delete a Task
  Future<void> deleteTask(int taskId) async {
    final url = Uri.parse('${baseUrl}tasks/$taskId/');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 204) {
      print("Task deleted successfully");
      fetchTasks();  // Refresh task list after deletion
    } else {
      print("Failed to delete task: ${response.statusCode} ${response.body}");
    }
  }
}
