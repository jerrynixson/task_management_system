class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String deadline;
  final int assignedUser;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.deadline,
    required this.assignedUser,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      deadline: json['deadline'],
      assignedUser: json['assigned_user'],
    );
  }
}
