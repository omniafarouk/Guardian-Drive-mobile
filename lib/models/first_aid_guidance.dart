import 'dart:ui';

import 'package:flutter/material.dart';

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
  final int guidanceId;

  Condition({
    required this.conditionType,
    required this.description,
    required this.guidanceId,
    this.specificAction,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      conditionType: ConditionType.values.byName(json['condition']),
      description: json['description'],
      specificAction: json['specificAction'],
      guidanceId: json['guidanceId'],
    );
  }
}

enum ConditionSeverity {
  MILD,
  MODERATE,
  CRITICAL,
  NORMAL;

  String get displayName {
    switch (this) {
      case ConditionSeverity.MILD:
        return 'Mild';
      case ConditionSeverity.MODERATE:
        return 'Moderate';
      case ConditionSeverity.CRITICAL:
        return 'Critical';
      case ConditionSeverity.NORMAL:
        return 'Normal';
    }
  }

  Color get color {
    switch (this) {
      case ConditionSeverity.MILD:
        return Colors.orange;
      case ConditionSeverity.MODERATE:
        return Colors.deepOrange;
      case ConditionSeverity.CRITICAL:
        return Colors.red;
      case ConditionSeverity.NORMAL:
        return Colors.green;
    }
  }
}

enum ConditionType {
  LOW_HEART_RATE,
  HIGH_HEART_RATE,
  LOW_TEMP,
  HIGH_TEMP,
  LOW_SPO2,
}


/*


{
  "message": "Success",
  "data": {
    "guidance": [
      {
        "severity": "MILD",
        "severityAction": "Pull over and rest. Monitor vitals and escalate if symptoms worsen.",
        "conditions": [
          {
            "guidanceId": 1,
            "condition": "HIGH_HEART_RATE",
            "description": "Elevated heart rate (100-120 bpm)",
            "specificAction": null
          },
          {
            "guidanceId": 7,
            "condition": "LOW_SPO2",
            "description": "Slightly low oxygen (92-95%)",
            "specificAction": null
          },
          {
            "guidanceId": 10,
            "condition": "HIGH_TEMP",
            "description": "Mild fever (37.5-38°C)",
            "specificAction": null
          }
        ]
      }
    ]
  }
}
 */