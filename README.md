# guardian_drive_mobile

A new Flutter project.

# Normal Person Readings :

thresholds = DriverHealthThresholds(
    avgHeartRate: 80,
    minHeartRate: 75,
    maxHeartRate: 110,
    avgSpo2: 98,
    minSpo2: 96,
    maxSpo2: 99,
    avgTemp: 37,
    minTemp: 36.2,
    maxTemp: 38.5,
);

# FLOW of Condition_Coordinator 
BandBleService
    ↓ VitalReadings
ThresholdChecker
    ↓ List<ConditionBreach>  (WARNING or ALERT severity per vital)
BreachTriggerCoordinator.evaluate()
    ↓ confirms 3-in-a-row streak
    ↓ calls _classifyPattern(confirmedBreaches, latestReading)
            ↓
        ConditionPatternMatcher.matchAll(latestReading)
            ↓ checks raw reading against HealthPatterns
            ↓ returns PatternMatch with conditionName + tier
    ↓ if no pattern → fallback to severity-based tier + combined name
    ↓ TriggerEvaluation(tier, conditionName, breaches)
HealthMonitorService.onAlertTriggered(conditionName)
    ↓
showHealthAlertDialog(conditionName)  +  POST to backend

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



--------------------- added by Omnia ---------------------

avgReadings flow

save each 10 seconds (basically 3la 7asb elband frequency)
↓
save each 5 min ( 1min/10sec = 6 => therefore, 6 * 5 = 30 values averaging of the seconds)
↓
save each 30 mins ( 30/5 = 6 values averaging of the 5mins values) 
↓
save based on hours (average 5hr trip would = 2*5= 10 values averaging of the 30mins values )

Flow description :

In the context of Guardian Drive, health readings are continuously collected from the wearable band and aggregated through a three-level pipeline. Raw readings are averaged every five minutes, five-minute averages are averaged every thirty minutes, and all thirty-minute averages are combined at trip end into a single trip-level average that is then submitted to the backend. Hive serves as the persistence layer for both the five-minute and thirty-minute averages, meaning that if the application is backgrounded, crashed, or killed by the OS at any point during the trip, all previously computed averages are already persisted and the pipeline can finalize correctly without data loss when the trip concludes.

In the implementation, two separate Hive boxes are maintained during an active trip: one for five-minute averages and one for thirty-minute averages. Each box is written to on every timer tick and read from when the next aggregation level computes its window average. Both boxes are cleared atomically after the final trip average is successfully submitted to the backend, ensuring no stale health data persists on the device between trips.



-----------------
Here's the pipeline section:        (avg readings flow)

---

The health data aggregation pipeline was designed around two competing constraints: the need for sufficient data granularity to detect meaningful health trends during a trip, and the need to minimize battery consumption, storage writes, and processing overhead on the driver's device throughout an entire driving shift.

Raw readings are collected from the wearable band every ten seconds. A five-second interval was considered but ruled out as heart rate and SpO2 do not change meaningfully within a five-second window, meaning the additional readings would double the processing frequency while contributing no measurable improvement to the computed averages. Ten seconds provides sufficient sampling density for accurate short-window averaging while remaining practical for continuous Bluetooth polling over a multi-hour shift.

The first aggregation level computes a five-minute average from the raw readings accumulated in that window, producing approximately thirty data points per average. A one-minute interval was considered but produces noisy averages that are heavily influenced by momentary movement artifacts, which is a known limitation of wearable sensors during physical activity such as driving. Five-minute windows are the established standard in clinical and consumer wearable health monitoring precisely because they smooth out these artifacts while remaining granular enough to reflect genuine physiological trends. The resulting average is persisted to Hive at this point, establishing the first crash-safe checkpoint in the pipeline.

The second aggregation level computes a thirty-minute average from the six five-minute averages accumulated in that window. A one-hour interval was considered but was ruled out for shorter trips, where a single data point per hour would leave trips under two hours with only one or two averages, making the final trip average statistically weak. Thirty minutes provides at least two data points on the shortest practical trips while producing a smooth and representative average on longer shifts, and the resulting value is persisted to Hive as the most critical checkpoint in the pipeline since it directly feeds the final computation.

At trip end, all persisted thirty-minute averages are read from Hive and combined into a single trip-level average that is submitted to the backend as the canonical health record for that trip. This final value represents the driver's average physiological state across the entire shift and is what fleet managers and the system use for health trend analysis and alert baseline comparison. Both Hive boxes are cleared only after the backend confirms a successful submission, ensuring no data is discarded before it has been safely received.


