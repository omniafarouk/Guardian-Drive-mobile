import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert_summary.dart';

final List<String> locations = ["Alexandria", "Cairo", "Giza"];

Future<Map<String, dynamic>?> showFilterBottomSheet(
  BuildContext context, {
  DateTimeRange? initialRange,
  alertType? initialType,
  String initialSortOrder = "desc",

}) {
  DateTimeRange? selectedRange = initialRange;
  alertType? selectedType = initialType;
  String sortOrder = initialSortOrder;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter & Sort",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // ================= DATE RANGE =================
                  const Text(
                    "Date Range",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2027),
                        initialDateRange: selectedRange,
                      );

                      if (picked != null) {
                        setState(() => selectedRange = picked);
                      }
                    },
                    child: Text(
                      selectedRange == null
                          ? "Select Date Range"
                          : "${selectedRange!.start.day}/${selectedRange!.start.month}/${selectedRange!.start.year}"
                                "  →  "
                                "${selectedRange!.end.day}/${selectedRange!.end.month}/${selectedRange!.end.year}",
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= TYPE =================
                  const Text(
                    "Alert Type",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  DropdownButton<alertType>(
                    isExpanded: true,
                    value: selectedType,
                    hint: const Text("Select Type"),
                    items: alertType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ================= SORT =================
                  const Text(
                    "Sort by Date",
                    style: TextStyle(color: Colors.grey),
                  ),

                  RadioListTile<String>(
                    title: const Text("Newest first"),
                    value: "desc",
                    groupValue:
                        sortOrder, // tells flutter which radio button is currently selected (checked) -> Flutter asks: "Which one should I highlight" --> tje answer comes from -> groupVlaue: sortOrder
                    onChanged: (value) {
                      setState(() => sortOrder = value!);
                    },
                  ),

                  RadioListTile<String>(
                    title: const Text("Oldest first"),
                    value: "asc",
                    groupValue: sortOrder,
                    onChanged: (value) {
                      setState(() => sortOrder = value!);
                    },
                  ),

                  const SizedBox(height: 20),

                  // ================= APPLY =================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // pop() -> remove the current screen (or madal) from the screen stack (It closes the bottom sheet)
                        Navigator.pop(context, {
                          // returns data back to the previous screen (The value being sent back)
                          "range": selectedRange,
                          "type": selectedType,
                          "sort": sortOrder,
                        });
                      },
                      child: const Text("Apply Filters"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= RESET =================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          "range": null,
                          "type": null,
                          "sort": "desc",
                        });
                      },
                      child: const Text("Reset"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
