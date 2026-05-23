import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';

final List<String> locations = ["Alexandria", "Cairo", "Giza"];

Future<Map<String, dynamic>?> showFilterBottomSheet(BuildContext context) {
  DateTimeRange? selectedRange;
  String? selectedCity;
  alertType? selectedType;
  String sortOrder = "desc";

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

                  // ================= CITY =================
                  const Text("City", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),

                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCity,
                    hint: const Text("Select City"),
                    items: locations
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedCity = value);
                    },
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
                    groupValue: sortOrder,
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
                        Navigator.pop(context, {
                          "range": selectedRange,
                          "city": selectedCity,
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
                        setState(() {
                          selectedRange = null;
                          selectedCity = null;
                          selectedType = null;
                          sortOrder = "desc";
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
