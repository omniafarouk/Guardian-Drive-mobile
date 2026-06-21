class FirstAidGuidance {
  /*
         severity: ConditionSeverity;
        severityAction: string;
        conditions: {
            condition: ConditionType;
            description: string;
            specificAction: string | null;
        }[];
  */
  final ConditionSeverity severity;
  final String severityAction;
  final List<Condition> conditions;

  FirstAidGuidance({
    required this.severity,
    required this.severityAction,
    required this.conditions,
  });

  factory FirstAidGuidance.fromJson(Map<String, dynamic> json) {
    return FirstAidGuidance(
      severity: ConditionSeverity.values.byName(json['severity']),
      severityAction: json['severityAction'],
      conditions: (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList(),
    );
  }
}

class Condition {
  final ConditionType conditionType;
  final String description;
  final String? specificAction;

  Condition({
    required this.conditionType,
    required this.description,
    this.specificAction,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      conditionType: ConditionType.values.byName(json['condition']),
      description: json['description'],
      specificAction: json['specificAction'],
    );
  }
}

enum ConditionSeverity { MILD, MODERATE, CRITICAL, NORMAL }

enum ConditionType {
  LOW_HEART_RATE,
  HIGH_HEART_RATE,
  LOW_TEMP,
  HIGH_TEMP,
  LOW_SPO2,
}
