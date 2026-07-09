import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';

// FlutterWidgetsLabScreen showcases basic layouts and interactive components
// required for Phase 1 (GridView, Dropdown, Radio, Checkbox, Slider, Pickers).
// This is a StatefulWidget because we need to hold and modify state values
// (e.g. selected radio index, checkbox toggles, date/time values) and rebuild the UI.
class FlutterWidgetsLabScreen extends StatefulWidget {
  const FlutterWidgetsLabScreen({super.key});

  @override
  State<FlutterWidgetsLabScreen> createState() =>
      _FlutterWidgetsLabScreenState();
}

class _FlutterWidgetsLabScreenState extends State<FlutterWidgetsLabScreen> {
  // 1. State for Dropdown Button
  final List<String> _abbottabadSectors = [
    'Cantonment',
    'Jinnahabad',
    'Mandian',
    'Nawanshehr',
    'Kehal',
    'Kakul',
  ];
  late String _selectedSector;

  // 2. State for Radio Buttons
  int _selectedSeverity = 1; // 1: Low, 2: Medium, 3: High

  // 3. State for Checkboxes
  bool _agreeToTOS = false;
  bool _subscribeToAlerts = true;

  // 4. State for Slider
  double _radiusFilter = 5.0; // Range: 0.0 to 20.0 km

  // 5. State for Date and Time Pickers
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // Initialize default dropdown value to the first element in the list.
    _selectedSector = _abbottabadSectors[0];
  }

  // Future method triggers the asynchronous platform date picker dialog.
  // Reference: https://api.flutter.dev/flutter/material/showDatePicker.html
  Future<void> _pickDate() async {
    // await blocks execution until the user selects a date or cancels the dialog.
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025), // Earliest selectable year
      lastDate: DateTime(2030), // Latest selectable year
    );
    // If the user selected a valid new date, update state to trigger a UI repaint.
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Future method triggers the asynchronous time picker dialog.
  // Reference: https://api.flutter.dev/flutter/material/showTimePicker.html
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final isSlim = size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgets Showcase'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(BedrockConstants.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Abbottabad Sectors (GridView)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: BedrockConstants.space12),

            // GridView.builder renders scrollable grids of widgets efficiently.
            GridView.builder(
              shrinkWrap:
                  true, // Let the GridView take only the height of its children (prevents infinite height errors inside scroll views).
              physics:
                  const NeverScrollableScrollPhysics(), // Delegate scroll behavior to the outer SingleChildScrollView.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Responsively scale grid column count: 3 on wide screens, 1 on slim viewports, and 2 on standard viewports.
                crossAxisCount: isWide ? 3 : (isSlim ? 1 : 2),
                crossAxisSpacing:
                    BedrockConstants.space12, // Gap between columns.
                mainAxisSpacing: BedrockConstants.space12, // Gap between rows.
                // Child aspect ratio is width divided by height.
                childAspectRatio: isSlim ? 2.5 : 1.35,
              ),
              itemCount: _abbottabadSectors.length,
              itemBuilder: (context, index) {
                final sector = _abbottabadSectors[index];
                return Container(
                  padding: const EdgeInsets.all(BedrockConstants.space12),
                  decoration: BoxDecoration(
                    color: BedrockTheme.cardDark,
                    borderRadius: BorderRadius.circular(
                      BedrockConstants.radiusSmall,
                    ),
                    border: Border.all(color: BedrockTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          Text(
                            'UC-${index + 1}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                      Text(
                        sector,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hazards: ${(index * 2) % 4}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: BedrockConstants.space32),
            Text(
              'Interactive Widget Lab Controls',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: BedrockConstants.space16),

            // Dropdown Button widget allows choosing a single item from a list.
            _buildControlGroup(
              title: 'Select Target Sector (Dropdown):',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: BedrockTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(
                    BedrockConstants.radiusSmall,
                  ),
                  border: Border.all(color: BedrockTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: BedrockTheme.surfaceDark,
                    value: _selectedSector, // Bind selected state variable.
                    isExpanded:
                        true, // Force dropdown to fill the container width.
                    items: _abbottabadSectors.map((sector) {
                      return DropdownMenuItem<String>(
                        value: sector,
                        child: Text(sector),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSector = val; // Set new state and redraw.
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: BedrockConstants.space16),

            // Radio Buttons allow choosing exactly one option from a mutually exclusive set.
            _buildControlGroup(
              title: 'Alert Severity Level (Radio):',
              child: Row(
                children: [
                  _buildRadioItem(1, 'Low'),
                  _buildRadioItem(2, 'Medium'),
                  _buildRadioItem(3, 'High'),
                ],
              ),
            ),

            const SizedBox(height: BedrockConstants.space16),

            // Slider widget allows selecting values from a continuous range.
            _buildControlGroup(
              title: 'Radius Filter (Slider):',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Radius Limit',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${_radiusFilter.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radiusFilter, // Bind state value.
                    min: 0.0,
                    max: 20.0,
                    divisions: 20, // Snaps to discrete increments (1km each).
                    label:
                        '${_radiusFilter.toStringAsFixed(1)} km', // Text shown in bubble on drag.
                    onChanged: (val) {
                      setState(() {
                        _radiusFilter = val; // Set state and redraw.
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: BedrockConstants.space16),

            // CheckboxListTile widgets allow toggling multiple independent binary choices.
            _buildControlGroup(
              title: 'Alert Subscriptions (Checkboxes):',
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Subscribe to push notifications'),
                    value: _subscribeToAlerts, // Bind boolean state.
                    onChanged: (val) {
                      if (val != null) setState(() => _subscribeToAlerts = val);
                    },
                    controlAffinity: ListTileControlAffinity
                        .leading, // Put checkbox on the left.
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Agree to emergency safety regulations'),
                    value: _agreeToTOS,
                    onChanged: (val) {
                      if (val != null) setState(() => _agreeToTOS = val);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: BedrockConstants.space16),

            // Date and Time pickers triggered by standard styled buttons.
            _buildControlGroup(
              title: 'Event Schedule (Pickers):',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: BedrockTheme.borderSubtle,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _pickDate, // Call async picker.
                    ),
                  ),
                  const SizedBox(width: BedrockConstants.space12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: BedrockTheme.borderSubtle,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BedrockConstants.space32),
          ],
        ),
      ),
    );
  }

  // Helper builder that wraps widget controls in a styled box layout.
  Widget _buildControlGroup({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: BedrockConstants.space12),
          child,
        ],
      ),
    );
  }

  // Helper builder that renders a radio option.
  Widget _buildRadioItem(int value, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSeverity = value;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<int>(
              value: value, // The value this radio option represents.
              groupValue:
                  _selectedSeverity, // The currently active selection index.
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSeverity = val; // Set active and redraw.
                  });
                }
              },
            ),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
