import 'package:flutter/material.dart';

// Assuming your enum is defined here or imported
enum TripStatus { planned, ongoing, cancelled, completed }

class FilterMenu extends StatefulWidget {
  const FilterMenu({super.key});

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> {
  // State variables to hold filter values
  DateTime? fromDate;
  DateTime? toDate;
  String? fromLocation;
  String? toLocation;
  List<TripStatus> selectedStatuses = [];

  final List<String> locations = ["Alexandria", "Cairo", "Giza"];

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, right: 10),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setInternalState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Filter Trips",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),

                          // 1. Date Range
                          const _SectionLabel("Start Time Range"),
                          Row(
                            children: [
                              _DateButton(
                                label: fromDate == null ? "From" : "${fromDate!.day}/${fromDate!.month}",
                                onTap: () async {
                                  DateTime? picked = await _pickDate();
                                  if (picked != null) setInternalState(() => fromDate = picked);
                                },
                              ),
                              const SizedBox(width: 8),
                              _DateButton(
                                label: toDate == null ? "To" : "${toDate!.day}/${toDate!.month}",
                                onTap: () async {
                                  DateTime? picked = await _pickDate();
                                  if (picked != null) setInternalState(() => toDate = picked);
                                },
                              ),
                            ],
                          ),

                          // 2. Location Dropdowns
                          const _SectionLabel("Route"),
                          _buildDropdown("From Location", fromLocation, (val) {
                            setInternalState(() => fromLocation = val);
                          }),
                          _buildDropdown("To Location", toLocation, (val) {
                            setInternalState(() => toLocation = val);
                          }),

                          // 3. Status Checkers (Chips)
                          const _SectionLabel("Trip Status"),
                          Wrap(
                            spacing: 8,
                            children: TripStatus.values.map((status) {
                              final isSelected = selectedStatuses.contains(status);
                              return FilterChip(
                                label: Text(status.name, style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setInternalState(() {
                                    selected ? selectedStatuses.add(status) : selectedStatuses.remove(status);
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // 4. Apply Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                // Logic to filter your list goes here
                                Navigator.pop(context);
                              },
                              child: const Text("Apply Filter"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _pickDate() => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2024),
    lastDate: DateTime(2027),
  );

  Widget _buildDropdown(String hint, String? value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(fontSize: 14)),
      value: value,
      items: locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The build method returns the button that triggers the dialog
    return IconButton(
      icon: const Icon(Icons.tune),
      onPressed: _openFilterDialog,
    );
  }
}

// Simple Helper Widgets for clean code
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: OutlinedButton(onPressed: onTap, child: Text(label, style: const TextStyle(fontSize: 12))),
  );
}
