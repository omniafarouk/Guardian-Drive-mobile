import 'package:flutter/material.dart';

enum TripStatus { planned, ongoing, cancelled, completed }

final List<String> locations = ["Alexandria", "Cairo", "Giza"];

Future<Map<String, dynamic>?> showFilterBottomSheet(BuildContext context) {
  DateTimeRange? selectedRange;
  String? fromLocation;
  String? toLocation;
  String sortOrder = "desc";
  List<TripStatus> selectedStatuses = [];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Trips",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: "Date Range",
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        selectedRange == null
                            ? "Select range"
                            : "${selectedRange!.start.day}/${selectedRange!.start.month} → ${selectedRange!.end.day}/${selectedRange!.end.month}",
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2027),
                        );

                        if (picked != null) {
                          setState(() => selectedRange = picked);
                        }
                      },
                    ),
                  ),

                  _SectionCard(
                    title: "From Location",
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: fromLocation,
                      hint: const Text("Select From"),
                      items: locations
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => fromLocation = value);
                      },
                    ),
                  ),

                  _SectionCard(
                    title: "To Location",
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: toLocation,
                      hint: const Text("Select To"),
                      items: locations
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => toLocation = value);
                      },
                    ),
                  ),

                  _SectionCard(
                    title: "Trip Status",
                    child: Wrap(
                      spacing: 8,
                      children: TripStatus.values.map((status) {
                        final isSelected = selectedStatuses.contains(status);
                        return FilterChip(
                          label: Text(status.name),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                selectedStatuses.add(status);
                              } else {
                                selectedStatuses.remove(status);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  _SectionCard(
                    title: "Sort by Date",
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text("Newest"),
                          selected: sortOrder == "desc",
                          onSelected: (_) => setState(() => sortOrder = "desc"),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text("Oldest"),
                          selected: sortOrder == "asc",
                          onSelected: (_) => setState(() => sortOrder = "asc"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          "range": selectedRange,
                          "fromLocation": fromLocation,
                          "toLocation": toLocation,
                          "statuses": selectedStatuses,
                          "sort": sortOrder,
                        });
                      },
                      child: const Text("Apply Filters"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedRange = null;
                          fromLocation = null;
                          toLocation = null;
                          selectedStatuses.clear();
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
