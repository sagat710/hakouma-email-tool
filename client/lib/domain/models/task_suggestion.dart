enum SuggestionTarget { googleTasks, googleCalendar }

class TaskSuggestion {
  final String id;
  final String emailMessageId;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final SuggestionTarget target;
  final bool accepted;
  final bool dismissed;

  const TaskSuggestion({
    required this.id,
    required this.emailMessageId,
    required this.title,
    this.notes,
    this.dueDate,
    this.target = SuggestionTarget.googleTasks,
    this.accepted = false,
    this.dismissed = false,
  });

  TaskSuggestion copyWith({bool? accepted, bool? dismissed}) => TaskSuggestion(
        id: id,
        emailMessageId: emailMessageId,
        title: title,
        notes: notes,
        dueDate: dueDate,
        target: target,
        accepted: accepted ?? this.accepted,
        dismissed: dismissed ?? this.dismissed,
      );
}
