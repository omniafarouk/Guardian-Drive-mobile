// services/breach_trigger_coordinator.dart
import 'package:guardian_drive_mobile/models/alert_tier.dart';
import 'package:guardian_drive_mobile/models/condition_breach_data.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_pattern_matcher.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/driver_baseline_with_noise_model.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

/// Three-stage pipeline, called once per incoming reading:
///
/// STAGE 1 — Consecutive confirmation: a condition only counts as "real"
///           once it appears in [requiredConsecutiveCount] readings in a
///           row. A single noisy reading is ignored; if the streak breaks
///           (condition absent from a reading), the count resets to zero.
///
/// STAGE 2 — Tier classification: once confirmed, decide warning (notify
///           only) vs alertTrigger (take real action). Rule not yet defined —
///           see _classifyTier() below.
///
/// STAGE 3 — Permanent retirement: once a condition has triggered (either
///           tier), it is NEVER evaluated again for the rest of this
///           coordinator's lifetime (i.e. the rest of the trip). No
///           cooldown, no re-firing if it recurs later.

/// What the coordinator decided to do (if anything) this cycle.
class TriggerEvaluation {
  final AlertTier? tier; // null = nothing happened this cycle
  final String? conditionName;
  final List<ConditionBreach>? breaches;

  TriggerEvaluation({this.tier, this.conditionName, this.breaches});

  factory TriggerEvaluation.none() =>
      TriggerEvaluation(tier: null, breaches: []);

  bool get hasAction => tier != null;
}

class BreachTriggerCoordinator {
  // final _tempOscillationTolerance = 0.2;
  final int requiredConsecutiveCount;
  final Duration cooldown;

  final Map<ConditionType, int> _consecutiveCounts = {};
  final Set<ConditionType> _confirmedActive = {};
  // final Set<ConditionType> _alreadyTriggered = {};

  // For panic oscillation detection: we keep the last 3 raw temp values
  // seen during the streak so we can check if direction flips.
  // final List<double> _recentTempReadings = [];

  /// null = no action has ever fired yet, so no cooldown exists.
  /// Only ever set inside Stage 3, the moment an alert actually triggers.
  DateTime? cooldownUntil;

  final DriverBaselineWithNoise _baselineWithNoise;

  BreachTriggerCoordinator({
    required DriverBaselineWithNoise baseline, // ← new
    this.requiredConsecutiveCount = 3,
    bool testMode = false,
  }) : cooldown = testMode
           ? Duration(seconds: 30)
           : Duration(minutes: 3), // timed out cooldown
       _baselineWithNoise = baseline;

  /// [now] is passed in (not read internally) — same testability reason
  /// as before: deterministic tests, no real waiting.
  TriggerEvaluation evaluate(
    List<ConditionBreach> currentBreaches,
    DateTime now,
    VitalReadings latestReading,
  ) {
    // ---- GLOBAL COOLDOWN GATE ----
    if (cooldownUntil != null && now.isBefore(cooldownUntil!)) {
      traceLog('Suppressed — cooldown active until', cooldownUntil.toString());
      return TriggerEvaluation.none();
    }

    final currentKeys = currentBreaches.map((b) => b.type).toSet();

    // ---- STAGE 1: consecutive confirmation ----
    for (final breach in currentBreaches) {
      final key = breach.type;
      final count = (_consecutiveCounts[key] ?? 0) + 1;
      _consecutiveCounts[key] = count;
      traceLog('Consecutive count for ${breach.type.name}', count);

      if (count >= requiredConsecutiveCount) {
        _confirmedActive.add(key);
      }
    }

    _consecutiveCounts.removeWhere((key, _) => !currentKeys.contains(key));
    _confirmedActive.removeWhere((key) => !currentKeys.contains(key));

    if (_confirmedActive.isEmpty) return TriggerEvaluation.none();

    final confirmedBreaches = currentBreaches
        .where((b) => _confirmedActive.contains(b.type))
        .toList();

    traceLog(
      'List of Confirmed breaches',
      confirmedBreaches.map((b) => b.toString()).join(', '),
    );

    // ---- STAGE 2: classify warning vs alertTrigger ----
    // First try pattern matcher — identifies a known condition (fatigue, panic etc.)
    // If no pattern matched, fall back to severity-based classification.
    final pattern = classifyPattern(latestReading);

    AlertTier? tier = pattern?.tier;
    String? conditionName = pattern?.conditionName;

    if (tier == null) {
      // No known pattern matched — classify by worst severity in confirmed breaches
      // and combine the breach type names into a readable condition name.
      final hasAlert = confirmedBreaches.any(
        (b) => b.severity == ConditionSeverity.CRITICAL,
      );
      final hasWarning = confirmedBreaches.any(
        (b) => b.severity == ConditionSeverity.MODERATE,
      );

      if (hasAlert) {
        tier = AlertTier.alertTrigger;
      } else if (hasWarning) {
        tier = AlertTier.warning;
      } else {
        // confirmed but neither warning nor alert severity — suppress
        return TriggerEvaluation.none();
      }

      // combine breach type names into one string e.g. "LOW_HEART_RATE + LOW_SPO2"
      conditionName = confirmedBreaches.map((b) => b.type.name).join(' + ');
      traceLog('No pattern matched — fallback condition', conditionName);
    }

    traceLog('Tier classified', '$conditionName (${tier.name})');

    // ---- STAGE 3: act, retire, start cooldown ----
    final triggeredBreaches = List<ConditionBreach>.from(confirmedBreaches);
    _confirmedActive.clear();
    cooldownUntil = now.add(cooldown);
    traceLog('Cooldown until', cooldownUntil.toString());

    return TriggerEvaluation(
      tier: tier,
      conditionName: conditionName,
      breaches: triggeredBreaches,
    );
  }

