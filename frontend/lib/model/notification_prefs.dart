class NotificationPrefs {
  const NotificationPrefs({
    this.messages = true,
    this.approvals = true,
    this.reviews = false,
  });

  final bool messages;
  final bool approvals;
  final bool reviews;

  NotificationPrefs copyWith({
    bool? messages,
    bool? approvals,
    bool? reviews,
  }) => NotificationPrefs(
    messages: messages ?? this.messages,
    approvals: approvals ?? this.approvals,
    reviews: reviews ?? this.reviews,
  );

  Map<String, dynamic> toJson() => {
    'messages': messages,
    'approvals': approvals,
    'reviews': reviews,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        messages: json['messages'] != false,
        approvals: json['approvals'] != false,
        reviews: json['reviews'] == true,
      );
}
