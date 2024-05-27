class Model {
  String label;
  String dateTime;
  bool check;
  String when;
  int id;
  int milliseconds;

  Model({
    required this.label,
    required this.dateTime,
    required this.check,
    required this.when,
    required this.id,
    required this.milliseconds,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      label: json['label'],
      dateTime: json['dateTime'],
      check: json['check'],
      when: json['when'],
      id: json['id'],
      milliseconds: json['milliseconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'dateTime': dateTime,
      'check': check,
      'when': when,
      'id': id,
      'milliseconds': milliseconds,
    };
  }
}