  void reset() {
    _consecutiveCounts.clear();
    _confirmedActive.clear();
    // _alreadyTriggered.clear();
    cooldownUntil = null;
  }

  PatternMatch? classifyPattern(
    // List<ConditionBreach> confirmedBreaches,
    VitalReadings latestReading, // pass the original reading in
  ) {
    // // Extract what breached for logging/debugging --->
    // //TODO : SHOULD BE DELETED WHEN ENSURED CORRECT
    // double? hrBreach, tempBreach, spo2Breach;
    // double? hrBaseline, tempBaseline, spo2Baseline;

    // for (final breach in confirmedBreaches) {
    //   if (breach.type == ConditionType.HIGH_HEART_RATE ||
    //       breach.type == ConditionType.LOW_HEART_RATE) {
    //     hrBreach = breach.value;
    //     hrBaseline = breach.baselineBreached;
    //   } else if (breach.type == ConditionType.HIGH_TEMP ||
    //       breach.type == ConditionType.LOW_TEMP) {
    //     tempBreach = breach.value;
    //     tempBaseline = breach.baselineBreached;
    //   } else if (breach.type == ConditionType.LOW_SPO2) {
    //     spo2Breach = breach.value;
    //     spo2Baseline = breach.baselineBreached;
    //   }
    // }

    // VitalReadings? confirmedBreachesReading = VitalReadings(
    //   heartRate: hrBreach ?? 0,
    //   spo2: spo2Breach ?? 0,
    //   temp: tempBreach ?? 0,
    //   timestamp: DateTime.now(),
    // );

    // Build the comparison baseline:
    // - use the specific threshold that was crossed if that vital breached
    // - fall back to the driver's stored average from MedicalInformation otherwise
    final activeBaseline =
        _baselineWithNoise; // NOTE : Taking Avg Values Instead of Breached Limit Value (IS THIS CORRECT THO?)

    final patternMatcher = ConditionPatternMatcher(baseline: activeBaseline);

    final matches = patternMatcher.matchAll(
      latestReading,
    ); // needs the raw reading, not just breaches

    if (matches.isEmpty) {
      return null;
    }

    final PatternMatch patternDetected = matches.first; // strongest match wins

    traceLog(
      'Pattern matched',
      '${patternDetected.conditionName} (${patternDetected.tier.name})',
    );

    return patternDetected;
  }
}

  // bool _isTempOscillating() {
  //   // used to detect oscillating temps for panic attacks only
  //   if (_recentTempReadings.length < 3) return false;
  //   final n = _recentTempReadings.length;
  //   final a = _recentTempReadings[n - 3];
  //   final b = _recentTempReadings[n - 2];
  //   final c = _recentTempReadings[n - 1];

  //   final delta1 = b - a;
  //   final delta2 = c - b;

  //   return delta1.abs() >= _tempOscillationTolerance &&
  //       delta2.abs() >= _tempOscillationTolerance &&
  //       delta1.sign != delta2.sign; // direction flipped = oscillating
  // }


/*
onAlertTriggered(){
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),}
*/
